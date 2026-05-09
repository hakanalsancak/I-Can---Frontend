import SwiftUI
import PhotosUI
import AVFoundation
import AVKit
import UniformTypeIdentifiers

struct ChatView: View {
    let conversation: DMConversation

    @State private var service = DMService.shared
    /// Always kept in chronological (ascending) order. Mutate only via the
    /// helpers below (`appendOutgoing`, `mergeIncoming`, `replacePending`,
    /// `setInitial`, `mergeOlder`) so the invariant + `messagesVersion` are
    /// kept in sync.
    @State private var messages: [DMMessage] = []
    /// Bumped on every mutation. Used by `ChatMessagesView` so its Equatable
    /// short-circuits when nothing changed (e.g. on every keystroke).
    @State private var messagesVersion: UInt64 = 0
    /// Bumped only when we want the list to scroll to the latest message
    /// (new outgoing message, new incoming poll batch, keyboard focus). Pure
    /// pagination must NOT bump this.
    @State private var scrollToBottomToken: UInt64 = 0
    @State private var draft: String = ""
    @State private var nextCursor: String?
    @State private var hasReachedEnd = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var pollTask: Task<Void, Never>?

    /// Refreshed on every `loadMessages` response. Drives the "Online" /
    /// "Last seen…" subtitle so it stays live while the chat is open.
    @State private var otherLastSeenAt: String?
    /// Re-evaluated on a 30s timer so the subtitle text demotes from
    /// "Online" → "Last seen Xm ago" without needing a server poke.
    @State private var presenceTick: Int = 0

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var pickerMode: PickerMode = .photo
    @State private var showCamera = false

    @State private var voiceRecorder = VoiceRecorder()
    @State private var isRecording = false
    @State private var recordingStart: Date?
    @State private var recordingTimer: Timer?
    @State private var recordingElapsed: TimeInterval = 0

    @State private var showProfile = false
    @State private var uploadProgress: Double = 0
    @State private var isUploading = false
    @State private var openImageURL: IdentifiableURL?
    @State private var openVideoURL: IdentifiableURL?
    /// The message the user is composing a reply to, if any. Cleared once
    /// the reply is sent or the user taps the X on the banner.
    @State private var replyTarget: DMMessage?
    @FocusState private var inputFocused: Bool

    @Environment(\.colorScheme) private var colorScheme
    private let currentUserId: String? = AuthService.shared.currentUser?.id

    private enum PickerMode { case photo, video }

    var body: some View {
        ZStack {
            chatBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                messagesList
                if isUploading {
                    uploadBar
                }
                inputBar
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            chatHeader
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    // Restrict back-to-inbox swipe to drags that start from
                    // the screen's left edge. Otherwise it conflicts with the
                    // swipe-to-reply gesture on individual message bubbles.
                    guard value.startLocation.x < 24 else { return }
                    if value.translation.width > 80
                        && abs(value.translation.height) < 60
                        && value.predictedEndTranslation.width > value.translation.width {
                        dismiss()
                    }
                }
        )
        .task { await initialLoad() }
        .onChange(of: inputFocused) { _, focused in
            if focused { scrollToBottomToken &+= 1 }
        }
        .onDisappear {
            pollTask?.cancel()
            stopRecording(submit: false)
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $photoPickerItem,
            matching: pickerMode == .photo ? .images : .videos
        )
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await handlePicked(newItem) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(
                cameraDevice: .rear,
                onImagePicked: { image in
                    showCamera = false
                    Task { await handleCapturedPhoto(image) }
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showProfile) {
            if let other = conversation.other {
                AthleteProfileSheet(athleteId: other.id)
            }
        }
        .fullScreenCover(item: $openImageURL) { wrapper in
            ChatImageViewer(url: wrapper.url) { openImageURL = nil }
        }
        .fullScreenCover(item: $openVideoURL) { wrapper in
            ChatVideoPlayerView(url: wrapper.url) { openVideoURL = nil }
        }
    }

    // MARK: - Background

    private var chatBackground: some View {
        ZStack {
            ColorTheme.background(colorScheme)
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(hex: "0A1628"), Color(hex: "0E1B30")]
                    : [Color(hex: "EEF0F4"), Color(hex: "E8EBF1")],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.9)
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 10) {
            backButton
            Button {
                showProfile = true
            } label: {
                HStack(spacing: 10) {
                    headerAvatar
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                        .overlay(
                            Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                        )
                    VStack(alignment: .leading, spacing: 1) {
                        Text(conversation.displayName)
                            .font(.system(size: 16, weight: .semibold).width(.condensed))
                            .foregroundStyle(ColorTheme.primaryText(colorScheme))
                            .lineLimit(1)
                        headerSubtitleView
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                showProfile = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(ColorTheme.accent)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                ColorTheme.cardBackground(colorScheme).opacity(colorScheme == .dark ? 0.5 : 0.55)
            }
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(height: 0.5)
        }
    }

    @ViewBuilder
    private var headerSubtitleView: some View {
        // `presenceTick` is read so the body refreshes on the 30s timer.
        let _ = presenceTick

        if DMPresence.isOnline(otherLastSeenAt) {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color(red: 0.20, green: 0.80, blue: 0.40))
                    .frame(width: 7, height: 7)
                Text("Online")
                    .foregroundStyle(Color(red: 0.20, green: 0.70, blue: 0.36))
            }
            .font(.system(size: 11.5, weight: .semibold).width(.condensed))
        } else if let lastSeen = DMPresence.lastSeenDescription(otherLastSeenAt) {
            Text(lastSeen)
                .font(.system(size: 11.5).width(.condensed))
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                .lineLimit(1)
        } else {
            Text(staticHeaderFallback)
                .font(.system(size: 11.5).width(.condensed))
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                .lineLimit(1)
        }
    }

    private var staticHeaderFallback: String {
        if let sport = conversation.other?.sport, !sport.isEmpty {
            return sport.capitalized
        }
        if let username = conversation.other?.username, !username.isEmpty {
            return "@\(username)"
        }
        return "Tap to view profile"
    }

    @ViewBuilder
    private var headerAvatar: some View {
        if let urlStr = conversation.other?.photoUrl, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    initialsCircle
                }
            }
        } else {
            initialsCircle
        }
    }

    private var initialsCircle: some View {
        Circle()
            .fill(ColorTheme.accentGradient)
            .overlay(
                Text(initials(conversation.displayName))
                    .font(.system(size: 14, weight: .semibold).width(.condensed))
                    .foregroundStyle(.white)
            )
    }

    @Environment(\.dismiss) private var dismiss
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(ColorTheme.accent)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let f = parts.first?.first.map(String.init) ?? ""
        let s = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (f + s).uppercased()
    }

    private var messagesList: some View {
        ChatMessagesView(
            messages: messages,
            messagesVersion: messagesVersion,
            scrollToken: scrollToBottomToken,
            currentUserId: currentUserId,
            peerDisplayName: conversation.displayName,
            colorScheme: colorScheme,
            onDelete: { msg in Task { await deleteMessage(msg) } },
            onOpenImage: { url in openImageURL = IdentifiableURL(url: url) },
            onOpenVideo: { url in openVideoURL = IdentifiableURL(url: url) },
            onLoadMore: { msg in Task { await loadMoreIfNeeded(currentItem: msg) } },
            onReply: { msg in
                withAnimation(.easeInOut(duration: 0.2)) { replyTarget = msg }
                inputFocused = true
            }
        )
        .equatable()
        .simultaneousGesture(
            TapGesture().onEnded {
                if inputFocused { inputFocused = false }
            }
        )
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            if let target = replyTarget {
                replyBanner(target)
            }
            if let m = errorMessage {
                Text(m)
                    .font(.system(size: 12).width(.condensed))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
            }
            if isRecording {
                recordingBar
            } else {
                normalInputBar
            }
        }
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                ColorTheme.cardBackground(colorScheme).opacity(colorScheme == .dark ? 0.5 : 0.6)
            }
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(height: 0.5)
        }
    }

    private var normalInputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                attachMenu

                TextField("Message", text: $draft, axis: .vertical)
                    .focused($inputFocused)
                    .font(.system(size: 16).width(.condensed))
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .padding(.vertical, 7)
            }
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(ColorTheme.elevatedBackground(colorScheme).opacity(colorScheme == .dark ? 0.7 : 0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(ColorTheme.separator(colorScheme), lineWidth: 0.5)
            )

            sendOrMicButton
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.18), value: canSendText)
    }

    /// Compact strip above the input that shows what message is being
    /// replied to. Tapping the X dismisses the reply.
    @ViewBuilder
    private func replyBanner(_ target: DMMessage) -> some View {
        let mine = target.senderId == currentUserId
        HStack(spacing: 10) {
            Rectangle()
                .fill(ColorTheme.accent)
                .frame(width: 3)
                .clipShape(Capsule())
            VStack(alignment: .leading, spacing: 2) {
                Text(mine ? "Replying to yourself" : "Replying to \(conversation.displayName)")
                    .font(.system(size: 12, weight: .semibold).width(.condensed))
                    .foregroundStyle(ColorTheme.accent)
                    .lineLimit(1)
                Text(replyPreviewText(for: target))
                    .font(.system(size: 13).width(.condensed))
                    .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                    .lineLimit(1)
            }
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { replyTarget = nil }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(ColorTheme.elevatedBackground(colorScheme))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ColorTheme.cardBackground(colorScheme).opacity(colorScheme == .dark ? 0.6 : 0.7)
        )
        .overlay(alignment: .top) {
            Rectangle().fill(ColorTheme.separator(colorScheme)).frame(height: 0.5)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    /// Best-effort one-liner preview for both the banner and the in-bubble
    /// quote: text body wins, attachments fall back to a label.
    private func replyPreviewText(for msg: DMMessage) -> String {
        if let body = msg.body, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return body
        }
        switch msg.attachmentType {
        case "image": return "Photo"
        case "video": return "Video"
        case "voice": return "Voice message"
        default: return "Attachment"
        }
    }

    /// Inline iOS menu anchored to the paperclip — the system pops it
    /// directly above the button instead of using a bottom-sheet
    /// confirmation dialog, which is what we want for an attachment picker.
    private var attachMenu: some View {
        Menu {
            Button {
                pickerMode = .photo
                showPhotoPicker = true
            } label: {
                Label("Photo", systemImage: "photo")
            }
            Button {
                pickerMode = .video
                showPhotoPicker = true
            } label: {
                Label("Video", systemImage: "video")
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    showCamera = true
                } label: {
                    Label("Camera", systemImage: "camera")
                }
            }
        } label: {
            Image(systemName: "paperclip")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(ColorTheme.accent)
                .frame(width: 30, height: 32)
                .contentShape(Rectangle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var sendOrMicButton: some View {
        if canSendText {
            Button { sendText() } label: {
                ZStack {
                    Circle().fill(ColorTheme.accentGradient)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: ColorTheme.accent.opacity(0.35), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .transition(.scale.combined(with: .opacity))
        } else {
            Button {
                Task { await tapMic() }
            } label: {
                ZStack {
                    Circle().fill(ColorTheme.accentGradient)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .shadow(color: ColorTheme.accent.opacity(0.25), radius: 3, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var recordingBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .opacity(0.85)
                .scaleEffect(isRecording ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isRecording)
            Text("Recording  \(formatDuration(recordingElapsed))")
                .font(.system(size: 14, weight: .semibold).width(.condensed).monospacedDigit())
                .foregroundStyle(ColorTheme.primaryText(colorScheme))
            Spacer()
            Button {
                stopRecording(submit: false)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle().fill(Color.red.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
            Button {
                Task { await stopAndSendVoice() }
            } label: {
                ZStack {
                    Circle().fill(ColorTheme.accentGradient)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)
                .shadow(color: ColorTheme.accent.opacity(0.35), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var uploadBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(ColorTheme.accent)
            ProgressView(value: uploadProgress)
                .progressViewStyle(.linear)
                .tint(ColorTheme.accent)
            Text("\(Int(uploadProgress * 100))%")
                .font(.system(size: 11).width(.condensed).monospacedDigit())
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }

    private var canSendText: Bool {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 2000
    }

    // MARK: - PhotosPicker plumbing

    private func handlePicked(_ item: PhotosPickerItem) async {
        defer { photoPickerItem = nil }
        do {
            if pickerMode == .photo {
                guard let data = try await item.loadTransferable(type: Data.self) else { return }
                await uploadAndSend(data: data, kind: "image", mime: "image/jpeg", filename: "photo.jpg")
            } else {
                guard let movie = try await item.loadTransferable(type: VideoTransfer.self) else { return }
                let url = movie.url
                let asset = AVURLAsset(url: url)
                let duration = try? await asset.load(.duration)
                if let d = duration, CMTimeGetSeconds(d) > 5 * 60 {
                    errorMessage = "Videos must be 5 minutes or less."
                    return
                }
                let data = try Data(contentsOf: url)
                if data.count > 100 * 1024 * 1024 {
                    errorMessage = "Video too large (max 100 MB)."
                    return
                }
                await uploadAndSend(data: data, kind: "video", mime: "video/mp4", filename: "video.mp4")
            }
        } catch {
            errorMessage = "Couldn't load that item."
        }
    }

    /// Converts a freshly-shot photo to JPEG and routes it through the same
    /// upload + send pipeline the photo picker uses. 0.85 quality matches
    /// what UIImagePickerController returns for `.original` images and keeps
    /// the upload comfortably under the multer 100 MB cap.
    private func handleCapturedPhoto(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            errorMessage = "Couldn't process photo."
            return
        }
        await uploadAndSend(data: data, kind: "image", mime: "image/jpeg", filename: "photo.jpg")
    }

    private func uploadAndSend(data: Data, kind: String, mime: String, filename: String) async {
        guard !isUploading else { return }
        isUploading = true
        uploadProgress = 0.1
        defer { isUploading = false; uploadProgress = 0 }
        do {
            let attachment = try await service.uploadMedia(
                data: data, kind: kind, mimeType: mime, filename: filename
            )
            uploadProgress = 0.9
            let m = try await service.sendAttachment(
                conversationId: conversation.id,
                kind: kind,
                attachment: attachment
            )
            appendOutgoing(m)
            errorMessage = nil
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Upload failed."
        }
    }

    // MARK: - Voice

    private func tapMic() async {
        let granted = await requestMicPermission()
        guard granted else {
            errorMessage = "Microphone access denied. Enable it in Settings → I Can → Microphone."
            return
        }
        startRecording()
    }

    private func requestMicPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted: return true
            case .denied: return false
            default:
                return await AVAudioApplication.requestRecordPermission()
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted: return true
            case .denied: return false
            default:
                return await withCheckedContinuation { cont in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        cont.resume(returning: granted)
                    }
                }
            }
        }
    }

    private func startRecording() {
        do {
            try voiceRecorder.start()
            isRecording = true
            recordingStart = Date()
            recordingElapsed = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if let s = recordingStart {
                    recordingElapsed = Date().timeIntervalSince(s)
                }
                if recordingElapsed >= 60 {
                    Task { await stopAndSendVoice() }
                }
            }
        } catch {
            errorMessage = "Can't access microphone: \(error.localizedDescription)"
        }
    }

    private func stopRecording(submit: Bool) {
        recordingTimer?.invalidate()
        recordingTimer = nil
        let url = voiceRecorder.stop()
        isRecording = false
        recordingElapsed = 0
        recordingStart = nil
        if !submit, let u = url { try? FileManager.default.removeItem(at: u) }
    }

    private func stopAndSendVoice() async {
        recordingTimer?.invalidate()
        recordingTimer = nil
        let elapsed = recordingElapsed
        guard let url = voiceRecorder.stop() else {
            isRecording = false
            return
        }
        isRecording = false
        recordingElapsed = 0
        recordingStart = nil

        if elapsed < 0.6 {
            try? FileManager.default.removeItem(at: url)
            return
        }
        do {
            let data = try Data(contentsOf: url)
            try? FileManager.default.removeItem(at: url)
            await uploadAndSend(data: data, kind: "voice", mime: "audio/m4a", filename: "voice.m4a")
        } catch {
            errorMessage = "Voice send failed."
        }
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    // MARK: - Loading

    private func initialLoad() async {
        otherLastSeenAt = conversation.other?.lastSeenAt
        await loadOlder(refresh: true)
        await service.markRead(conversationId: conversation.id)
        startPolling()
        startPresenceTicker()
    }

    /// Pure local timer: re-renders the subtitle every 30s so an "Online"
    /// label demotes to "Last seen…" once the window expires, even if the
    /// poll task is delayed.
    private func startPresenceTicker() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { return }
                presenceTick &+= 1
            }
        }
    }

    private func loadOlder(refresh: Bool) async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let cursor = refresh ? nil : nextCursor
            let page = try await service.loadMessages(
                conversationId: conversation.id,
                cursor: cursor
            )
            if refresh {
                setInitial(page.items)
            } else {
                mergeOlder(page.items)
            }
            nextCursor = page.nextCursor
            hasReachedEnd = page.nextCursor == nil
            applyPresence(page.otherLastSeenAt)
        } catch {
            // silent
        }
    }

    private func loadMoreIfNeeded(currentItem: DMMessage) async {
        guard !hasReachedEnd, !isLoading else { return }
        guard let idx = messages.firstIndex(where: { $0.id == currentItem.id }) else { return }
        if idx <= 5 { await loadOlder(refresh: false) }
    }

    /// Optimistic send — clears the draft and renders a placeholder bubble
    /// immediately so the input feels responsive. The placeholder is replaced
    /// with the server message on success, or removed and the draft restored
    /// on failure.
    private func sendText() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Snapshot the reply target up front so we can clear the banner
        // optimistically; the snapshot is what we actually pass to the API.
        let target = replyTarget
        let optimisticReplyPreview = target.map {
            DMReplyPreview(
                id: $0.id,
                senderId: $0.senderId,
                body: $0.body,
                attachmentType: $0.attachmentType
            )
        }

        let pendingId = "pending-\(UUID().uuidString)"
        let placeholder = DMMessage(
            id: pendingId,
            conversationId: conversation.id,
            senderId: currentUserId ?? "",
            body: trimmed,
            attachmentType: nil,
            attachmentRef: nil,
            createdAt: DMDate.now(),
            deliveredAt: nil,
            readAt: nil,
            replyTo: optimisticReplyPreview
        )

        draft = ""
        errorMessage = nil
        replyTarget = nil
        appendOutgoing(placeholder)

        Task {
            do {
                let m = try await service.send(
                    conversationId: conversation.id,
                    body: trimmed,
                    replyToMessageId: target?.id
                )
                replaceMessage(id: pendingId, with: m)
                // Restart polling so the next tick fires from "now", not from
                // wherever the previous sleep was. Keeps the receipt update
                // latency bounded by `pollInterval`, even if the user was idle.
                startPolling()
            } catch {
                removeMessage(id: pendingId)
                errorMessage = (error as? APIError)?.errorDescription ?? "Couldn't send."
                if draft.isEmpty { draft = trimmed }
                // Restore the reply target so the user can retry without
                // re-selecting the message.
                if replyTarget == nil { replyTarget = target }
            }
        }
    }

    private func deleteMessage(_ msg: DMMessage) async {
        let snapshot = messages
        let snapshotVersion = messagesVersion
        withAnimation(.easeInOut(duration: 0.2)) {
            removeMessage(id: msg.id)
        }
        do {
            try await service.deleteMessage(
                conversationId: conversation.id,
                messageId: msg.id
            )
            errorMessage = nil
        } catch {
            messages = snapshot
            messagesVersion = snapshotVersion &+ 1
            errorMessage = (error as? APIError)?.errorDescription ?? "Couldn't delete."
        }
    }

    /// Polling interval. Tight enough that delivered → read tick transitions
    /// feel near-instant when both users are in the chat; loose enough that
    /// it's not hammering the server. WhatsApp uses a websocket for this —
    /// a short poll is the lightweight stand-in.
    private static let pollInterval: Duration = .seconds(3)

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.pollInterval)
                guard !Task.isCancelled else { return }
                await pollLatest()
            }
        }
    }

    private func pollLatest() async {
        do {
            let page = try await service.loadMessages(
                conversationId: conversation.id,
                limit: 20
            )
            let added = mergeIncoming(page.items)
            applyPresence(page.otherLastSeenAt)
            if added > 0 {
                await service.markRead(conversationId: conversation.id)
            }
        } catch {
            // silent
        }
    }

    /// Only adopts a server-supplied timestamp if it's strictly newer than
    /// what we have. Prevents an out-of-order poll from rolling presence
    /// backwards (e.g. a slow request returning after a faster one).
    private func applyPresence(_ incoming: String?) {
        guard let incoming else { return }
        if let current = otherLastSeenAt,
           let currentDate = DMDate.parse(current),
           let incomingDate = DMDate.parse(incoming),
           incomingDate <= currentDate {
            return
        }
        otherLastSeenAt = incoming
    }

    // MARK: - Sorted-message mutation helpers

    /// Replaces all messages with the given collection (sorted ascending).
    private func setInitial(_ items: [DMMessage]) {
        messages = items.sorted(by: Self.ascending)
        messagesVersion &+= 1
        scrollToBottomToken &+= 1
    }

    /// Appends a message that is known to be the newest (just sent locally).
    /// O(1) — preserves the sorted invariant since it goes at the end.
    private func appendOutgoing(_ m: DMMessage) {
        messages.append(m)
        messagesVersion &+= 1
        scrollToBottomToken &+= 1
    }

    /// Replaces the pending placeholder with the real server message in place.
    /// Avoids a re-sort and avoids triggering scroll-to-bottom (the bubble is
    /// already in view).
    private func replaceMessage(id: String, with m: DMMessage) {
        guard let idx = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[idx] = m
        messagesVersion &+= 1
    }

    private func removeMessage(id: String) {
        let before = messages.count
        messages.removeAll { $0.id == id }
        if messages.count != before { messagesVersion &+= 1 }
    }

    /// Merges a poll response. Always rebuilds the array fresh — in-place
    /// element mutation was too easy for SwiftUI's diff to elide, which kept
    /// the sender's ticks frozen at one gray after the recipient delivered
    /// or read the message. Replacing the storage guarantees the bubbles
    /// re-render. Returns the number of brand-new messages so the caller
    /// knows whether to mark the conversation as read.
    @discardableResult
    private func mergeIncoming(_ incoming: [DMMessage]) -> Int {
        if incoming.isEmpty { return 0 }
        let incomingById = Dictionary(uniqueKeysWithValues: incoming.map { ($0.id, $0) })

        var rebuilt: [DMMessage] = []
        rebuilt.reserveCapacity(messages.count + incoming.count)
        var seenIds = Set<String>()
        var changed = false

        for current in messages {
            seenIds.insert(current.id)
            if let updated = incomingById[current.id], updated != current {
                rebuilt.append(updated)
                changed = true
            } else {
                rebuilt.append(current)
            }
        }

        var added = 0
        for msg in incoming where !seenIds.contains(msg.id) {
            rebuilt.append(msg)
            added += 1
            changed = true
        }

        guard changed else { return 0 }
        if added > 0 { rebuilt.sort(by: Self.ascending) }
        messages = rebuilt
        messagesVersion &+= 1
        if added > 0 { scrollToBottomToken &+= 1 }
        return added
    }

    /// Merges older messages from a pagination fetch. Does NOT scroll to
    /// bottom — the user is reading older history.
    private func mergeOlder(_ older: [DMMessage]) {
        if older.isEmpty { return }
        let existing = Set(messages.map(\.id))
        let toAdd = older.filter { !existing.contains($0.id) }
        if toAdd.isEmpty { return }
        messages.append(contentsOf: toAdd)
        messages.sort(by: Self.ascending)
        messagesVersion &+= 1
    }

    private static func ascending(_ a: DMMessage, _ b: DMMessage) -> Bool {
        (a.createdAtDate ?? .distantPast) < (b.createdAtDate ?? .distantPast)
    }
}

// MARK: - Messages list (Equatable subview)

/// Dedicated subview for the message list. The Equatable conformance lets
/// SwiftUI skip re-rendering the entire transcript while the user is typing
/// in the input field — `messagesVersion` only changes on real mutations,
/// so keystrokes that update the parent `draft` no longer thrash the list.
private struct ChatMessagesView: View, Equatable {
    let messages: [DMMessage]
    let messagesVersion: UInt64
    let scrollToken: UInt64
    let currentUserId: String?
    let peerDisplayName: String
    let colorScheme: ColorScheme
    let onDelete: (DMMessage) -> Void
    let onOpenImage: (URL) -> Void
    let onOpenVideo: (URL) -> Void
    let onLoadMore: (DMMessage) -> Void
    let onReply: (DMMessage) -> Void

    static func == (lhs: ChatMessagesView, rhs: ChatMessagesView) -> Bool {
        lhs.messagesVersion == rhs.messagesVersion
            && lhs.scrollToken == rhs.scrollToken
            && lhs.currentUserId == rhs.currentUserId
            && lhs.colorScheme == rhs.colorScheme
    }

    private enum ChatItem: Identifiable {
        case dateHeader(Date, id: String)
        case message(DMMessage, isFirstInGroup: Bool, isLastInGroup: Bool)

        var id: String {
            switch self {
            case .dateHeader(_, let id): return "date-\(id)"
            case .message(let m, _, _): return "msg-\(m.id)"
            }
        }
    }

    var body: some View {
        let items = buildItems()
        let lastMessageId = messages.last?.id

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                        row(item, prev: idx > 0 ? items[idx - 1] : nil)
                            .id(item.id)
                    }
                    Color.clear.frame(height: 6).id("bottomAnchor")
                }
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                if let last = lastMessageId {
                    proxy.scrollTo("msg-\(last)", anchor: .bottom)
                }
            }
            .onChange(of: scrollToken) { _, _ in
                guard let last = lastMessageId else { return }
                withAnimation(.easeOut(duration: 0.22)) {
                    proxy.scrollTo("msg-\(last)", anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ item: ChatItem, prev: ChatItem?) -> some View {
        switch item {
        case .dateHeader(let date, _):
            dateSeparator(date)
                .padding(.top, prev == nil ? 4 : 14)
                .padding(.bottom, 8)
        case .message(let msg, let isFirst, let isLast):
            let topPadding: CGFloat = {
                guard let prev else { return 4 }
                if case .dateHeader = prev { return 0 }
                return isFirst ? 8 : 2
            }()
            bubble(for: msg, isFirstInGroup: isFirst, isLastInGroup: isLast)
                .padding(.horizontal, 10)
                .padding(.top, topPadding)
                .padding(.bottom, isLast ? 2 : 0)
                .task { onLoadMore(msg) }
        }
    }

    @ViewBuilder
    private func bubble(for msg: DMMessage, isFirstInGroup: Bool, isLastInGroup: Bool) -> some View {
        let mine = msg.senderId == currentUserId
        MessageBubble(
            message: msg,
            isMe: mine,
            isFirstInGroup: isFirstInGroup,
            isLastInGroup: isLastInGroup,
            onDelete: mine ? { onDelete(msg) } : nil,
            onOpenImage: { url in onOpenImage(url) },
            onOpenVideo: { url in onOpenVideo(url) },
            onReply: { onReply(msg) },
            currentUserId: currentUserId,
            peerDisplayName: peerDisplayName
        )
        .opacity(msg.id.hasPrefix("pending-") ? 0.7 : 1.0)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .opacity
        ))
    }

    private func dateSeparator(_ date: Date) -> some View {
        HStack {
            Spacer()
            Text(Self.formatDateSeparator(date))
                .font(.system(size: 11, weight: .semibold).width(.condensed))
                .tracking(0.4)
                .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(ColorTheme.cardBackground(colorScheme).opacity(0.85))
                )
                .overlay(
                    Capsule()
                        .stroke(ColorTheme.separator(colorScheme), lineWidth: 0.5)
                )
            Spacer()
        }
    }

    /// Build the [ChatItem] list (date headers + grouped messages) once per
    /// real mutation. `messages` is already in ascending order.
    private func buildItems() -> [ChatItem] {
        var items: [ChatItem] = []
        items.reserveCapacity(messages.count + 4)
        let cal = Calendar.current
        let groupWindow: TimeInterval = 180
        var prevDate: Date?

        for index in 0..<messages.count {
            let msg = messages[index]
            let msgDate = msg.createdAtDate ?? Date()

            if let prev = prevDate, cal.isDate(prev, inSameDayAs: msgDate) {
                // same day, no header
            } else {
                let dayId = String(Int(cal.startOfDay(for: msgDate).timeIntervalSince1970))
                items.append(.dateHeader(msgDate, id: dayId))
            }

            let prevMsg = index > 0 ? messages[index - 1] : nil
            let nextMsg = index + 1 < messages.count ? messages[index + 1] : nil

            let isFirst: Bool = {
                guard let p = prevMsg,
                      p.senderId == msg.senderId,
                      let pd = p.createdAtDate,
                      cal.isDate(pd, inSameDayAs: msgDate),
                      msgDate.timeIntervalSince(pd) < groupWindow
                else { return true }
                return false
            }()
            let isLast: Bool = {
                guard let n = nextMsg,
                      n.senderId == msg.senderId,
                      let nd = n.createdAtDate,
                      cal.isDate(nd, inSameDayAs: msgDate),
                      nd.timeIntervalSince(msgDate) < groupWindow
                else { return true }
                return false
            }()
            items.append(.message(msg, isFirstInGroup: isFirst, isLastInGroup: isLast))
            prevDate = msgDate
        }
        return items
    }

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    private static let longDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMM d, yyyy", options: 0, locale: .current) ?? "MMM d, yyyy"
        return f
    }()

    private static func formatDateSeparator(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        if let days = cal.dateComponents([.day], from: date, to: Date()).day, days < 7 {
            return weekdayFormatter.string(from: date)
        }
        return longDateFormatter.string(from: date)
    }
}

// MARK: - Helpers

private struct VideoTransfer: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copyURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension)
            try? FileManager.default.removeItem(at: copyURL)
            try FileManager.default.copyItem(at: received.file, to: copyURL)
            return Self(url: copyURL)
        }
    }
}

struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private struct ChatImageViewer: View {
    let url: URL
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit()
                } else {
                    ProgressView().tint(.white)
                }
            }
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(.black.opacity(0.5)))
                    }
                    .padding(16)
                }
                Spacer()
            }
        }
    }
}

private struct ChatVideoPlayerView: View {
    let url: URL
    let onClose: () -> Void
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(.black.opacity(0.5)))
                    }
                    .padding(16)
                }
                Spacer()
            }
        }
        .onAppear {
            player = AVPlayer(url: url)
            player?.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

private final class VoiceRecorder {
    private var recorder: AVAudioRecorder?
    private var fileURL: URL?

    @available(iOS, deprecated: 18.0)
    private static func legacyBluetoothOption() -> AVAudioSession.CategoryOptions {
        .allowBluetooth
    }

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        let bluetoothOption: AVAudioSession.CategoryOptions
        if #available(iOS 18.0, *) {
            bluetoothOption = .allowBluetoothHFP
        } else {
            bluetoothOption = Self.legacyBluetoothOption()
        }
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, bluetoothOption])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
        let r = try AVAudioRecorder(url: url, settings: settings)
        r.record()
        recorder = r
        fileURL = url
    }

    func stop() -> URL? {
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return fileURL
    }
}

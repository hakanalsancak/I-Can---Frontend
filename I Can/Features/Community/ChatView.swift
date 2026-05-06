import SwiftUI
import PhotosUI
import AVFoundation
import AVKit
import UniformTypeIdentifiers

struct ChatView: View {
    let conversation: DMConversation

    @State private var service = DMService.shared
    @State private var messages: [DMMessage] = []
    @State private var draft: String = ""
    @State private var nextCursor: String?
    @State private var hasReachedEnd = false
    @State private var isLoading = false
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var pollTask: Task<Void, Never>?

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showAttachSheet = false
    @State private var showPhotoPicker = false
    @State private var pickerMode: PickerMode = .photo

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
        .task { await initialLoad() }
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
        .confirmationDialog("Attach", isPresented: $showAttachSheet, titleVisibility: .hidden) {
            Button("Photo") { pickerMode = .photo; showPhotoPicker = true }
            Button("Video") { pickerMode = .video; showPhotoPicker = true }
            Button("Cancel", role: .cancel) {}
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
                        Text(headerSubtitle)
                            .font(.system(size: 11.5).width(.condensed))
                            .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                            .lineLimit(1)
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

    private var headerSubtitle: String {
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

    // MARK: - Chat items (dates + grouped messages)

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

    private var orderedMessages: [DMMessage] {
        messages.sorted { ($0.createdAtDate ?? .distantPast) < ($1.createdAtDate ?? .distantPast) }
    }

    private var chatItems: [ChatItem] {
        let ordered = orderedMessages
        var items: [ChatItem] = []
        let cal = Calendar.current
        let groupWindow: TimeInterval = 180  // 3 minutes

        for (index, msg) in ordered.enumerated() {
            let prev = index > 0 ? ordered[index - 1] : nil
            let next = index + 1 < ordered.count ? ordered[index + 1] : nil

            // Day separator when day changes (or first message)
            let msgDay = msg.createdAtDate ?? Date()
            if let prev = prev,
               let prevDate = prev.createdAtDate,
               cal.isDate(prevDate, inSameDayAs: msgDay) {
                // same day, no header
            } else {
                let id = String(Int(cal.startOfDay(for: msgDay).timeIntervalSince1970))
                items.append(.dateHeader(msgDay, id: id))
            }

            // Grouping: same sender + within 3 min of neighbor
            let isFirst: Bool = {
                guard let prev = prev,
                      prev.senderId == msg.senderId,
                      let pd = prev.createdAtDate,
                      let md = msg.createdAtDate,
                      cal.isDate(pd, inSameDayAs: md),
                      md.timeIntervalSince(pd) < groupWindow
                else { return true }
                return false
            }()
            let isLast: Bool = {
                guard let next = next,
                      next.senderId == msg.senderId,
                      let nd = next.createdAtDate,
                      let md = msg.createdAtDate,
                      cal.isDate(nd, inSameDayAs: md),
                      nd.timeIntervalSince(md) < groupWindow
                else { return true }
                return false
            }()
            items.append(.message(msg, isFirstInGroup: isFirst, isLastInGroup: isLast))
        }
        return items
    }

    // MARK: - Messages list

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(chatItems.enumerated()), id: \.element.id) { idx, item in
                        chatItemRow(item, prev: idx > 0 ? chatItems[idx - 1] : nil)
                            .id(item.id)
                    }
                    Color.clear.frame(height: 6).id("bottomAnchor")
                }
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: orderedMessages.count) { _, _ in
                if let last = orderedMessages.last?.id {
                    withAnimation(.easeOut(duration: 0.22)) {
                        proxy.scrollTo("msg-\(last)", anchor: .bottom)
                    }
                }
            }
            .onChange(of: inputFocused) { _, focused in
                if focused, let last = orderedMessages.last?.id {
                    withAnimation(.easeOut(duration: 0.18)) {
                        proxy.scrollTo("msg-\(last)", anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let last = orderedMessages.last?.id {
                    proxy.scrollTo("msg-\(last)", anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func chatItemRow(_ item: ChatItem, prev: ChatItem?) -> some View {
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
            let bottomPadding: CGFloat = isLast ? 2 : 0
            bubble(for: msg, isFirstInGroup: isFirst, isLastInGroup: isLast)
                .padding(.horizontal, 10)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .task { await loadMoreIfNeeded(currentItem: msg) }
        }
    }

    private func dateSeparator(_ date: Date) -> some View {
        HStack {
            Spacer()
            Text(formatDateSeparator(date))
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

    private func formatDateSeparator(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        if let days = cal.dateComponents([.day], from: date, to: Date()).day, days < 7 {
            let f = DateFormatter()
            f.dateFormat = "EEEE"
            return f.string(from: date)
        }
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMM d, yyyy", options: 0, locale: .current) ?? "MMM d, yyyy"
        return f.string(from: date)
    }

    @ViewBuilder
    private func bubble(for msg: DMMessage, isFirstInGroup: Bool, isLastInGroup: Bool) -> some View {
        let mine = msg.senderId == currentUserId
        let onDelete: (() -> Void)? = mine
            ? { Task { await deleteMessage(msg) } }
            : nil
        MessageBubble(
            message: msg,
            isMe: mine,
            isFirstInGroup: isFirstInGroup,
            isLastInGroup: isLastInGroup,
            onDelete: onDelete,
            onOpenImage: { url in openImageURL = IdentifiableURL(url: url) },
            onOpenVideo: { url in openVideoURL = IdentifiableURL(url: url) }
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 0) {
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
                Button {
                    showAttachSheet = true
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(ColorTheme.accent)
                        .frame(width: 30, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

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

    @ViewBuilder
    private var sendOrMicButton: some View {
        if canSendText {
            Button { Task { await sendText() } } label: {
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
        return !trimmed.isEmpty && trimmed.count <= 2000 && !isSending
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
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                messages.append(m)
            }
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
        await loadOlder(refresh: true)
        await service.markRead(conversationId: conversation.id)
        startPolling()
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
                messages = page.items
            } else {
                let existing = Set(messages.map(\.id))
                messages.append(contentsOf: page.items.filter { !existing.contains($0.id) })
            }
            nextCursor = page.nextCursor
            hasReachedEnd = page.nextCursor == nil
        } catch {
            // silent
        }
    }

    private func loadMoreIfNeeded(currentItem: DMMessage) async {
        guard !hasReachedEnd, !isLoading else { return }
        let ordered = orderedMessages
        guard let idx = ordered.firstIndex(of: currentItem) else { return }
        if idx <= 5 { await loadOlder(refresh: false) }
    }

    private func sendText() async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSending = true
        defer { isSending = false }
        do {
            let m = try await service.send(conversationId: conversation.id, body: trimmed)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                messages.append(m)
            }
            draft = ""
            errorMessage = nil
            try? await service.loadInbox()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Couldn't send."
        }
    }

    private func deleteMessage(_ msg: DMMessage) async {
        let snapshot = messages
        withAnimation(.easeInOut(duration: 0.2)) {
            messages.removeAll { $0.id == msg.id }
        }
        do {
            try await service.deleteMessage(
                conversationId: conversation.id,
                messageId: msg.id
            )
            errorMessage = nil
            try? await service.loadInbox()
        } catch {
            messages = snapshot
            errorMessage = (error as? APIError)?.errorDescription ?? "Couldn't delete."
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(8))
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
            let existing = Set(messages.map(\.id))
            let newOnes = page.items.filter { !existing.contains($0.id) }
            if !newOnes.isEmpty {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    messages.append(contentsOf: newOnes)
                }
                await service.markRead(conversationId: conversation.id)
            }
        } catch {
            // silent
        }
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

import SwiftUI
import PhotosUI
import AVFoundation
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

    @Environment(\.colorScheme) private var colorScheme
    private let currentUserId: String? = AuthService.shared.currentUser?.id

    private enum PickerMode { case photo, video }

    var body: some View {
        ZStack {
            ColorTheme.background(colorScheme).ignoresSafeArea()
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
        .navigationDestination(isPresented: $showProfile) {
            if let other = conversation.other {
                CommunityProfileView(userId: other.id)
            }
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            backButton
            Button {
                showProfile = true
            } label: {
                HStack(spacing: 10) {
                    headerAvatar
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(conversation.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        if let sport = conversation.other?.sport {
                            Text(sport.capitalized)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.primary.opacity(0.08)).frame(height: 1)
        }
    }

    @ViewBuilder
    private var headerAvatar: some View {
        if let urlStr = conversation.other?.photoUrl, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                if let image = phase.image { image.resizable().scaledToFill() }
                else { Circle().fill(Color.secondary.opacity(0.2)) }
            }
        } else {
            Circle()
                .fill(ColorTheme.accent.opacity(0.2))
                .overlay(
                    Text(initials(conversation.displayName))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ColorTheme.accent)
                )
        }
    }

    @Environment(\.dismiss) private var dismiss
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
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

    // MARK: - Messages list

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(orderedMessages) { msg in
                        MessageBubble(
                            message: msg,
                            isMe: msg.senderId == currentUserId
                        )
                        .id(msg.id)
                        .padding(.horizontal, 12)
                        .task { await loadMoreIfNeeded(currentItem: msg) }
                    }
                    Color.clear.frame(height: 4).id("bottomAnchor")
                }
                .padding(.vertical, 8)
            }
            .onChange(of: orderedMessages.count) { _, _ in
                if let lastId = orderedMessages.last?.id {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let lastId = orderedMessages.last?.id {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }

    private var orderedMessages: [DMMessage] {
        messages.sorted { ($0.createdAtDate ?? .distantPast) < ($1.createdAtDate ?? .distantPast) }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            if let m = errorMessage {
                Text(m)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
            if isRecording {
                recordingBar
            } else {
                normalInputBar
            }
        }
        .background(.ultraThinMaterial)
    }

    private var normalInputBar: some View {
        HStack(spacing: 8) {
            Button {
                showAttachSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(ColorTheme.accent)
            }
            .buttonStyle(.plain)

            TextField("Message", text: $draft, axis: .vertical)
                .font(.system(size: 15))
                .textFieldStyle(.plain)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.secondary.opacity(0.10))
                )

            if canSendText {
                Button { Task { await sendText() } } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(ColorTheme.accent)
                }
                .buttonStyle(.plain)
                .disabled(!canSendText)
            } else {
                Button {
                    Task { await tapMic() }
                } label: {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var recordingBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .opacity(0.85)
            Text("Recording \(formatDuration(recordingElapsed))")
                .font(.system(size: 14, weight: .semibold).monospacedDigit())
            Spacer()
            Button {
                stopRecording(submit: false)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 18))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            Button {
                Task { await stopAndSendVoice() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(ColorTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var uploadBar: some View {
        HStack(spacing: 8) {
            ProgressView(value: uploadProgress)
                .progressViewStyle(.linear)
                .tint(ColorTheme.accent)
            Text("\(Int(uploadProgress * 100))%")
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(.secondary)
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
            messages.append(m)
            errorMessage = nil
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Upload failed."
        }
    }

    // MARK: - Voice

    private func tapMic() async {
        // Request mic permission up-front, with a clear error when denied.
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
            messages.append(m)
            draft = ""
            errorMessage = nil
            try? await service.loadInbox()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Couldn't send."
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
                messages.append(contentsOf: newOnes)
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

private final class VoiceRecorder {
    private var recorder: AVAudioRecorder?
    private var fileURL: URL?

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
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

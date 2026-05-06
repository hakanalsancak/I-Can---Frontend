import SwiftUI
import AVKit

struct MessageBubble: View {
    let message: DMMessage
    let isMe: Bool
    var onDelete: (() -> Void)? = nil
    @State private var showVideo = false
    @State private var showImage = false
    @State private var showDeleteConfirm = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            if isMe { Spacer(minLength: 40) }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                content
                    .contextMenu {
                        if isMe, onDelete != nil {
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                Text(timeString(message.createdAtDate))
                    .font(.system(size: 10).width(.condensed))
                    .foregroundStyle(.secondary)
            }
            if !isMe { Spacer(minLength: 40) }
        }
        .confirmationDialog(
            "Delete this message?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { onDelete?() }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var content: some View {
        switch message.attachmentType {
        case "image":
            imageContent
        case "video":
            videoContent
        case "voice":
            VoiceBubble(
                url: message.attachmentRef?.url,
                durationMs: message.attachmentRef?.durationMs,
                isMe: isMe
            )
        default:
            textBubble
        }
    }

    private var textBubble: some View {
        Text(message.body ?? "")
            .font(.system(size: 15).width(.condensed))
            .foregroundStyle(isMe ? Color.white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isMe
                          ? AnyShapeStyle(ColorTheme.accent)
                          : AnyShapeStyle(Color.secondary.opacity(0.12)))
            )
    }

    @ViewBuilder
    private var imageContent: some View {
        if let s = message.attachmentRef?.url, let url = URL(string: s) {
            Button {
                showImage = true
            } label: {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Rectangle().fill(Color.secondary.opacity(0.15))
                    }
                }
                .frame(width: 220, height: 220)
                .clipped()
                .contentShape(RoundedRectangle(cornerRadius: 14))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .fullScreenCover(isPresented: $showImage) {
                ImageViewer(url: url, onClose: { showImage = false })
            }
            if let body = message.body, !body.isEmpty {
                Text(body)
                    .font(.system(size: 14).width(.condensed))
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var videoContent: some View {
        if let s = message.attachmentRef?.url, let url = URL(string: s) {
            Button { showVideo = true } label: {
                ZStack {
                    Rectangle().fill(Color.black.opacity(0.6))
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }
                .frame(width: 220, height: 220)
                .clipped()
                .contentShape(RoundedRectangle(cornerRadius: 14))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .fullScreenCover(isPresented: $showVideo) {
                VideoPlayerView(url: url, onClose: { showVideo = false })
            }
        }
    }

    private func timeString(_ date: Date?) -> String {
        guard let d = date else { return "" }
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: d)
    }
}

private struct VoiceBubble: View {
    let url: String?
    let durationMs: Int?
    let isMe: Bool
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var elapsed: TimeInterval = 0
    @State private var timeObserverToken: Any?
    @Environment(\.colorScheme) private var colorScheme

    private let barCount = 22

    var body: some View {
        Button {
            togglePlay()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isMe ? Color.white : ColorTheme.accent)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(isMe ? Color.white.opacity(0.2) : ColorTheme.accent.opacity(0.18))
                    )
                waveform
                Text(displayedTime())
                    .font(.system(size: 12).width(.condensed).monospacedDigit())
                    .foregroundStyle(isMe ? Color.white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .contentShape(
                RoundedRectangle(cornerRadius: 18)
            )
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isMe
                          ? AnyShapeStyle(ColorTheme.accent)
                          : AnyShapeStyle(Color.secondary.opacity(0.12)))
            )
        }
        .buttonStyle(.plain)
    }

    private var waveform: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                let threshold = Double(i) / Double(barCount)
                let active = progress > threshold
                Capsule()
                    .fill(barColor(active: active))
                    .frame(width: 2, height: CGFloat(6 + (i % 5) * 4))
            }
        }
    }

    private func barColor(active: Bool) -> Color {
        if isMe {
            return active ? .white : Color.white.opacity(0.35)
        } else {
            return active ? ColorTheme.accent : ColorTheme.accent.opacity(0.3)
        }
    }

    private func togglePlay() {
        if isPlaying {
            player?.pause()
            isPlaying = false
            return
        }
        guard let s = url, let url = URL(string: s) else { return }

        // Route through the speaker and ignore the silent switch.
        // Without this, default session routing may send audio to the
        // receiver (earpiece) or be muted by silent mode entirely.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true, options: [])
        } catch {
            // Best effort — continue and let AVPlayer try anyway.
        }

        if player == nil {
            let p = AVPlayer(url: url)
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem,
                queue: .main
            ) { _ in
                isPlaying = false
                p.seek(to: .zero)
                progress = 0
                elapsed = 0
            }
            // 30Hz updates keep the waveform highlight smooth.
            let interval = CMTime(value: 1, timescale: 30)
            let token = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                let current = CMTimeGetSeconds(time)
                guard current.isFinite else { return }
                elapsed = current
                let total = resolveDurationSeconds(p)
                if total > 0 {
                    progress = min(1, max(0, current / total))
                }
            }
            timeObserverToken = token
            player = p
        }
        player?.play()
        isPlaying = true
    }

    private func resolveDurationSeconds(_ p: AVPlayer) -> Double {
        if let ms = durationMs, ms > 0 {
            return Double(ms) / 1000.0
        }
        let d = p.currentItem?.duration ?? .zero
        let s = CMTimeGetSeconds(d)
        return s.isFinite && s > 0 ? s : 0
    }

    private func displayedTime() -> String {
        let seconds: Int
        if isPlaying || (elapsed > 0 && progress < 1) {
            seconds = Int(elapsed)
        } else {
            seconds = (durationMs ?? 0) / 1000
        }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct ImageViewer: View {
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

private struct VideoPlayerView: View {
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

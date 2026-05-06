import SwiftUI
import AVKit

struct MessageBubble: View {
    let message: DMMessage
    let isMe: Bool
    @State private var showVideo = false
    @State private var showImage = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            if isMe { Spacer(minLength: 40) }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                content
                Text(timeString(message.createdAtDate))
                    .font(.system(size: 10).width(.condensed))
                    .foregroundStyle(.secondary)
            }
            if !isMe { Spacer(minLength: 40) }
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            Button {
                togglePlay()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isMe ? Color.white : ColorTheme.accent)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(isMe ? Color.white.opacity(0.2) : ColorTheme.accent.opacity(0.18))
                    )
            }
            .buttonStyle(.plain)
            HStack(spacing: 2) {
                ForEach(0..<14, id: \.self) { i in
                    Capsule()
                        .fill(isMe ? Color.white.opacity(0.6) : ColorTheme.accent.opacity(0.4))
                        .frame(width: 2, height: CGFloat(6 + (i % 5) * 4))
                }
            }
            Text(formatDuration())
                .font(.system(size: 12).width(.condensed).monospacedDigit())
                .foregroundStyle(isMe ? Color.white.opacity(0.8) : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isMe
                      ? AnyShapeStyle(ColorTheme.accent)
                      : AnyShapeStyle(Color.secondary.opacity(0.12)))
        )
    }

    private func togglePlay() {
        if isPlaying {
            player?.pause()
            isPlaying = false
            return
        }
        guard let s = url, let url = URL(string: s) else { return }
        if player == nil {
            let p = AVPlayer(url: url)
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem,
                queue: .main
            ) { _ in
                isPlaying = false
                p.seek(to: .zero)
            }
            player = p
        }
        player?.play()
        isPlaying = true
    }

    private func formatDuration() -> String {
        let s = (durationMs ?? 0) / 1000
        return String(format: "%d:%02d", s / 60, s % 60)
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

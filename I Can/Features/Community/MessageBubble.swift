import SwiftUI
import AVKit

struct MessageBubble: View {
    let message: DMMessage
    let isMe: Bool
    var isFirstInGroup: Bool = true
    var isLastInGroup: Bool = true
    var onDelete: (() -> Void)? = nil
    var onOpenImage: ((URL) -> Void)? = nil
    var onOpenVideo: ((URL) -> Void)? = nil

    @State private var showDeleteConfirm = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isMe { Spacer(minLength: 56) }
            content
                .contextMenu(menuItems: { menuContent })
            if !isMe { Spacer(minLength: 56) }
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
    private var menuContent: some View {
        let bodyText = message.body ?? ""
        if !bodyText.isEmpty {
            Button {
                copyToPasteboard(bodyText)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        if isMe, onDelete != nil {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch message.attachmentType {
        case "image":
            mediaBubble { imageContent }
        case "video":
            mediaBubble { videoContent }
        case "voice":
            VoiceBubble(
                url: message.attachmentRef?.url,
                durationMs: message.attachmentRef?.durationMs,
                isMe: isMe,
                isLastInGroup: isLastInGroup,
                timeText: timeString(message.createdAtDate)
            )
        default:
            textBubble
        }
    }

    // MARK: - Text bubble (WhatsApp-style inline timestamp)

    private var textBubble: some View {
        let body = message.body ?? ""
        return ZStack(alignment: .bottomTrailing) {
            Text(body)
                .font(.system(size: 15.5).width(.condensed))
                .foregroundStyle(isMe ? Color.white : ColorTheme.primaryText(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, isMe ? 58 : 44)
                .padding(.leading, 12)
                .padding(.top, 7)
                .padding(.bottom, 7)

            metadataRow
                .padding(.trailing, 10)
                .padding(.bottom, 5)
        }
        .background(bubbleFill)
        .clipShape(bubbleShape)
        .overlay(bubbleShape.stroke(borderColor, lineWidth: 0.5))
        .shadow(color: shadowColor, radius: 1.5, x: 0, y: 0.5)
    }

    // MARK: - Media bubble wrapper (image / video)

    @ViewBuilder
    private func mediaBubble<Inner: View>(@ViewBuilder _ inner: () -> Inner) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            inner()
                .clipShape(bubbleShape)
                .overlay(alignment: .bottomTrailing) {
                    metadataRow
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.45))
                        )
                        .padding(8)
                }
            if let captionText = message.body, !captionText.isEmpty {
                Text(captionText)
                    .font(.system(size: 14).width(.condensed))
                    .foregroundStyle(isMe ? Color.white : ColorTheme.primaryText(colorScheme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(bubbleFill)
            }
        }
        .background(bubbleFill)
        .clipShape(bubbleShape)
        .overlay(bubbleShape.stroke(borderColor, lineWidth: 0.5))
        .shadow(color: shadowColor, radius: 1.5, x: 0, y: 0.5)
    }

    @ViewBuilder
    private var imageContent: some View {
        if let s = message.attachmentRef?.url, let url = URL(string: s) {
            Button {
                onOpenImage?(url)
            } label: {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        ZStack {
                            Color.secondary.opacity(0.15)
                            ProgressView()
                        }
                    }
                }
                .frame(width: 240, height: 240)
                .clipped()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var videoContent: some View {
        if let s = message.attachmentRef?.url, let url = URL(string: s) {
            Button { onOpenVideo?(url) } label: {
                ZStack {
                    LinearGradient(
                        colors: [Color.black.opacity(0.55), Color.black.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(18)
                        .background(Circle().fill(Color.black.opacity(0.45)))
                }
                .frame(width: 240, height: 240)
                .clipped()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Metadata (time + sent check)

    private var metadataRow: some View {
        HStack(spacing: 3) {
            Text(timeString(message.createdAtDate))
                .font(.system(size: 10.5).width(.condensed).monospacedDigit())
            if isMe {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .foregroundStyle(isOnMedia ? Color.white : metadataColor)
    }

    private var isOnMedia: Bool {
        message.attachmentType == "image" || message.attachmentType == "video"
    }

    // MARK: - Bubble styling

    private var bubbleShape: UnevenRoundedRectangle {
        let big: CGFloat = 18
        let small: CGFloat = 6
        let bottomLeading: CGFloat = isMe ? big : (isLastInGroup ? small : big)
        let bottomTrailing: CGFloat = isMe ? (isLastInGroup ? small : big) : big
        return UnevenRoundedRectangle(
            topLeadingRadius: big,
            bottomLeadingRadius: bottomLeading,
            bottomTrailingRadius: bottomTrailing,
            topTrailingRadius: big,
            style: .continuous
        )
    }

    private var bubbleFill: AnyShapeStyle {
        if isMe {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        ColorTheme.accent,
                        Color(hex: "358A90")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(
                colorScheme == .dark
                ? Color(hex: "1F2D44")
                : Color.white
            )
        }
    }

    private var borderColor: Color {
        if isMe { return .clear }
        return colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.05)
    }

    private var shadowColor: Color {
        colorScheme == .dark ? .clear : Color.black.opacity(0.06)
    }

    private var metadataColor: Color {
        if isMe { return Color.white.opacity(0.85) }
        return ColorTheme.tertiaryText(colorScheme)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "j:mm", options: 0, locale: .current) ?? "HH:mm"
        return f
    }()

    private func timeString(_ date: Date?) -> String {
        guard let d = date else { return "" }
        return Self.timeFormatter.string(from: d)
    }

    private func copyToPasteboard(_ string: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = string
        #endif
    }
}

// MARK: - Voice bubble

private struct VoiceBubble: View {
    let url: String?
    let durationMs: Int?
    let isMe: Bool
    let isLastInGroup: Bool
    let timeText: String

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var elapsed: TimeInterval = 0
    @State private var timeObserverToken: Any?
    @Environment(\.colorScheme) private var colorScheme

    private let barCount = 26

    var body: some View {
        Button {
            togglePlay()
        } label: {
            HStack(spacing: 10) {
                playIcon
                waveform
                VStack(alignment: .trailing, spacing: 2) {
                    Text(displayedTime())
                        .font(.system(size: 11).width(.condensed).monospacedDigit())
                        .foregroundStyle(isMe ? Color.white.opacity(0.85) : .secondary)
                    Text(timeText)
                        .font(.system(size: 9.5).width(.condensed).monospacedDigit())
                        .foregroundStyle(isMe ? Color.white.opacity(0.7) : ColorTheme.tertiaryText(colorScheme))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(bubbleFill)
        .clipShape(bubbleShape)
    }

    private var bubbleShape: UnevenRoundedRectangle {
        let big: CGFloat = 18
        let small: CGFloat = 6
        let bottomLeading: CGFloat = isMe ? big : (isLastInGroup ? small : big)
        let bottomTrailing: CGFloat = isMe ? (isLastInGroup ? small : big) : big
        return UnevenRoundedRectangle(
            topLeadingRadius: big,
            bottomLeadingRadius: bottomLeading,
            bottomTrailingRadius: bottomTrailing,
            topTrailingRadius: big,
            style: .continuous
        )
    }

    private var bubbleFill: AnyShapeStyle {
        if isMe {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [ColorTheme.accent, Color(hex: "358A90")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(
                colorScheme == .dark ? Color(hex: "1F2D44") : Color.white
            )
        }
    }

    private var playIcon: some View {
        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(isMe ? ColorTheme.accent : Color.white)
            .frame(width: 34, height: 34)
            .background(
                Circle().fill(isMe ? Color.white : ColorTheme.accent)
            )
    }

    private var waveform: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                let threshold = Double(i) / Double(barCount)
                let active = progress > threshold
                Capsule()
                    .fill(barColor(active: active))
                    .frame(width: 2.5, height: barHeight(for: i))
            }
        }
    }

    private func barHeight(for i: Int) -> CGFloat {
        let pattern: [CGFloat] = [8, 14, 20, 12, 6, 18, 22, 10, 16, 24, 14, 8]
        return pattern[i % pattern.count]
    }

    private func barColor(active: Bool) -> Color {
        if isMe {
            return active ? .white : Color.white.opacity(0.4)
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

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true, options: [])
        } catch {
            // best effort
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


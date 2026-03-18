import SwiftUI

struct CoachChatView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var headerVisible = false
    @State private var chipsVisible = false
    @FocusState private var isInputFocused: Bool

    private let coachGradient = [Color(hex: "0EA5E9"), Color(hex: "22C55E")]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if messages.isEmpty {
                    emptyState
                } else {
                    messagesList
                }

                inputBar
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        coachAvatar(size: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("AI Coach")
                                .font(.system(size: 16, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                            Text(isLoading ? "Thinking..." : "Online")
                                .font(.system(size: 11, weight: .semibold).width(.condensed))
                                .foregroundColor(isLoading ? Color(hex: "F59E0B") : Color(hex: "22C55E"))
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(ColorTheme.secondaryText(colorScheme))
                    }
                }
            }
        }
    }

    // MARK: - Coach Avatar

    private func coachAvatar(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: coachGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color(hex: "0EA5E9").opacity(0.3), radius: size * 0.2, x: 0, y: size * 0.08)

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 50)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "0EA5E9").opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(headerVisible ? 1 : 0.8)
                        .opacity(headerVisible ? 1 : 0)

                    coachAvatar(size: 80)
                        .scaleEffect(headerVisible ? 1 : 0.5)
                        .opacity(headerVisible ? 1 : 0)
                }

                VStack(spacing: 10) {
                    Text("Your Personal Coach")
                        .font(.system(size: 26, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("Ask me anything about your sport —\ntraining, tactics, recovery, mindset, nutrition.")
                        .font(.system(size: 15, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 20)
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : 12)

                VStack(spacing: 10) {
                    suggestionChip("How can I improve my shooting?", icon: "scope", delay: 0)
                    suggestionChip("What should I eat before a game?", icon: "fork.knife", delay: 0.05)
                    suggestionChip("How do I deal with pre-game nerves?", icon: "brain", delay: 0.1)
                    suggestionChip("Create a recovery routine for me", icon: "heart.circle", delay: 0.15)
                }
                .padding(.top, 32)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
                headerVisible = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                chipsVisible = true
            }
        }
    }

    private func suggestionChip(_ text: String, icon: String, delay: Double) -> some View {
        Button {
            HapticManager.impact(.light)
            inputText = text
            sendMessage()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "0EA5E9").opacity(0.15), Color(hex: "22C55E").opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: coachGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                Text(text)
                    .font(.system(size: 14, weight: .semibold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color(hex: "0EA5E9").opacity(0.1), Color(hex: "22C55E").opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .opacity(chipsVisible ? 1 : 0)
        .offset(y: chipsVisible ? 0 : 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: chipsVisible)
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        let showAvatar = shouldShowAvatar(at: index)
                        messageBubble(message, showAvatar: showAvatar)
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(y: 12)).combined(with: .scale(scale: 0.97)),
                                removal: .opacity
                            ))
                    }

                    if isLoading {
                        typingIndicator
                            .id("typing")
                            .transition(.opacity.combined(with: .offset(y: 8)))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: messages.count)
                .animation(.easeOut(duration: 0.25), value: isLoading)
            }
            .onChange(of: messages.count) {
                Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    withAnimation(.easeOut(duration: 0.3)) {
                        if isLoading {
                            proxy.scrollTo("typing", anchor: .bottom)
                        } else if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: isLoading) {
                if isLoading {
                    Task {
                        try? await Task.sleep(for: .milliseconds(100))
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    private func shouldShowAvatar(at index: Int) -> Bool {
        guard index >= 0, index < messages.count else { return false }
        let msg = messages[index]
        if msg.isUser { return false }
        if index == 0 { return true }
        return messages[index - 1].isUser
    }

    private func messageBubble(_ message: ChatMessage, showAvatar: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isUser {
                if showAvatar {
                    coachAvatar(size: 28)
                        .padding(.bottom, 2)
                } else {
                    Spacer().frame(width: 28)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 3) {
                Text(message.content)
                    .font(.system(size: 15.5, weight: .regular))
                    .foregroundColor(message.isUser ? .white : ColorTheme.primaryText(colorScheme))
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if message.isUser {
                                LinearGradient(
                                    colors: [Color(hex: "0EA5E9"), Color(hex: "0284C7")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                ColorTheme.cardBackground(colorScheme)
                            }
                        }
                    )
                    .clipShape(ChatBubbleShape(isUser: message.isUser))
                    .shadow(
                        color: message.isUser
                            ? Color(hex: "0EA5E9").opacity(0.2)
                            : ColorTheme.cardShadow(colorScheme),
                        radius: message.isUser ? 8 : 4,
                        x: 0,
                        y: 2
                    )

                Text(message.timestamp, style: .time)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    .padding(.horizontal, 6)
                    .padding(.top, 1)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.78, alignment: message.isUser ? .trailing : .leading)

            if message.isUser {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .padding(.top, showAvatar && !message.isUser ? 12 : 2)
    }

    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: 8) {
            coachAvatar(size: 28)
                .padding(.bottom, 2)

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    TypingDot(delay: Double(i) * 0.2)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(ChatBubbleShape(isUser: false))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(ColorTheme.secondaryText(colorScheme).opacity(0.08))
                .frame(height: 0.5)

            HStack(alignment: .bottom, spacing: 10) {
                HStack(spacing: 0) {
                    TextField("Message your coach...", text: $inputText, axis: .vertical)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .lineLimit(1...6)
                        .focused($isInputFocused)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            isInputFocused
                                ? LinearGradient(colors: coachGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.5
                        )
                )

                Button {
                    sendMessage()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                canSend
                                    ? AnyShapeStyle(LinearGradient(colors: coachGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    : AnyShapeStyle(ColorTheme.cardBackground(colorScheme))
                            )
                            .frame(width: 40, height: 40)
                            .shadow(
                                color: canSend ? Color(hex: "0EA5E9").opacity(0.3) : .clear,
                                radius: 6, x: 0, y: 3
                            )

                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(canSend ? .white : ColorTheme.tertiaryText(colorScheme))
                    }
                }
                .disabled(!canSend)
                .animation(.easeOut(duration: 0.2), value: canSend)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                ColorTheme.background(colorScheme)
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: -2)
            )
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    // MARK: - Send

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        let userMessage = ChatMessage(role: "user", content: text)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            messages.append(userMessage)
        }
        inputText = ""
        HapticManager.impact(.light)

        Task {
            // Show typing indicator after a short delay, but cancel if the response arrives first
            let loadingTask = Task {
                try await Task.sleep(for: .milliseconds(400))
                withAnimation(.easeOut(duration: 0.25)) {
                    isLoading = true
                }
            }

            do {
                let reply = try await ChatService.shared.send(message: text, history: messages)
                loadingTask.cancel()
                let coachMessage = ChatMessage(role: "assistant", content: reply)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isLoading = false
                    messages.append(coachMessage)
                }
                HapticManager.impact(.light)
            } catch {
                loadingTask.cancel()
                let errMsg = ChatMessage(
                    role: "assistant",
                    content: "Sorry, I couldn't respond right now. Try again in a sec."
                )
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isLoading = false
                    messages.append(errMsg)
                }
            }
        }
    }
}

// MARK: - Chat Bubble Shape

struct ChatBubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 18
        let tail: CGFloat = 6
        var path = Path()

        if isUser {
            path.addRoundedRect(
                in: CGRect(x: 0, y: 0, width: rect.width - tail, height: rect.height),
                cornerRadii: .init(topLeading: r, bottomLeading: r, bottomTrailing: 4, topTrailing: r)
            )
            path.move(to: CGPoint(x: rect.width - tail, y: rect.height - 2))
            path.addQuadCurve(
                to: CGPoint(x: rect.width, y: rect.height + 2),
                control: CGPoint(x: rect.width - 2, y: rect.height)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.width - tail - 4, y: rect.height),
                control: CGPoint(x: rect.width - tail + 2, y: rect.height + 2)
            )
        } else {
            path.addRoundedRect(
                in: CGRect(x: tail, y: 0, width: rect.width - tail, height: rect.height),
                cornerRadii: .init(topLeading: r, bottomLeading: 4, bottomTrailing: r, topTrailing: r)
            )
            path.move(to: CGPoint(x: tail, y: rect.height - 2))
            path.addQuadCurve(
                to: CGPoint(x: 0, y: rect.height + 2),
                control: CGPoint(x: 2, y: rect.height)
            )
            path.addQuadCurve(
                to: CGPoint(x: tail + 4, y: rect.height),
                control: CGPoint(x: tail - 2, y: rect.height + 2)
            )
        }

        return path
    }
}

// MARK: - Typing Dot

struct TypingDot: View {
    let delay: Double
    @State private var animating = false

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "0EA5E9"), Color(hex: "22C55E")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 8, height: 8)
            .scaleEffect(animating ? 1.15 : 0.7)
            .opacity(animating ? 1 : 0.35)
            .animation(
                .easeInOut(duration: 0.55)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: animating
            )
            .onAppear { animating = true }
    }
}

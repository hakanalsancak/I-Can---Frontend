import SwiftUI

struct CoachChatView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var headerVisible = false
    @State private var chipsVisible = false
    @State private var showSubscription = false
    @State private var remainingMessages: Int? = nil
    @State private var limitReached = false
    @State private var resetAt: Date? = nil
    @State private var countdownText = ""
    @State private var countdownTimer: Timer? = nil
    @FocusState private var isInputFocused: Bool

    private let coachGradient = [Color(hex: "0EA5E9"), Color(hex: "22C55E")]
    private let dailyLimit = 7

    private var isPremium: Bool { SubscriptionService.shared.isPremium }

    private var coachImageName: String {
        let gender = AuthService.shared.currentUser?.gender ?? ""
        return gender == "male" ? "CoachMale" : "CoachFemale"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PageHeader("AI Coach")

                if messages.isEmpty && !limitReached {
                    emptyState
                } else if limitReached {
                    if messages.isEmpty {
                        limitReachedFullState
                    } else {
                        messagesList
                    }
                } else {
                    messagesList
                }

                if limitReached {
                    limitReachedBar
                } else {
                    inputBar
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showSubscription, onDismiss: {
                Task { try? await SubscriptionService.shared.checkStatus() }
                if SubscriptionService.shared.isPremium {
                    limitReached = false
                    remainingMessages = nil
                    clearLimitState()
                    stopCountdown()
                }
            }) {
                SubscriptionView()
            }
            .onAppear {
                if messages.isEmpty {
                    messages = ChatService.shared.loadMessages()
                }
                restoreLimitState()
            }
            .onDisappear {
                stopCountdown()
            }
        }
    }

    private func persistMessages() {
        ChatService.shared.saveMessages(messages)
    }

    // MARK: - Coach Avatar

    private func coachAvatar(size: CGFloat) -> some View {
        Image(coachImageName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .shadow(color: Color(hex: "0EA5E9").opacity(0.3), radius: size * 0.2, x: 0, y: size * 0.08)
    }

    // MARK: - Remaining Messages Banner

    private var remainingBanner: some View {
        Group {
            if !isPremium, let remaining = remainingMessages, !limitReached {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(remaining <= 2 ? Color(hex: "F59E0B") : Color(hex: "0EA5E9"))

                    Text("\(remaining) message\(remaining == 1 ? "" : "s") left today")
                        .font(.system(size: 13, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Spacer()

                    Button {
                        HapticManager.impact(.light)
                        showSubscription = true
                    } label: {
                        Text("Go Unlimited")
                            .font(.system(size: 12, weight: .bold).width(.condensed))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                LinearGradient(colors: coachGradient, startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    (remaining <= 2 ? Color(hex: "F59E0B") : Color(hex: "0EA5E9")).opacity(0.08)
                )
            }
        }
    }

    // MARK: - Limit Reached Full State

    private var limitReachedFullState: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer().frame(height: 50)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "F59E0B").opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "clock.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                VStack(spacing: 8) {
                    Text("Daily Limit Reached")
                        .font(.system(size: 26, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("You've used all \(dailyLimit) free messages today")
                        .font(.system(size: 15, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }

                if !countdownText.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Resets in \(countdownText)")
                            .font(.system(size: 16, weight: .bold).width(.condensed))
                    }
                    .foregroundColor(Color(hex: "F59E0B"))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color(hex: "F59E0B").opacity(0.1))
                    .clipShape(Capsule())
                }

                VStack(spacing: 12) {
                    Button {
                        HapticManager.impact(.medium)
                        showSubscription = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Unlock Unlimited Messages")
                                .font(.system(size: 16, weight: .bold).width(.condensed))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: coachGradient, startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color(hex: "0EA5E9").opacity(0.35), radius: 12, x: 0, y: 6)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "EAB308"))
                        Text("1 month free trial included")
                            .font(.system(size: 13, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Limit Reached Bar (replaces input bar)

    private var limitReachedBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(ColorTheme.secondaryText(colorScheme).opacity(0.08))
                .frame(height: 0.5)

            VStack(spacing: 10) {
                if !countdownText.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "F59E0B"))
                        Text("Resets in \(countdownText)")
                            .font(.system(size: 13, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                    }
                }

                Button {
                    HapticManager.impact(.medium)
                    showSubscription = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Unlock Unlimited Messages")
                            .font(.system(size: 15, weight: .bold).width(.condensed))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(colors: coachGradient, startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                ColorTheme.background(colorScheme)
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: -2)
            )
        }
    }

    // MARK: - Countdown Helpers

    private func startCountdown(to resetDate: Date) {
        resetAt = resetDate
        limitReached = true
        persistLimitState(resetDate: resetDate)
        updateCountdownText()
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                updateCountdownText()
            }
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func updateCountdownText() {
        guard let resetAt else {
            countdownText = ""
            return
        }
        let remaining = resetAt.timeIntervalSinceNow
        if remaining <= 0 {
            countdownText = ""
            limitReached = false
            remainingMessages = dailyLimit
            clearLimitState()
            stopCountdown()
            return
        }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        countdownText = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func persistLimitState(resetDate: Date) {
        UserDefaults.standard.set(resetDate.timeIntervalSince1970, forKey: "chat_limit_reset_at")
    }

    private func clearLimitState() {
        UserDefaults.standard.removeObject(forKey: "chat_limit_reset_at")
    }

    private func restoreLimitState() {
        guard !isPremium else { return }
        let stored = UserDefaults.standard.double(forKey: "chat_limit_reset_at")
        guard stored > 0 else { return }
        let resetDate = Date(timeIntervalSince1970: stored)
        if resetDate.timeIntervalSinceNow > 0 {
            resetAt = resetDate
            limitReached = true
            remainingMessages = 0
            updateCountdownText()
            countdownTimer?.invalidate()
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                Task { @MainActor in
                    updateCountdownText()
                }
            }
        } else {
            clearLimitState()
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
        GeometryReader { geometry in
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    remainingBanner

                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        let showAvatar = shouldShowAvatar(at: index)
                        messageBubble(message, showAvatar: showAvatar, containerWidth: geometry.size.width)
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
    }

    private func shouldShowAvatar(at index: Int) -> Bool {
        guard index >= 0, index < messages.count else { return false }
        let msg = messages[index]
        if msg.isUser { return false }
        if index == 0 { return true }
        return messages[index - 1].isUser
    }

    private func messageBubble(_ message: ChatMessage, showAvatar: Bool, containerWidth: CGFloat = 350) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 0)
            }

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
            .frame(maxWidth: containerWidth * 0.78, alignment: message.isUser ? .trailing : .leading)
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
        guard !text.isEmpty, !isLoading, !limitReached else { return }

        let userMessage = ChatMessage(role: "user", content: text)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            messages.append(userMessage)
        }
        persistMessages()
        inputText = ""
        HapticManager.impact(.light)

        Task {
            let loadingTask = Task {
                try await Task.sleep(for: .milliseconds(400))
                withAnimation(.easeOut(duration: 0.25)) {
                    isLoading = true
                }
            }

            do {
                let result = try await ChatService.shared.send(message: text, history: messages)
                loadingTask.cancel()
                let coachMessage = ChatMessage(role: "assistant", content: result.reply)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isLoading = false
                    messages.append(coachMessage)
                }
                persistMessages()
                if let remaining = result.remaining {
                    remainingMessages = remaining
                    if remaining <= 0 {
                        // Next message will be blocked, calculate reset
                        let now = Date()
                        let calendar = Calendar(identifier: .gregorian)
                        var utcCalendar = calendar
                        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                        if let tomorrow = utcCalendar.date(byAdding: .day, value: 1, to: now) {
                            let resetDate = utcCalendar.startOfDay(for: tomorrow)
                            limitReached = true
                            startCountdown(to: resetDate)
                        }
                    }
                }
                HapticManager.impact(.light)
            } catch let error as APIError {
                loadingTask.cancel()
                switch error {
                case .dailyLimitExceeded(let resetDate):
                    // Remove the user message we just added since it wasn't processed
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        isLoading = false
                        if let lastIdx = messages.indices.last, messages[lastIdx].isUser {
                            messages.removeLast()
                        }
                    }
                    persistMessages()
                    limitReached = true
                    remainingMessages = 0
                    if let resetDate {
                        startCountdown(to: resetDate)
                    }
                default:
                    let errMsg = ChatMessage(
                        role: "assistant",
                        content: "Sorry, I couldn't respond right now. Try again in a sec."
                    )
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        isLoading = false
                        messages.append(errMsg)
                    }
                }
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

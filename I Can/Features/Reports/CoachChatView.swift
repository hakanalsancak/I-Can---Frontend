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
    @State private var countdownTask: Task<Void, Never>? = nil
    @State private var currentConversationId: String? = nil
    @State private var showHistory = false
    @State private var isLoadingConversation = false
    @State private var appearedMessageIDs: Set<UUID> = []
    @State private var streamingMessageID: UUID? = nil
    @State private var streamingDisplayText: String = ""
    @State private var streamingTask: Task<Void, Never>? = nil
    @FocusState private var isInputFocused: Bool

    private let coachGradient = [Color(hex: "0EA5E9"), Color(hex: "22C55E")]
    private let dailyLimit = 15

    private var isPremium: Bool { SubscriptionService.shared.isPremium }

    private var coachImageName: String {
        let gender = AuthService.shared.currentUser?.gender ?? ""
        return gender == "male" ? "CoachMale" : "CoachFemale"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                coachHeader

                if isLoadingConversation {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(Color(hex: "0EA5E9"))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if messages.isEmpty && !limitReached {
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
            .onTapGesture { isInputFocused = false }
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
            .sheet(isPresented: $showHistory) {
                ChatHistoryView(
                    onSelectConversation: { id in
                        Task { await loadConversation(id) }
                    },
                    onNewChat: {
                        startNewChat()
                    }
                )
            }
            .onAppear {
                if messages.isEmpty {
                    messages = ChatService.shared.loadMessages()
                    // Mark all loaded messages as already appeared (no animation)
                    appearedMessageIDs = Set(messages.map(\.id))
                }
                restoreLimitState()
            }
            .onDisappear {
                stopCountdown()
                streamingTask?.cancel()
            }
        }
    }

    // MARK: - Coach Header

    private var coachHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Coach avatar + status
                ZStack(alignment: .bottomTrailing) {
                    coachAvatar(size: 36)

                    Circle()
                        .fill(Color(hex: "22C55E"))
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .strokeBorder(ColorTheme.background(colorScheme), lineWidth: 2)
                        )
                        .offset(x: 1, y: 1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Coach")
                        .font(.system(size: 18, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("Active now")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "22C55E"))
                }

                Spacer()

                HStack(spacing: 14) {
                    Button {
                        HapticManager.impact(.light)
                        startNewChat()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(colors: coachGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 36, height: 36)
                            .background(ColorTheme.cardBackground(colorScheme))
                            .clipShape(Circle())
                    }

                    Button {
                        HapticManager.impact(.light)
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(colors: coachGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 36, height: 36)
                            .background(ColorTheme.cardBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Rectangle()
                .fill(ColorTheme.secondaryText(colorScheme).opacity(0.08))
                .frame(height: 0.5)
        }
    }

    private func persistMessages() {
        ChatService.shared.saveMessages(messages)
    }

    private func loadConversation(_ id: String) async {
        isLoadingConversation = true
        do {
            let response = try await ChatService.shared.fetchMessages(conversationId: id)
            let loaded = response.messages.map { $0.toChatMessage() }
            withAnimation(.easeOut(duration: 0.2)) {
                messages = loaded
                currentConversationId = id
                appearedMessageIDs = Set(loaded.map(\.id))
            }
            persistMessages()
        } catch {
            #if DEBUG
            print("CoachChatView: failed to load conversation - \(error.localizedDescription)")
            #endif
        }
        isLoadingConversation = false
    }

    private func startNewChat() {
        streamingTask?.cancel()
        streamingMessageID = nil
        streamingDisplayText = ""
        withAnimation(.easeOut(duration: 0.2)) {
            messages = []
            currentConversationId = nil
            headerVisible = false
            chipsVisible = false
            appearedMessageIDs = []
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
            headerVisible = true
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
            chipsVisible = true
        }
    }

    // MARK: - Coach Avatar

    private func coachAvatar(size: CGFloat) -> some View {
        Image(coachImageName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .shadow(color: Color(hex: "0EA5E9").opacity(0.25), radius: size * 0.15, x: 0, y: size * 0.06)
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
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "EAB308"))
                        Text("Premium feature")
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
        countdownTask?.cancel()
        countdownTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                updateCountdownText()
            }
        }
    }

    private func stopCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
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

    private static let limitResetKeychainKey = "chat_limit_reset_at"

    private func persistLimitState(resetDate: Date) {
        let value = String(resetDate.timeIntervalSince1970)
        KeychainHelper.save(value, forKey: Self.limitResetKeychainKey)
    }

    private func clearLimitState() {
        KeychainHelper.delete(forKey: Self.limitResetKeychainKey)
    }

    private func restoreLimitState() {
        guard !isPremium else { return }
        guard let storedString = KeychainHelper.readString(forKey: Self.limitResetKeychainKey),
              let stored = Double(storedString), stored > 0 else { return }
        let resetDate = Date(timeIntervalSince1970: stored)
        if resetDate.timeIntervalSinceNow > 0 {
            remainingMessages = 0
            startCountdown(to: resetDate)
        } else {
            clearLimitState()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 40)

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
                    Text("Your Elite Coach")
                        .font(.system(size: 26, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))

                    Text("Training, tactics, recovery, mindset, nutrition.\nI know your data. Let's get to work.")
                        .font(.system(size: 15, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 20)
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : 12)

                VStack(spacing: 10) {
                    suggestionChip("Review my recent training", icon: "chart.line.uptrend.xyaxis", delay: 0)
                    suggestionChip("What should I focus on today?", icon: "scope", delay: 0.05)
                    suggestionChip("Help me with pre-game prep", icon: "brain", delay: 0.1)
                    suggestionChip("Build a recovery plan for me", icon: "heart.circle", delay: 0.15)
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
                LazyVStack(spacing: 6) {
                    remainingBanner

                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        let showAvatar = shouldShowAvatar(at: index)
                        messageBubble(message, showAvatar: showAvatar, containerWidth: geometry.size.width)
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(y: 16)).combined(with: .scale(scale: 0.96)),
                                removal: .opacity
                            ))
                            .onAppear {
                                appearedMessageIDs.insert(message.id)
                            }
                    }

                    if isLoading {
                        typingIndicator
                            .id("typing")
                            .transition(.opacity.combined(with: .offset(y: 8)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: messages.count)
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
            .onChange(of: streamingDisplayText) {
                // Scroll every ~5 words during streaming (throttle)
                if let id = streamingMessageID,
                   streamingDisplayText.filter({ $0 == " " }).count % 5 == 0 {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(id, anchor: .bottom)
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

    // MARK: - Message Bubble

    private func messageBubble(_ message: ChatMessage, showAvatar: Bool, containerWidth: CGFloat = 350) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 0)
            }

            if !message.isUser {
                if showAvatar {
                    coachAvatar(size: 30)
                        .padding(.bottom, 2)
                } else {
                    Spacer().frame(width: 30)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Message content — use streaming text if this message is currently being revealed
                Group {
                    if message.isUser {
                        Text(message.content)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white)
                    } else {
                        let displayText = message.id == streamingMessageID ? streamingDisplayText : message.content
                        formattedCoachText(displayText)
                    }
                }
                .lineSpacing(5)
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
                            colorScheme == .dark
                                ? Color(hex: "1E293B")
                                : Color(hex: "F1F5F9")
                        }
                    }
                )
                .clipShape(ChatBubbleShape(isUser: message.isUser))
                .shadow(
                    color: message.isUser
                        ? Color(hex: "0EA5E9").opacity(0.15)
                        : ColorTheme.cardShadow(colorScheme),
                    radius: message.isUser ? 8 : 3,
                    x: 0,
                    y: 2
                )

                Text(message.timestamp, style: .time)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                    .padding(.horizontal, 6)
                    .padding(.top, 1)
            }
            .frame(maxWidth: containerWidth * 0.82, alignment: message.isUser ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .padding(.top, showAvatar && !message.isUser ? 14 : 2)
    }

    /// Renders coach text with paragraph breaks and **bold** support
    private func formattedCoachText(_ text: String) -> some View {
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        return VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                let lines = paragraph.components(separatedBy: "\n")
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        parseBoldText(line)
                    }
                }
            }
        }
    }

    /// Parses **bold** markers in a line and returns styled Text
    private func parseBoldText(_ line: String) -> Text {
        let textColor = ColorTheme.primaryText(colorScheme)
        var result = Text("")
        var remaining = line[line.startIndex...]

        while let boldStart = remaining.range(of: "**") {
            // Add text before **
            let before = remaining[remaining.startIndex..<boldStart.lowerBound]
            if !before.isEmpty {
                result = result + Text(String(before))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(textColor)
            }

            let afterOpen = remaining[boldStart.upperBound...]
            if let boldEnd = afterOpen.range(of: "**") {
                // Add bold text between ** and **
                let boldContent = afterOpen[afterOpen.startIndex..<boldEnd.lowerBound]
                result = result + Text(String(boldContent))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(textColor)
                remaining = afterOpen[boldEnd.upperBound...]
            } else {
                // No closing **, treat rest as normal text
                result = result + Text(String(remaining[boldStart.lowerBound...]))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(textColor)
                remaining = remaining[remaining.endIndex...]
            }
        }

        // Add any remaining text
        if !remaining.isEmpty {
            result = result + Text(String(remaining))
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(textColor)
        }

        // If the line was empty or had no bold markers, ensure font is set
        if line.isEmpty {
            return Text("")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(textColor)
        }

        return result
    }

    private var typingIndicator: some View {
        HStack(alignment: .bottom, spacing: 8) {
            coachAvatar(size: 30)
                .padding(.bottom, 2)

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    TypingDot(delay: Double(i) * 0.2)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                colorScheme == .dark
                    ? Color(hex: "1E293B")
                    : Color(hex: "F1F5F9")
            )
            .clipShape(ChatBubbleShape(isUser: false))
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 3, x: 0, y: 2)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 14)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(ColorTheme.secondaryText(colorScheme).opacity(0.06))
                .frame(height: 0.5)

            HStack(alignment: .bottom, spacing: 10) {
                HStack(spacing: 0) {
                    TextField("Message your coach...", text: $inputText, axis: .vertical)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .lineLimit(1...6)
                        .focused($isInputFocused)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                }
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            isInputFocused
                                ? LinearGradient(colors: coachGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(
                                    colors: [ColorTheme.secondaryText(colorScheme).opacity(0.15),
                                             ColorTheme.secondaryText(colorScheme).opacity(0.1)],
                                    startPoint: .top, endPoint: .bottom
                                  ),
                            lineWidth: isInputFocused ? 1.5 : 0.5
                        )
                )
                .shadow(
                    color: isInputFocused ? Color(hex: "0EA5E9").opacity(0.08) : .clear,
                    radius: 8, x: 0, y: 2
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
                            .frame(width: 42, height: 42)
                            .shadow(
                                color: canSend ? Color(hex: "0EA5E9").opacity(0.3) : .clear,
                                radius: 8, x: 0, y: 3
                            )

                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(canSend ? .white : ColorTheme.tertiaryText(colorScheme))
                    }
                    .scaleEffect(canSend ? 1.0 : 0.92)
                }
                .disabled(!canSend)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canSend)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                ColorTheme.background(colorScheme)
                    .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 8, x: 0, y: -2)
            )
        }
    }

    private var isStreaming: Bool { streamingMessageID != nil }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isStreaming
    }

    // MARK: - Send

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading, !limitReached else { return }

        let userMessage = ChatMessage(role: "user", content: text)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
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
                let result = try await ChatService.shared.send(message: text, history: messages, conversationId: currentConversationId)
                loadingTask.cancel()
                if let newId = result.conversationId {
                    currentConversationId = newId
                }
                let coachMessage = ChatMessage(role: "assistant", content: result.reply)
                // Prepare streaming state BEFORE appending so the full text never flashes
                streamingMessageID = coachMessage.id
                streamingDisplayText = ""
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    isLoading = false
                    messages.append(coachMessage)
                }
                startStreamingReveal(for: coachMessage)
                if let remaining = result.remaining {
                    remainingMessages = remaining
                    if remaining <= 0 {
                        let now = Date()
                        var utcCalendar = Calendar(identifier: .gregorian)
                        utcCalendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
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
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
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
                        content: "Couldn't get through right now. Give it another shot."
                    )
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        isLoading = false
                        messages.append(errMsg)
                    }
                }
            } catch {
                loadingTask.cancel()
                let errMsg = ChatMessage(
                    role: "assistant",
                    content: "Couldn't get through right now. Give it another shot."
                )
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    isLoading = false
                    messages.append(errMsg)
                }
            }
        }
    }

    // MARK: - Streaming Reveal

    private func startStreamingReveal(for message: ChatMessage) {
        streamingTask?.cancel()
        streamingMessageID = message.id
        streamingDisplayText = ""

        let fullText = message.content
        // Split into words preserving whitespace/newlines
        let words = splitIntoTokens(fullText)

        streamingTask = Task { @MainActor in
            for i in words.indices {
                guard !Task.isCancelled else { break }
                streamingDisplayText += words[i]

                // Adaptive speed: faster for short words, slight pause after punctuation
                let word = words[i].trimmingCharacters(in: .whitespaces)
                let delay: UInt64
                if word.last == "." || word.last == "?" || word.last == "!" {
                    delay = 60_000_000 // 60ms after sentence endings
                } else if word.last == "," || word.last == ":" {
                    delay = 40_000_000 // 40ms after commas/colons
                } else {
                    delay = 25_000_000 // 25ms default per word
                }
                try? await Task.sleep(nanoseconds: delay)
            }

            // Streaming done — finalize
            streamingMessageID = nil
            streamingDisplayText = ""
            persistMessages()
        }
    }

    /// Splits text into words while keeping whitespace/newlines attached
    private func splitIntoTokens(_ text: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inWhitespace = false

        for char in text {
            if char == " " || char == "\n" {
                if !inWhitespace && !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                current.append(char)
                inWhitespace = true
            } else {
                if inWhitespace {
                    tokens.append(current)
                    current = ""
                    inWhitespace = false
                }
                current.append(char)
            }
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }
}

// MARK: - Chat Bubble Shape

struct ChatBubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 20
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

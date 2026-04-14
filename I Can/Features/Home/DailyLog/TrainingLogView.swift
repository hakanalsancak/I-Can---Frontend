import SwiftUI

// MARK: - Session Editor State

@Observable
final class SessionEditorState {
    var trainingType = ""
    var duration = 60
    var notes = ""

    // Match
    var matchType = "match"
    var result = ""
    var performanceRating = 5
    var minutesPlayed = 90
    var position = ""
    var keyStats: [String: Int] = [:]

    // Gym
    var gymFocus = ""
    var effortLevel = ""
    var exercises: [String] = []
    var exerciseInput = ""

    // Cardio
    var cardioType = ""
    var distance: Double = 0
    var pace = ""
    var cardioEffort = ""

    // Technical
    var skillTrained = ""
    var focusQuality = ""

    // Tactical
    var tacticalType = ""
    var understandingLevel = ""

    // Recovery
    var recoveryType = ""

    // Legacy
    var intensity = ""
    var details: Set<String> = []

    func toSession() -> TrainingSession {
        var session = TrainingSession(
            trainingType: trainingType,
            duration: duration,
            intensity: intensity,
            details: Array(details),
            notes: notes.isEmpty ? nil : notes
        )

        switch trainingType {
        case "match":
            session.matchType = matchType
            session.result = result.isEmpty ? nil : result
            session.performanceRating = performanceRating
            session.minutesPlayed = minutesPlayed
            session.position = position.isEmpty ? nil : position
            session.keyStats = keyStats.isEmpty ? nil : keyStats
        case "gym":
            session.gymFocus = gymFocus.isEmpty ? nil : gymFocus
            session.effortLevel = effortLevel.isEmpty ? nil : effortLevel
            session.exercises = exercises.isEmpty ? nil : exercises
        case "cardio":
            session.cardioType = cardioType.isEmpty ? nil : cardioType
            session.distance = distance > 0 ? distance : nil
            session.pace = pace.isEmpty ? nil : pace
            session.cardioEffort = cardioEffort.isEmpty ? nil : cardioEffort
        case "technical":
            session.skillTrained = skillTrained.isEmpty ? nil : skillTrained
            session.focusQuality = focusQuality.isEmpty ? nil : focusQuality
        case "tactical":
            session.tacticalType = tacticalType.isEmpty ? nil : tacticalType
            session.understandingLevel = understandingLevel.isEmpty ? nil : understandingLevel
        case "recovery":
            session.recoveryType = recoveryType.isEmpty ? nil : recoveryType
        default:
            break
        }

        session.computeAndSetScore()
        return session
    }

    func load(from session: TrainingSession) {
        trainingType = session.trainingType
        duration = session.duration
        intensity = session.intensity
        details = Set(session.details)
        notes = session.notes ?? ""

        matchType = session.matchType ?? "match"
        result = session.result ?? ""
        performanceRating = session.performanceRating ?? 5
        minutesPlayed = session.minutesPlayed ?? 90
        position = session.position ?? ""
        keyStats = session.keyStats ?? [:]

        gymFocus = session.gymFocus ?? ""
        effortLevel = session.effortLevel ?? ""
        exercises = session.exercises ?? []

        cardioType = session.cardioType ?? ""
        distance = session.distance ?? 0
        pace = session.pace ?? ""
        cardioEffort = session.cardioEffort ?? ""

        skillTrained = session.skillTrained ?? ""
        focusQuality = session.focusQuality ?? ""

        tacticalType = session.tacticalType ?? ""
        understandingLevel = session.understandingLevel ?? ""

        recoveryType = session.recoveryType ?? ""
    }

    func reset() {
        trainingType = ""
        duration = 60
        notes = ""
        intensity = ""
        details = []
        matchType = "match"
        result = ""
        performanceRating = 5
        minutesPlayed = 90
        position = ""
        keyStats = [:]
        gymFocus = ""
        effortLevel = ""
        exercises = []
        exerciseInput = ""
        cardioType = ""
        distance = 0
        pace = ""
        cardioEffort = ""
        skillTrained = ""
        focusQuality = ""
        tacticalType = ""
        understandingLevel = ""
        recoveryType = ""
    }
}

// MARK: - Training Log View

struct TrainingLogView: View {
    let existingData: TrainingData?
    let onSave: (TrainingData) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var sessions: [TrainingSession] = []
    @State private var showAddSession = false
    @State private var editingSessionIndex: Int?
    @State private var inlineEditor = SessionEditorState()

    private var userSport: String {
        AuthService.shared.currentUser?.sport ?? "soccer"
    }

    init(existingData: TrainingData?, onSave: @escaping (TrainingData) -> Void) {
        self.existingData = existingData
        self.onSave = onSave
        if let d = existingData {
            _sessions = State(initialValue: d.sessions)
        }
    }

    private var isInlineEditing: Bool {
        sessions.isEmpty && !inlineEditor.trainingType.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if sessions.isEmpty && inlineEditor.trainingType.isEmpty {
                        emptyState
                    } else if isInlineEditing {
                        inlineEditorView
                    } else {
                        sessionListView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ColorTheme.training)
                        Text("Training")
                            .font(.system(size: 17, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 30, height: 30)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showAddSession) {
                SessionEditorView(
                    sport: userSport,
                    existingSession: editingSessionIndex != nil ? sessions[editingSessionIndex!] : nil
                ) { session in
                    if let idx = editingSessionIndex {
                        sessions[idx] = session
                    } else {
                        sessions.append(session)
                    }
                    editingSessionIndex = nil
                }
            }
        }
    }

    // MARK: - Session List (existing sessions)

    private var sessionListView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                HStack {
                    Text("YOUR SESSIONS")
                        .font(.system(size: 11, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    Spacer()
                    Text("\(sessions.count) session\(sessions.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.training)
                }

                ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                    sessionCard(session, index: index)
                }
            }

            totalSummaryCard

            // Add another
            Button {
                HapticManager.impact(.medium)
                editingSessionIndex = nil
                showAddSession = true
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(ColorTheme.training.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(ColorTheme.training)
                    }
                    Text("Add Another Session")
                        .font(.system(size: 14, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                }
                .padding(12)
                .background(ColorTheme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(ColorTheme.training.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(LogCardButtonStyle())

            // Save Button
            Button {
                HapticManager.impact(.medium)
                save()
            } label: {
                Text("SAVE TRAINING")
                    .font(.system(size: 15, weight: .heavy).width(.condensed))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ColorTheme.trainingGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: ColorTheme.training.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Session Card

    private func sessionCard(_ session: TrainingSession, index: Int) -> some View {
        Button {
            HapticManager.selection()
            editingSessionIndex = index
            showAddSession = true
        } label: {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(ColorTheme.training.opacity(0.12))
                            .frame(width: 38, height: 38)
                        Image(systemName: session.trainingTypeIcon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(ColorTheme.training)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.trainingTypeDisplay)
                            .font(.system(size: 15, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))

                        Text(session.typeSpecificSummary)
                            .font(.system(size: 11, weight: .medium).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }

                    Spacer()

                    // Session score badge
                    if let score = session.sessionScore {
                        sessionScoreBadge(score)
                    }

                    // Edit / Delete
                    HStack(spacing: 6) {
                        Button {
                            HapticManager.selection()
                            editingSessionIndex = index
                            showAddSession = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ColorTheme.accent)
                                .frame(width: 28, height: 28)
                                .background(ColorTheme.accent.opacity(0.1))
                                .clipShape(Circle())
                        }

                        Button {
                            HapticManager.impact(.light)
                            _ = withAnimation(.easeInOut(duration: 0.25)) {
                                sessions.remove(at: index)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "EF4444"))
                                .frame(width: 28, height: 28)
                                .background(Color(hex: "EF4444").opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }

                // Result badge for match
                if session.trainingType == "match", let result = session.resultDisplay {
                    HStack(spacing: 6) {
                        resultBadge(result)
                        if let rating = session.performanceRating {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "F59E0B"))
                                Text("\(rating)/10")
                                    .font(.system(size: 11, weight: .bold).width(.condensed))
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "F59E0B").opacity(0.1))
                            .clipShape(Capsule())
                        }
                        Spacer()
                    }
                }

                // Detail chips (gym exercises, etc.)
                if !session.details.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(session.details, id: \.self) { detail in
                                Text(detail)
                                    .font(.system(size: 11, weight: .semibold).width(.condensed))
                                    .foregroundColor(ColorTheme.training)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(ColorTheme.training.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                    }
                }

                if let exercises = session.exercises, !exercises.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(exercises, id: \.self) { ex in
                                Text(ex)
                                    .font(.system(size: 11, weight: .semibold).width(.condensed))
                                    .foregroundColor(Color(hex: "8B5CF6"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "8B5CF6").opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                        }
                    }
                }

                if let notes = session.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 12, weight: .regular).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                }
            }
            .padding(14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(ColorTheme.training.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(LogCardButtonStyle())
    }

    private func resultBadge(_ result: String) -> some View {
        let color: Color = switch result {
        case "Win": Color(hex: "22C55E")
        case "Loss": Color(hex: "EF4444")
        default: Color(hex: "F59E0B")
        }
        return Text(result.uppercased())
            .font(.system(size: 11, weight: .heavy).width(.condensed))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func sessionScoreBadge(_ score: Int) -> some View {
        let color: Color = if score >= 80 {
            Color(hex: "22C55E")
        } else if score >= 50 {
            ColorTheme.accent
        } else {
            Color(hex: "F97316")
        }
        return VStack(spacing: 1) {
            Text("\(score)")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text("SCORE")
                .font(.system(size: 7, weight: .heavy).width(.condensed))
                .foregroundColor(color.opacity(0.7))
        }
        .frame(width: 44, height: 44)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Total Summary

    private var totalSummaryCard: some View {
        HStack(spacing: 0) {
            summaryItem(
                value: "\(sessions.count)",
                label: "Sessions",
                color: ColorTheme.training
            )

            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(width: 1, height: 32)

            summaryItem(
                value: "\(sessions.reduce(0) { $0 + $1.duration })m",
                label: "Total Time",
                color: ColorTheme.accent
            )

            Rectangle()
                .fill(ColorTheme.separator(colorScheme))
                .frame(width: 1, height: 32)

            let avgScore = sessions.compactMap { $0.sessionScore }.isEmpty
                ? 0
                : sessions.compactMap { $0.sessionScore }.reduce(0, +) / max(sessions.compactMap { $0.sessionScore }.count, 1)
            summaryItem(
                value: "\(avgScore)",
                label: "Avg Score",
                color: Color(hex: "8B5CF6")
            )
        }
        .padding(.vertical, 14)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
    }

    private func summaryItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Typography.number(20))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .bold).width(.condensed))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(ColorTheme.training.opacity(0.1))
                    .frame(width: 90, height: 90)
                Circle()
                    .fill(ColorTheme.training.opacity(0.06))
                    .frame(width: 130, height: 130)
                Image(systemName: "figure.run")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(ColorTheme.training)
            }

            VStack(spacing: 8) {
                Text("Log Your Training")
                    .font(.system(size: 22, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("Select your session type below.\nEach type has its own tailored form.")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            VStack(spacing: 8) {
                Text("WHAT DID YOU DO TODAY?")
                    .font(.system(size: 10, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.tertiaryText(colorScheme))

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                ], spacing: 10) {
                    ForEach([
                        ("match", "Match", "trophy.fill"),
                        ("gym", "Gym", "dumbbell.fill"),
                        ("cardio", "Cardio", "heart.circle.fill"),
                        ("technical", "Technical", "figure.run"),
                        ("tactical", "Tactical", "brain.head.profile"),
                        ("recovery", "Recovery", "leaf.fill"),
                    ], id: \.0) { type, label, icon in
                        Button {
                            HapticManager.selection()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                inlineEditor.reset()
                                inlineEditor.trainingType = type
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: icon)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(label)
                                    .font(.system(size: 14, weight: .semibold).width(.condensed))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ColorTheme.cardBackground(colorScheme))
                            .foregroundColor(ColorTheme.primaryText(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(ColorTheme.training.opacity(0.15), lineWidth: 1)
                            )
                            .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(LogCardButtonStyle())
                    }
                }
            }
            .padding(.top, 4)

            Spacer()
        }
    }

    // MARK: - Inline Editor (type-specific forms)

    private var inlineEditorView: some View {
        VStack(spacing: 16) {
            // Selected type header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: TrainingSession(trainingType: inlineEditor.trainingType, duration: 0, intensity: "", details: []).trainingTypeIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(ColorTheme.training)
                    Text(TrainingSession(trainingType: inlineEditor.trainingType, duration: 0, intensity: "", details: []).trainingTypeDisplay)
                        .font(.system(size: 16, weight: .heavy).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
                Spacer()
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        inlineEditor.reset()
                    }
                } label: {
                    Text("Change")
                        .font(.system(size: 13, weight: .semibold).width(.condensed))
                        .foregroundColor(ColorTheme.training)
                }
            }
            .padding(14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(ColorTheme.training.opacity(0.2), lineWidth: 1)
            )

            // Type-specific form sections
            switch inlineEditor.trainingType {
            case "match":
                matchFormSections
            case "gym":
                gymFormSections
            case "cardio":
                cardioFormSections
            case "technical":
                technicalFormSections
            case "tactical":
                tacticalFormSections
            case "recovery":
                recoveryFormSections
            default:
                genericFormSections
            }

            // Notes (all types)
            sectionCard(title: "NOTES (OPTIONAL)", icon: "note.text") {
                TextField("How was this session?", text: $inlineEditor.notes, axis: .vertical)
                    .font(.system(size: 15, weight: .regular).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .lineLimit(3...6)
                    .padding(12)
                    .background(ColorTheme.elevatedBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Quick Save + Save buttons
            HStack(spacing: 10) {
                // Quick Save — saves with current defaults and dismisses
                Button {
                    HapticManager.impact(.medium)
                    let session = inlineEditor.toSession()
                    sessions.append(session)
                    let data = TrainingData(sessions: sessions, sport: userSport)
                    onSave(data)
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("QUICK SAVE")
                            .font(.system(size: 13, weight: .heavy).width(.condensed))
                    }
                    .foregroundColor(ColorTheme.training)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ColorTheme.training.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(ColorTheme.training.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                // Save session — adds to list
                Button {
                    HapticManager.impact(.medium)
                    let session = inlineEditor.toSession()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        sessions.append(session)
                        inlineEditor.reset()
                    }
                } label: {
                    Text("SAVE SESSION")
                        .font(.system(size: 13, weight: .heavy).width(.condensed))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ColorTheme.trainingGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: ColorTheme.training.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Match Form

    @ViewBuilder
    private var matchFormSections: some View {
        // Match Type
        sectionCard(title: "MATCH TYPE", icon: "trophy.fill") {
            HStack(spacing: 8) {
                ForEach([("match", "Match"), ("sparring", "Sparring"), ("competition", "Competition")], id: \.0) { value, label in
                    chipButton(label: label, isSelected: inlineEditor.matchType == value) {
                        inlineEditor.matchType = value
                    }
                }
            }
        }

        // Result
        sectionCard(title: "RESULT", icon: "flag.fill") {
            HStack(spacing: 8) {
                ForEach([("win", "Win", "22C55E"), ("loss", "Loss", "EF4444"), ("draw", "Draw", "F59E0B")], id: \.0) { value, label, hex in
                    Button {
                        HapticManager.selection()
                        inlineEditor.result = value
                    } label: {
                        Text(label)
                            .font(.system(size: 14, weight: .bold).width(.condensed))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                inlineEditor.result == value
                                    ? Color(hex: hex).opacity(0.15)
                                    : ColorTheme.elevatedBackground(colorScheme)
                            )
                            .foregroundColor(
                                inlineEditor.result == value
                                    ? Color(hex: hex)
                                    : ColorTheme.secondaryText(colorScheme)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(
                                        inlineEditor.result == value ? Color(hex: hex).opacity(0.4) : .clear,
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        // Performance Rating
        sectionCard(title: "PERFORMANCE RATING", icon: "star.fill") {
            VStack(spacing: 12) {
                HStack {
                    ForEach(1...10, id: \.self) { i in
                        Button {
                            HapticManager.selection()
                            inlineEditor.performanceRating = i
                        } label: {
                            Image(systemName: i <= inlineEditor.performanceRating ? "star.fill" : "star")
                                .font(.system(size: 18))
                                .foregroundColor(i <= inlineEditor.performanceRating ? Color(hex: "F59E0B") : ColorTheme.tertiaryText(colorScheme))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("\(inlineEditor.performanceRating)/10")
                    .font(.system(size: 14, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }
        }

        // Minutes Played
        sectionCard(title: "MINUTES PLAYED", icon: "clock.fill") {
            VStack(spacing: 12) {
                Text("\(inlineEditor.minutesPlayed) min")
                    .font(Typography.number(32))
                    .foregroundColor(ColorTheme.training)

                HStack(spacing: 10) {
                    ForEach([45, 60, 70, 80, 90], id: \.self) { mins in
                        quickDurationButton(mins, binding: $inlineEditor.minutesPlayed)
                    }
                }

                Slider(value: Binding(
                    get: { Double(inlineEditor.minutesPlayed) },
                    set: { inlineEditor.minutesPlayed = Int($0) }
                ), in: 1...120, step: 1)
                .tint(ColorTheme.training)
            }
        }

        // Position (optional)
        sectionCard(title: "POSITION (OPTIONAL)", icon: "mappin.circle.fill") {
            TextField("e.g. Striker, Point Guard, Flyweight...", text: $inlineEditor.position)
                .font(.system(size: 15, weight: .regular).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .padding(12)
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }

        // Key Stats (sport-specific)
        matchKeyStatsSection
    }

    @ViewBuilder
    private var matchKeyStatsSection: some View {
        let statFields = matchStatFields(for: userSport)
        if !statFields.isEmpty {
            sectionCard(title: "KEY STATS (OPTIONAL)", icon: "chart.bar.fill") {
                VStack(spacing: 8) {
                    ForEach(statFields, id: \.key) { field in
                        StatInputRow(
                            label: field.label,
                            icon: field.icon,
                            value: Binding(
                                get: { inlineEditor.keyStats[field.key] ?? 0 },
                                set: { inlineEditor.keyStats[field.key] = $0 }
                            )
                        )
                    }
                }
            }
        }
    }

    private func matchStatFields(for sport: String) -> [(key: String, label: String, icon: String)] {
        switch sport.lowercased() {
        case "soccer":
            return [("goals", "Goals", "sportscourt.fill"), ("assists", "Assists", "arrow.right.arrow.left"), ("shotsOnTarget", "Shots on Target", "scope")]
        case "basketball":
            return [("points", "Points", "basketball.fill"), ("assists", "Assists", "arrow.right.arrow.left"), ("rebounds", "Rebounds", "arrow.up.circle")]
        case "tennis":
            return [("setsWon", "Sets Won", "checkmark.circle"), ("aces", "Aces", "bolt.fill"), ("winners", "Winners", "star.fill")]
        case "boxing":
            return [("roundsFought", "Rounds", "figure.boxing"), ("cleanPunches", "Clean Punches", "bolt.fill"), ("knockdowns", "Knockdowns", "arrow.down.circle")]
        case "football":
            return [("touchdowns", "Touchdowns", "football.fill"), ("yardsGained", "Yards", "arrow.right"), ("tackles", "Tackles", "shield.fill")]
        case "cricket":
            return [("runsScored", "Runs", "figure.cricket"), ("wicketsTaken", "Wickets", "flame.fill"), ("catches", "Catches", "hand.raised.fill")]
        default:
            return [("points", "Points / Score", "star.fill")]
        }
    }

    // MARK: - Gym Form

    @ViewBuilder
    private var gymFormSections: some View {
        // Focus
        sectionCard(title: "FOCUS", icon: "dumbbell.fill") {
            HStack(spacing: 8) {
                ForEach([("strength", "Strength"), ("hypertrophy", "Hypertrophy"), ("power", "Power"), ("conditioning", "Conditioning")], id: \.0) { value, label in
                    chipButton(label: label, isSelected: inlineEditor.gymFocus == value) {
                        inlineEditor.gymFocus = value
                    }
                }
            }
        }

        // Duration
        durationSection(binding: $inlineEditor.duration)

        // Effort Level
        sectionCard(title: "EFFORT LEVEL", icon: "flame.fill") {
            HStack(spacing: 8) {
                ForEach([("easy", "Easy"), ("moderate", "Moderate"), ("hard", "Hard"), ("failure", "Failure")], id: \.0) { value, label in
                    chipButton(label: label, isSelected: inlineEditor.effortLevel == value) {
                        inlineEditor.effortLevel = value
                    }
                }
            }
        }

        // Exercises (optional list)
        sectionCard(title: "EXERCISES (OPTIONAL)", icon: "list.bullet") {
            VStack(spacing: 10) {
                if !inlineEditor.exercises.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(inlineEditor.exercises, id: \.self) { exercise in
                            HStack(spacing: 4) {
                                Text(exercise)
                                    .font(.system(size: 12, weight: .semibold).width(.condensed))
                                Button {
                                    inlineEditor.exercises.removeAll { $0 == exercise }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                }
                            }
                            .foregroundColor(Color(hex: "8B5CF6"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: "8B5CF6").opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }

                HStack(spacing: 8) {
                    TextField("Add exercise...", text: $inlineEditor.exerciseInput)
                        .font(.system(size: 14, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(ColorTheme.elevatedBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .onSubmit { addExercise() }

                    Button {
                        addExercise()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(
                                inlineEditor.exerciseInput.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? ColorTheme.tertiaryText(colorScheme)
                                    : ColorTheme.training
                            )
                    }
                    .disabled(inlineEditor.exerciseInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func addExercise() {
        let trimmed = inlineEditor.exerciseInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if !inlineEditor.exercises.contains(where: { $0.lowercased() == trimmed.lowercased() }) {
            inlineEditor.exercises.append(trimmed)
        }
        inlineEditor.exerciseInput = ""
        HapticManager.selection()
    }

    // MARK: - Cardio Form

    @ViewBuilder
    private var cardioFormSections: some View {
        // Cardio Type
        sectionCard(title: "TYPE", icon: "heart.circle.fill") {
            HStack(spacing: 8) {
                ForEach([("run", "Run"), ("bike", "Bike"), ("swim", "Swim")], id: \.0) { value, label in
                    chipButton(label: label, isSelected: inlineEditor.cardioType == value) {
                        inlineEditor.cardioType = value
                    }
                }
            }
        }

        // Distance
        sectionCard(title: "DISTANCE (KM)", icon: "map.fill") {
            VStack(spacing: 12) {
                Text(String(format: "%.1f km", inlineEditor.distance))
                    .font(Typography.number(32))
                    .foregroundColor(ColorTheme.training)

                HStack(spacing: 10) {
                    ForEach([3.0, 5.0, 8.0, 10.0, 15.0], id: \.self) { km in
                        Button {
                            HapticManager.selection()
                            inlineEditor.distance = km
                        } label: {
                            Text(String(format: "%.0f", km))
                                .font(.system(size: 13, weight: .bold).width(.condensed))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    inlineEditor.distance == km
                                        ? ColorTheme.training.opacity(0.15)
                                        : ColorTheme.elevatedBackground(colorScheme)
                                )
                                .foregroundColor(
                                    inlineEditor.distance == km
                                        ? ColorTheme.training
                                        : ColorTheme.secondaryText(colorScheme)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Slider(value: $inlineEditor.distance, in: 0...50, step: 0.5)
                    .tint(ColorTheme.training)
            }
        }

        // Time
        durationSection(binding: $inlineEditor.duration, title: "TIME", presets: [15, 20, 30, 45, 60])

        // Pace (optional)
        sectionCard(title: "PACE (OPTIONAL)", icon: "speedometer") {
            TextField("e.g. 5:30 /km", text: $inlineEditor.pace)
                .font(.system(size: 15, weight: .regular).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .padding(12)
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }

        // Effort
        sectionCard(title: "EFFORT", icon: "flame.fill") {
            HStack(spacing: 8) {
                ForEach([("light", "Light"), ("moderate", "Moderate"), ("hard", "Hard")], id: \.0) { value, label in
                    chipButton(label: label, isSelected: inlineEditor.cardioEffort == value) {
                        inlineEditor.cardioEffort = value
                    }
                }
            }
        }
    }

    // MARK: - Technical Form

    @ViewBuilder
    private var technicalFormSections: some View {
        // Skill trained
        sectionCard(title: "SKILL TRAINED", icon: "target") {
            VStack(spacing: 10) {
                let skills = TrainingSession.technicalDetails(sport: userSport)
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                ], spacing: 8) {
                    ForEach(skills, id: \.self) { skill in
                        chipButton(label: skill, isSelected: inlineEditor.skillTrained == skill) {
                            inlineEditor.skillTrained = inlineEditor.skillTrained == skill ? "" : skill
                        }
                    }
                }

                TextField("Or type your own...", text: $inlineEditor.skillTrained)
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(ColorTheme.elevatedBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }

        // Duration
        durationSection(binding: $inlineEditor.duration)

        // Focus Quality
        sectionCard(title: "FOCUS QUALITY", icon: "eye.fill") {
            HStack(spacing: 8) {
                ForEach([("poor", "Poor"), ("average", "Average"), ("good", "Good"), ("elite", "Elite")], id: \.0) { value, label in
                    chipButton(label: label, isSelected: inlineEditor.focusQuality == value) {
                        inlineEditor.focusQuality = value
                    }
                }
            }
        }
    }

    // MARK: - Tactical Form

    @ViewBuilder
    private var tacticalFormSections: some View {
        // Type
        sectionCard(title: "SESSION TYPE", icon: "brain.head.profile") {
            HStack(spacing: 8) {
                ForEach([("team_session", "Team Session"), ("analysis", "Analysis")], id: \.0) { value, label in
                    chipButton(label: label, isSelected: inlineEditor.tacticalType == value) {
                        inlineEditor.tacticalType = value
                    }
                }
            }
        }

        // Duration
        durationSection(binding: $inlineEditor.duration)

        // Understanding Level
        sectionCard(title: "UNDERSTANDING LEVEL", icon: "brain") {
            HStack(spacing: 8) {
                ForEach([("low", "Low"), ("medium", "Medium"), ("high", "High")], id: \.0) { value, label in
                    chipButton(label: label, isSelected: inlineEditor.understandingLevel == value) {
                        inlineEditor.understandingLevel = value
                    }
                }
            }
        }
    }

    // MARK: - Recovery Form

    @ViewBuilder
    private var recoveryFormSections: some View {
        // Recovery Type
        sectionCard(title: "RECOVERY TYPE", icon: "leaf.fill") {
            HStack(spacing: 8) {
                ForEach([("stretching", "Stretching"), ("ice_bath", "Ice Bath"), ("massage", "Massage"), ("rest", "Rest")], id: \.0) { value, label in
                    chipButton(label: label, isSelected: inlineEditor.recoveryType == value) {
                        inlineEditor.recoveryType = value
                    }
                }
            }
        }

        // Duration (optional for recovery)
        sectionCard(title: "DURATION (OPTIONAL)", icon: "clock.fill") {
            VStack(spacing: 12) {
                Text("\(inlineEditor.duration) min")
                    .font(Typography.number(32))
                    .foregroundColor(ColorTheme.training)

                HStack(spacing: 10) {
                    ForEach([10, 15, 20, 30, 60], id: \.self) { mins in
                        quickDurationButton(mins, binding: $inlineEditor.duration)
                    }
                }

                Slider(value: Binding(
                    get: { Double(inlineEditor.duration) },
                    set: { inlineEditor.duration = Int($0) }
                ), in: 5...120, step: 5)
                .tint(ColorTheme.training)
            }
        }
    }

    // MARK: - Generic Form (fallback for custom types)

    @ViewBuilder
    private var genericFormSections: some View {
        let options = TrainingSession.detailOptions(for: inlineEditor.trainingType, sport: userSport)
        if !options.isEmpty {
            sectionCard(title: "DETAILS", icon: "list.bullet") {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                ], spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        chipButton(label: option, isSelected: inlineEditor.details.contains(option)) {
                            if inlineEditor.details.contains(option) {
                                inlineEditor.details.remove(option)
                            } else {
                                inlineEditor.details.insert(option)
                            }
                        }
                    }
                }
            }
        }

        durationSection(binding: $inlineEditor.duration)
    }

    // MARK: - Shared Form Components

    private func durationSection(binding: Binding<Int>, title: String = "DURATION", presets: [Int] = [30, 45, 60, 90, 120]) -> some View {
        sectionCard(title: title, icon: "clock.fill") {
            VStack(spacing: 12) {
                Text("\(binding.wrappedValue) min")
                    .font(Typography.number(32))
                    .foregroundColor(ColorTheme.training)

                HStack(spacing: 10) {
                    ForEach(presets, id: \.self) { mins in
                        quickDurationButton(mins, binding: binding)
                    }
                }

                Slider(value: Binding(
                    get: { Double(binding.wrappedValue) },
                    set: { binding.wrappedValue = Int($0) }
                ), in: 10...180, step: 5)
                .tint(ColorTheme.training)
            }
        }
    }

    private func quickDurationButton(_ mins: Int, binding: Binding<Int>) -> some View {
        Button {
            HapticManager.selection()
            binding.wrappedValue = mins
        } label: {
            Text("\(mins)")
                .font(.system(size: 13, weight: .bold).width(.condensed))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    binding.wrappedValue == mins
                        ? ColorTheme.training.opacity(0.15)
                        : ColorTheme.elevatedBackground(colorScheme)
                )
                .foregroundColor(
                    binding.wrappedValue == mins
                        ? ColorTheme.training
                        : ColorTheme.secondaryText(colorScheme)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.selection()
            action()
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .bold).width(.condensed))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    isSelected
                        ? ColorTheme.training.opacity(0.15)
                        : ColorTheme.elevatedBackground(colorScheme)
                )
                .foregroundColor(
                    isSelected
                        ? ColorTheme.training
                        : ColorTheme.secondaryText(colorScheme)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            isSelected ? ColorTheme.training.opacity(0.4) : .clear,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func sectionCard<Content: View>(
        title: String, icon: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ColorTheme.training)
                Text(title)
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }

    private func save() {
        let data = TrainingData(sessions: sessions, sport: userSport)
        onSave(data)
        dismiss()
    }
}

// MARK: - Session Editor (Sheet for adding/editing one session)

struct SessionEditorView: View {
    let sport: String
    let existingSession: TrainingSession?
    let onSave: (TrainingSession) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var editor = SessionEditorState()

    private let trainingTypes: [(String, String, String)] = [
        ("match", "Match", "trophy.fill"),
        ("gym", "Gym", "dumbbell.fill"),
        ("cardio", "Cardio", "heart.circle.fill"),
        ("technical", "Technical", "figure.run"),
        ("tactical", "Tactical", "brain.head.profile"),
        ("recovery", "Recovery", "leaf.fill"),
    ]

    private var canSave: Bool { !editor.trainingType.isEmpty }

    init(sport: String, existingSession: TrainingSession?, onSave: @escaping (TrainingSession) -> Void) {
        self.sport = sport
        self.existingSession = existingSession
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Training Type
                    sheetSectionCard(title: "TYPE", icon: "figure.run") {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                        ], spacing: 10) {
                            ForEach(trainingTypes, id: \.0) { type, label, icon in
                                Button {
                                    HapticManager.selection()
                                    if editor.trainingType != type {
                                        let oldType = editor.trainingType
                                        editor.trainingType = type
                                        if oldType != type {
                                            // Reset type-specific fields when switching
                                            editor.details = []
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: icon)
                                            .font(.system(size: 14, weight: .semibold))
                                        Text(label)
                                            .font(.system(size: 14, weight: .semibold).width(.condensed))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        editor.trainingType == type
                                            ? AnyShapeStyle(ColorTheme.training.opacity(0.15))
                                            : AnyShapeStyle(ColorTheme.elevatedBackground(colorScheme))
                                    )
                                    .foregroundColor(
                                        editor.trainingType == type
                                            ? ColorTheme.training
                                            : ColorTheme.secondaryText(colorScheme)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(
                                                editor.trainingType == type ? ColorTheme.training.opacity(0.4) : .clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Type-specific form
                    if !editor.trainingType.isEmpty {
                        SheetFormContent(editor: editor, sport: sport, colorScheme: colorScheme)
                    }

                    // Save Button
                    if canSave {
                        Button {
                            HapticManager.impact(.medium)
                            let session = editor.toSession()
                            onSave(session)
                            dismiss()
                        } label: {
                            Text(existingSession != nil ? "UPDATE SESSION" : "ADD SESSION")
                                .font(.system(size: 15, weight: .heavy).width(.condensed))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(ColorTheme.trainingGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: ColorTheme.training.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(existingSession != nil ? "Edit Session" : "New Session")
                        .font(.system(size: 17, weight: .bold).width(.condensed))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 30, height: 30)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
            }
            .onAppear {
                editor.reset()
                if let s = existingSession {
                    editor.load(from: s)
                }
            }
        }
    }

    private func sheetSectionCard<Content: View>(
        title: String, icon: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ColorTheme.training)
                Text(title)
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Sheet Form Content (reusable type-specific forms for sheet editor)

private struct SheetFormContent: View {
    let editor: SessionEditorState
    let sport: String
    let colorScheme: ColorScheme

    var body: some View {
        switch editor.trainingType {
        case "match":
            SheetMatchForm(editor: editor, sport: sport, colorScheme: colorScheme)
        case "gym":
            SheetGymForm(editor: editor, colorScheme: colorScheme)
        case "cardio":
            SheetCardioForm(editor: editor, colorScheme: colorScheme)
        case "technical":
            SheetTechnicalForm(editor: editor, sport: sport, colorScheme: colorScheme)
        case "tactical":
            SheetTacticalForm(editor: editor, colorScheme: colorScheme)
        case "recovery":
            SheetRecoveryForm(editor: editor, colorScheme: colorScheme)
        default:
            EmptyView()
        }

        // Notes for all types
        SheetNotesSection(editor: editor, colorScheme: colorScheme)
    }
}

// MARK: - Sheet Sub-forms

private struct SheetMatchForm: View {
    let editor: SessionEditorState
    let sport: String
    let colorScheme: ColorScheme

    var body: some View {
        SheetSection(title: "MATCH TYPE", icon: "trophy.fill", colorScheme: colorScheme) {
            SheetChipRow(options: [("match", "Match"), ("sparring", "Sparring"), ("competition", "Competition")],
                         selection: Binding(get: { editor.matchType }, set: { editor.matchType = $0 }),
                         colorScheme: colorScheme)
        }

        SheetSection(title: "RESULT", icon: "flag.fill", colorScheme: colorScheme) {
            HStack(spacing: 8) {
                ForEach([("win", "Win", "22C55E"), ("loss", "Loss", "EF4444"), ("draw", "Draw", "F59E0B")], id: \.0) { value, label, hex in
                    Button {
                        HapticManager.selection()
                        editor.result = value
                    } label: {
                        Text(label)
                            .font(.system(size: 14, weight: .bold).width(.condensed))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(editor.result == value ? Color(hex: hex).opacity(0.15) : ColorTheme.elevatedBackground(colorScheme))
                            .foregroundColor(editor.result == value ? Color(hex: hex) : ColorTheme.secondaryText(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(editor.result == value ? Color(hex: hex).opacity(0.4) : .clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        SheetSection(title: "PERFORMANCE RATING", icon: "star.fill", colorScheme: colorScheme) {
            VStack(spacing: 12) {
                HStack {
                    ForEach(1...10, id: \.self) { i in
                        Button {
                            HapticManager.selection()
                            editor.performanceRating = i
                        } label: {
                            Image(systemName: i <= editor.performanceRating ? "star.fill" : "star")
                                .font(.system(size: 18))
                                .foregroundColor(i <= editor.performanceRating ? Color(hex: "F59E0B") : ColorTheme.tertiaryText(colorScheme))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text("\(editor.performanceRating)/10")
                    .font(.system(size: 14, weight: .bold).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
            }
        }

        SheetDurationSection(value: Binding(get: { editor.minutesPlayed }, set: { editor.minutesPlayed = $0 }),
                             title: "MINUTES PLAYED", presets: [45, 60, 70, 80, 90], range: 1...120, colorScheme: colorScheme)
    }
}

private struct SheetGymForm: View {
    let editor: SessionEditorState
    let colorScheme: ColorScheme

    var body: some View {
        SheetSection(title: "FOCUS", icon: "dumbbell.fill", colorScheme: colorScheme) {
            SheetChipRow(options: [("strength", "Strength"), ("hypertrophy", "Hypertrophy"), ("power", "Power"), ("conditioning", "Conditioning")],
                         selection: Binding(get: { editor.gymFocus }, set: { editor.gymFocus = $0 }),
                         colorScheme: colorScheme)
        }

        SheetDurationSection(value: Binding(get: { editor.duration }, set: { editor.duration = $0 }),
                             colorScheme: colorScheme)

        SheetSection(title: "EFFORT LEVEL", icon: "flame.fill", colorScheme: colorScheme) {
            SheetChipRow(options: [("easy", "Easy"), ("moderate", "Moderate"), ("hard", "Hard"), ("failure", "Failure")],
                         selection: Binding(get: { editor.effortLevel }, set: { editor.effortLevel = $0 }),
                         colorScheme: colorScheme)
        }
    }
}

private struct SheetCardioForm: View {
    let editor: SessionEditorState
    let colorScheme: ColorScheme

    var body: some View {
        SheetSection(title: "TYPE", icon: "heart.circle.fill", colorScheme: colorScheme) {
            SheetChipRow(options: [("run", "Run"), ("bike", "Bike"), ("swim", "Swim")],
                         selection: Binding(get: { editor.cardioType }, set: { editor.cardioType = $0 }),
                         colorScheme: colorScheme)
        }

        SheetSection(title: "DISTANCE (KM)", icon: "map.fill", colorScheme: colorScheme) {
            VStack(spacing: 12) {
                Text(String(format: "%.1f km", editor.distance))
                    .font(Typography.number(32))
                    .foregroundColor(ColorTheme.training)

                Slider(value: Binding(get: { editor.distance }, set: { editor.distance = $0 }), in: 0...50, step: 0.5)
                    .tint(ColorTheme.training)
            }
        }

        SheetDurationSection(value: Binding(get: { editor.duration }, set: { editor.duration = $0 }),
                             title: "TIME", presets: [15, 20, 30, 45, 60], colorScheme: colorScheme)

        SheetSection(title: "EFFORT", icon: "flame.fill", colorScheme: colorScheme) {
            SheetChipRow(options: [("light", "Light"), ("moderate", "Moderate"), ("hard", "Hard")],
                         selection: Binding(get: { editor.cardioEffort }, set: { editor.cardioEffort = $0 }),
                         colorScheme: colorScheme)
        }
    }
}

private struct SheetTechnicalForm: View {
    let editor: SessionEditorState
    let sport: String
    let colorScheme: ColorScheme

    var body: some View {
        SheetSection(title: "SKILL TRAINED", icon: "target", colorScheme: colorScheme) {
            VStack(spacing: 10) {
                let skills = TrainingSession.technicalDetails(sport: sport)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(skills, id: \.self) { skill in
                        Button {
                            HapticManager.selection()
                            editor.skillTrained = editor.skillTrained == skill ? "" : skill
                        } label: {
                            Text(skill)
                                .font(.system(size: 12, weight: .bold).width(.condensed))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(editor.skillTrained == skill ? ColorTheme.training.opacity(0.15) : ColorTheme.elevatedBackground(colorScheme))
                                .foregroundColor(editor.skillTrained == skill ? ColorTheme.training : ColorTheme.secondaryText(colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                TextField("Or type your own...", text: Binding(get: { editor.skillTrained }, set: { editor.skillTrained = $0 }))
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(ColorTheme.elevatedBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }

        SheetDurationSection(value: Binding(get: { editor.duration }, set: { editor.duration = $0 }),
                             colorScheme: colorScheme)

        SheetSection(title: "FOCUS QUALITY", icon: "eye.fill", colorScheme: colorScheme) {
            SheetChipRow(options: [("poor", "Poor"), ("average", "Average"), ("good", "Good"), ("elite", "Elite")],
                         selection: Binding(get: { editor.focusQuality }, set: { editor.focusQuality = $0 }),
                         colorScheme: colorScheme)
        }
    }
}

private struct SheetTacticalForm: View {
    let editor: SessionEditorState
    let colorScheme: ColorScheme

    var body: some View {
        SheetSection(title: "SESSION TYPE", icon: "brain.head.profile", colorScheme: colorScheme) {
            SheetChipRow(options: [("team_session", "Team Session"), ("analysis", "Analysis")],
                         selection: Binding(get: { editor.tacticalType }, set: { editor.tacticalType = $0 }),
                         colorScheme: colorScheme)
        }

        SheetDurationSection(value: Binding(get: { editor.duration }, set: { editor.duration = $0 }),
                             colorScheme: colorScheme)

        SheetSection(title: "UNDERSTANDING LEVEL", icon: "brain", colorScheme: colorScheme) {
            SheetChipRow(options: [("low", "Low"), ("medium", "Medium"), ("high", "High")],
                         selection: Binding(get: { editor.understandingLevel }, set: { editor.understandingLevel = $0 }),
                         colorScheme: colorScheme)
        }
    }
}

private struct SheetRecoveryForm: View {
    let editor: SessionEditorState
    let colorScheme: ColorScheme

    var body: some View {
        SheetSection(title: "RECOVERY TYPE", icon: "leaf.fill", colorScheme: colorScheme) {
            SheetChipRow(options: [("stretching", "Stretching"), ("ice_bath", "Ice Bath"), ("massage", "Massage"), ("rest", "Rest")],
                         selection: Binding(get: { editor.recoveryType }, set: { editor.recoveryType = $0 }),
                         colorScheme: colorScheme)
        }

        SheetDurationSection(value: Binding(get: { editor.duration }, set: { editor.duration = $0 }),
                             title: "DURATION (OPTIONAL)", presets: [10, 15, 20, 30, 60], range: 5...120, colorScheme: colorScheme)
    }
}

private struct SheetNotesSection: View {
    let editor: SessionEditorState
    let colorScheme: ColorScheme

    var body: some View {
        SheetSection(title: "NOTES (OPTIONAL)", icon: "note.text", colorScheme: colorScheme) {
            TextField("How was this session?", text: Binding(get: { editor.notes }, set: { editor.notes = $0 }), axis: .vertical)
                .font(.system(size: 15, weight: .regular).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))
                .lineLimit(3...6)
                .padding(12)
                .background(ColorTheme.elevatedBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

// MARK: - Shared Sheet Components

private struct SheetSection<Content: View>: View {
    let title: String
    let icon: String
    let colorScheme: ColorScheme
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ColorTheme.training)
                Text(title)
                    .font(.system(size: 11, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 6, x: 0, y: 2)
    }
}

private struct SheetChipRow: View {
    let options: [(String, String)]
    @Binding var selection: String
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.0) { value, label in
                Button {
                    HapticManager.selection()
                    selection = value
                } label: {
                    Text(label)
                        .font(.system(size: 12, weight: .bold).width(.condensed))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selection == value
                                ? ColorTheme.training.opacity(0.15)
                                : ColorTheme.elevatedBackground(colorScheme)
                        )
                        .foregroundColor(
                            selection == value
                                ? ColorTheme.training
                                : ColorTheme.secondaryText(colorScheme)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(
                                    selection == value ? ColorTheme.training.opacity(0.4) : .clear,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SheetDurationSection: View {
    @Binding var value: Int
    var title: String = "DURATION"
    var presets: [Int] = [30, 45, 60, 90, 120]
    var range: ClosedRange<Double> = 10...180
    let colorScheme: ColorScheme

    var body: some View {
        SheetSection(title: title, icon: "clock.fill", colorScheme: colorScheme) {
            VStack(spacing: 12) {
                Text("\(value) min")
                    .font(Typography.number(32))
                    .foregroundColor(ColorTheme.training)

                HStack(spacing: 10) {
                    ForEach(presets, id: \.self) { mins in
                        Button {
                            HapticManager.selection()
                            value = mins
                        } label: {
                            Text("\(mins)")
                                .font(.system(size: 13, weight: .bold).width(.condensed))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    value == mins
                                        ? ColorTheme.training.opacity(0.15)
                                        : ColorTheme.elevatedBackground(colorScheme)
                                )
                                .foregroundColor(
                                    value == mins
                                        ? ColorTheme.training
                                        : ColorTheme.secondaryText(colorScheme)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Slider(value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ), in: range, step: 5)
                .tint(ColorTheme.training)
            }
        }
    }
}

// MARK: - Stat Input Row

private struct StatInputRow: View {
    let label: String
    let icon: String
    @Binding var value: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ColorTheme.accent)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 15, weight: .semibold).width(.condensed))
                .foregroundColor(ColorTheme.primaryText(colorScheme))

            Spacer()

            HStack(spacing: 0) {
                Button {
                    if value > 0 { value -= 1 }
                    HapticManager.impact(.light)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(value > 0 ? ColorTheme.primaryText(colorScheme) : ColorTheme.tertiaryText(colorScheme))
                        .frame(width: 36, height: 36)
                        .background(ColorTheme.elevatedBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Text("\(value)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .frame(width: 44)
                    .contentTransition(.numericText())

                Button {
                    value += 1
                    HapticManager.impact(.light)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(ColorTheme.primaryText(colorScheme))
                        .frame(width: 36, height: 36)
                        .background(ColorTheme.elevatedBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(ColorTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: ColorTheme.cardShadow(colorScheme), radius: 4, x: 0, y: 1)
    }
}

// FlowLayout is defined in MultiSelectChip.swift
// LogCardButtonStyle is defined in HomeView.swift

import SwiftUI

// MARK: - Session Editor State

@Observable
final class SessionEditorState {
    var trainingType = ""
    var duration = 60
    var intensity = "medium"
    var details: Set<String> = []
    var notes = ""

    func toSession() -> TrainingSession {
        TrainingSession(
            trainingType: trainingType,
            duration: duration,
            intensity: intensity,
            details: Array(details),
            notes: notes.isEmpty ? nil : notes
        )
    }

    func load(from session: TrainingSession) {
        trainingType = session.trainingType
        duration = session.duration
        intensity = session.intensity
        details = Set(session.details)
        notes = session.notes ?? ""
    }

    func reset() {
        trainingType = ""
        duration = 60
        intensity = "medium"
        details = []
        notes = ""
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

    /// Whether the user picked a type from the empty state and is now filling in details inline
    private var isInlineEditing: Bool {
        sessions.isEmpty && !inlineEditor.trainingType.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if sessions.isEmpty && inlineEditor.trainingType.isEmpty {
                        // No sessions, no type chosen yet — show type picker
                        emptyState
                    } else if isInlineEditing {
                        // User picked a type — show inline editor (no sheet)
                        inlineEditorView
                    } else {
                        // Existing sessions
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

                        // Total summary
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
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
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

    // MARK: - Session Card

    private func sessionCard(_ session: TrainingSession, index: Int) -> some View {
        Button {
            HapticManager.selection()
            editingSessionIndex = index
            showAddSession = true
        } label: {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    // Type icon
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

                        HStack(spacing: 8) {
                            Label("\(session.duration)min", systemImage: "clock")
                            Label(session.intensityDisplay, systemImage: "bolt.fill")
                        }
                        .font(.system(size: 11, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    }

                    Spacer()

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
                            withAnimation(.easeInOut(duration: 0.25)) {
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

                // Detail chips
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

            let allDetails = sessions.flatMap { $0.details }
            summaryItem(
                value: "\(Set(allDetails).count)",
                label: "Areas",
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
                Text("Add your sessions for today.\nYou can log multiple training types.")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            // Quick-add training type buttons
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

    // MARK: - Inline Editor (first session, no sheet)

    private var inlineDetailOptions: [String] {
        TrainingSession.detailOptions(for: inlineEditor.trainingType, sport: userSport)
    }

    private var inlineEditorView: some View {
        VStack(spacing: 16) {
            // Selected type header with change button
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

            // Detail options
            if !inlineDetailOptions.isEmpty {
                inlineSectionCard(title: inlineDetailSectionTitle, icon: inlineDetailSectionIcon) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                    ], spacing: 8) {
                        ForEach(inlineDetailOptions, id: \.self) { option in
                            Button {
                                HapticManager.selection()
                                if inlineEditor.details.contains(option) {
                                    inlineEditor.details.remove(option)
                                } else {
                                    inlineEditor.details.insert(option)
                                }
                            } label: {
                                Text(option)
                                    .font(.system(size: 12, weight: .semibold).width(.condensed))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        inlineEditor.details.contains(option)
                                            ? ColorTheme.training.opacity(0.15)
                                            : ColorTheme.elevatedBackground(colorScheme)
                                    )
                                    .foregroundColor(
                                        inlineEditor.details.contains(option)
                                            ? ColorTheme.training
                                            : ColorTheme.secondaryText(colorScheme)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(
                                                inlineEditor.details.contains(option) ? ColorTheme.training.opacity(0.4) : .clear,
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Duration
            inlineSectionCard(title: "DURATION", icon: "clock.fill") {
                VStack(spacing: 12) {
                    Text("\(inlineEditor.duration) min")
                        .font(Typography.number(32))
                        .foregroundColor(ColorTheme.training)

                    HStack(spacing: 10) {
                        ForEach([30, 45, 60, 90, 120], id: \.self) { mins in
                            Button {
                                HapticManager.selection()
                                inlineEditor.duration = mins
                            } label: {
                                Text("\(mins)")
                                    .font(.system(size: 13, weight: .bold).width(.condensed))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        inlineEditor.duration == mins
                                            ? ColorTheme.training.opacity(0.15)
                                            : ColorTheme.elevatedBackground(colorScheme)
                                    )
                                    .foregroundColor(
                                        inlineEditor.duration == mins
                                            ? ColorTheme.training
                                            : ColorTheme.secondaryText(colorScheme)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Slider(value: Binding(
                        get: { Double(inlineEditor.duration) },
                        set: { inlineEditor.duration = Int($0) }
                    ), in: 10...180, step: 5)
                    .tint(ColorTheme.training)
                }
            }

            // Intensity
            inlineSectionCard(title: "INTENSITY", icon: "bolt.fill") {
                HStack(spacing: 8) {
                    ForEach([("low", "Low"), ("medium", "Medium"), ("high", "High"), ("max", "Maximum")], id: \.0) { value, label in
                        Button {
                            HapticManager.selection()
                            inlineEditor.intensity = value
                        } label: {
                            Text(label)
                                .font(.system(size: 13, weight: .bold).width(.condensed))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    inlineEditor.intensity == value
                                        ? ColorTheme.training.opacity(0.15)
                                        : ColorTheme.elevatedBackground(colorScheme)
                                )
                                .foregroundColor(
                                    inlineEditor.intensity == value
                                        ? ColorTheme.training
                                        : ColorTheme.secondaryText(colorScheme)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(
                                            inlineEditor.intensity == value ? ColorTheme.training.opacity(0.4) : .clear,
                                            lineWidth: 1.5
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Notes
            inlineSectionCard(title: "NOTES (OPTIONAL)", icon: "note.text") {
                TextField("How was this session?", text: $inlineEditor.notes, axis: .vertical)
                    .font(.system(size: 15, weight: .regular).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                    .lineLimit(3...6)
                    .padding(12)
                    .background(ColorTheme.elevatedBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Save session button — adds to list so user can review or add more
            Button {
                HapticManager.impact(.medium)
                let session = inlineEditor.toSession()
                withAnimation(.easeInOut(duration: 0.25)) {
                    sessions.append(session)
                    inlineEditor.reset()
                }
            } label: {
                Text("SAVE SESSION")
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

    private var inlineDetailSectionTitle: String {
        switch inlineEditor.trainingType {
        case "match": return "MATCH DETAILS"
        case "gym": return "MUSCLE GROUPS"
        case "cardio": return "CARDIO TYPE"
        case "technical": return "SKILLS WORKED ON"
        case "tactical": return "TACTICAL FOCUS"
        case "recovery": return "RECOVERY METHODS"
        case "other": return "ACTIVITY DETAILS"
        default: return "DETAILS"
        }
    }

    private var inlineDetailSectionIcon: String {
        switch inlineEditor.trainingType {
        case "match": return "trophy.fill"
        case "gym": return "dumbbell.fill"
        case "cardio": return "heart.circle.fill"
        case "technical": return "target"
        case "tactical": return "brain.head.profile"
        case "recovery": return "leaf.fill"
        case "other": return "ellipsis.circle.fill"
        default: return "list.bullet"
        }
    }

    private func inlineSectionCard<Content: View>(
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
        ("other", "Other", "ellipsis.circle.fill"),
    ]

    private let intensities = [
        ("low", "Low"),
        ("medium", "Medium"),
        ("high", "High"),
        ("max", "Maximum"),
    ]

    private var detailOptions: [String] {
        TrainingSession.detailOptions(for: editor.trainingType, sport: sport)
    }

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
                    sectionCard(title: "TYPE", icon: "figure.run") {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                        ], spacing: 10) {
                            ForEach(trainingTypes, id: \.0) { type, label, icon in
                                Button {
                                    HapticManager.selection()
                                    if editor.trainingType != type {
                                        editor.details = []
                                    }
                                    editor.trainingType = type
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

                    // Type-specific details
                    if !editor.trainingType.isEmpty && !detailOptions.isEmpty {
                        sectionCard(title: detailSectionTitle, icon: detailSectionIcon) {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8),
                            ], spacing: 8) {
                                ForEach(detailOptions, id: \.self) { option in
                                    Button {
                                        HapticManager.selection()
                                        if editor.details.contains(option) {
                                            editor.details.remove(option)
                                        } else {
                                            editor.details.insert(option)
                                        }
                                    } label: {
                                        Text(option)
                                            .font(.system(size: 12, weight: .semibold).width(.condensed))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 9)
                                            .background(
                                                editor.details.contains(option)
                                                    ? ColorTheme.training.opacity(0.15)
                                                    : ColorTheme.elevatedBackground(colorScheme)
                                            )
                                            .foregroundColor(
                                                editor.details.contains(option)
                                                    ? ColorTheme.training
                                                    : ColorTheme.secondaryText(colorScheme)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .strokeBorder(
                                                        editor.details.contains(option) ? ColorTheme.training.opacity(0.4) : .clear,
                                                        lineWidth: 1
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Duration
                    if !editor.trainingType.isEmpty {
                        sectionCard(title: "DURATION", icon: "clock.fill") {
                            VStack(spacing: 12) {
                                Text("\(editor.duration) min")
                                    .font(Typography.number(32))
                                    .foregroundColor(ColorTheme.training)

                                HStack(spacing: 10) {
                                    ForEach([30, 45, 60, 90, 120], id: \.self) { mins in
                                        Button {
                                            HapticManager.selection()
                                            editor.duration = mins
                                        } label: {
                                            Text("\(mins)")
                                                .font(.system(size: 13, weight: .bold).width(.condensed))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(
                                                    editor.duration == mins
                                                        ? ColorTheme.training.opacity(0.15)
                                                        : ColorTheme.elevatedBackground(colorScheme)
                                                )
                                                .foregroundColor(
                                                    editor.duration == mins
                                                        ? ColorTheme.training
                                                        : ColorTheme.secondaryText(colorScheme)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                Slider(value: Binding(
                                    get: { Double(editor.duration) },
                                    set: { editor.duration = Int($0) }
                                ), in: 10...180, step: 5)
                                .tint(ColorTheme.training)
                            }
                        }

                        // Intensity
                        sectionCard(title: "INTENSITY", icon: "bolt.fill") {
                            HStack(spacing: 8) {
                                ForEach(intensities, id: \.0) { value, label in
                                    Button {
                                        HapticManager.selection()
                                        editor.intensity = value
                                    } label: {
                                        Text(label)
                                            .font(.system(size: 13, weight: .bold).width(.condensed))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                editor.intensity == value
                                                    ? ColorTheme.training.opacity(0.15)
                                                    : ColorTheme.elevatedBackground(colorScheme)
                                            )
                                            .foregroundColor(
                                                editor.intensity == value
                                                    ? ColorTheme.training
                                                    : ColorTheme.secondaryText(colorScheme)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .strokeBorder(
                                                        editor.intensity == value ? ColorTheme.training.opacity(0.4) : .clear,
                                                        lineWidth: 1.5
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Notes
                        sectionCard(title: "NOTES (OPTIONAL)", icon: "note.text") {
                            TextField("How was this session?", text: $editor.notes, axis: .vertical)
                                .font(.system(size: 15, weight: .regular).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                                .lineLimit(3...6)
                                .padding(12)
                                .background(ColorTheme.elevatedBackground(colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }

                    // Save Session Button
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
                            .background(
                                canSave
                                    ? AnyShapeStyle(ColorTheme.trainingGradient)
                                    : AnyShapeStyle(ColorTheme.training.opacity(0.4))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: ColorTheme.training.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!canSave)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
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

    // MARK: - Dynamic section titles based on type

    private var detailSectionTitle: String {
        switch editor.trainingType {
        case "match": return "MATCH DETAILS"
        case "gym": return "MUSCLE GROUPS"
        case "cardio": return "CARDIO TYPE"
        case "technical": return "SKILLS WORKED ON"
        case "tactical": return "TACTICAL FOCUS"
        case "recovery": return "RECOVERY METHODS"
        case "other": return "ACTIVITY DETAILS"
        default: return "DETAILS"
        }
    }

    private var detailSectionIcon: String {
        switch editor.trainingType {
        case "match": return "trophy.fill"
        case "gym": return "dumbbell.fill"
        case "cardio": return "heart.circle.fill"
        case "technical": return "target"
        case "tactical": return "brain.head.profile"
        case "recovery": return "leaf.fill"
        case "other": return "ellipsis.circle.fill"
        default: return "list.bullet"
        }
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
}

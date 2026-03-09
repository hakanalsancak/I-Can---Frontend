import SwiftUI

enum EntryStep: Hashable {
    case activityType
    case singleChoice(id: String)
    case multiSelect(id: String)
    case reflections
    case optionalQuestion
    case submitting
}

@Observable
final class DailyEntryViewModel {
    var currentStepIndex = 0
    var activityType: String = ""

    var focusLabel: String = ""
    var effortLabel: String = ""
    var workedOn: Set<String> = []

    var preGameFeeling: String = ""
    var overallPerformance: String = ""
    var strongestAreas: Set<String> = []

    var recoveryQuality: String = ""
    var restActivities: Set<String> = []
    var disciplineLevel: String = ""
    var recoveryReflection: String = ""

    var didWell: String = ""
    var improveNext: String = ""

    var rotatingAnswer: String = ""

    var isSubmitting = false
    var errorMessage: String?
    var submittedResponse: EntrySubmitResponse?
    var coachInsight: String = ""
    var isLoadingInsight = false

    var steps: [EntryStep] {
        var s: [EntryStep] = [.activityType]
        switch activityType {
        case "training":
            s += [
                .singleChoice(id: "focus"),
                .singleChoice(id: "effort"),
                .multiSelect(id: "workedOn"),
                .reflections,
                .optionalQuestion,
            ]
        case "game":
            s += [
                .singleChoice(id: "preGame"),
                .singleChoice(id: "performance"),
                .multiSelect(id: "strongest"),
                .reflections,
            ]
        case "rest_day":
            s += [
                .singleChoice(id: "recovery"),
                .multiSelect(id: "restActivities"),
                .singleChoice(id: "discipline"),
                .reflections,
            ]
        default:
            break
        }
        s.append(.submitting)
        return s
    }

    var currentStep: EntryStep {
        let s = steps
        guard currentStepIndex < s.count else { return .submitting }
        return s[currentStepIndex]
    }

    var totalSteps: Int { steps.count }

    var progress: Double {
        guard totalSteps > 1 else { return 0 }
        return Double(currentStepIndex) / Double(totalSteps - 1)
    }

    // MARK: - Numeric mappings

    private var focusRating: Int {
        switch activityType {
        case "training":
            return Self.focusMap[focusLabel] ?? 5
        case "game":
            return Self.performanceMap[overallPerformance] ?? 5
        case "rest_day":
            return Self.recoveryMap[recoveryQuality] ?? 5
        default: return 5
        }
    }

    private var effortRating: Int {
        switch activityType {
        case "training":
            return Self.effortMap[effortLabel] ?? 5
        case "game":
            return Self.performanceMap[overallPerformance] ?? 5
        case "rest_day":
            return Self.disciplineMap[disciplineLevel] ?? 5
        default: return 5
        }
    }

    private var confidenceRating: Int {
        switch activityType {
        case "training":
            return Int(round(Double(focusRating + effortRating) / 2.0))
        case "game":
            return Self.preGameMap[preGameFeeling] ?? 5
        case "rest_day":
            return Int(round(Double(focusRating + effortRating) / 2.0))
        default: return 5
        }
    }

    static let focusMap: [String: Int] = [
        "Very focused": 9, "Mostly focused": 7,
        "Distracted at times": 4, "Hard to focus": 2,
    ]
    static let effortMap: [String: Int] = [
        "Maximum effort": 10, "Good effort": 7,
        "Average effort": 5, "Low effort": 2,
    ]
    static let preGameMap: [String: Int] = [
        "Confident": 9, "Ready": 7, "Nervous": 4, "Unprepared": 2,
    ]
    static let performanceMap: [String: Int] = [
        "Excellent": 9, "Good": 7, "Average": 5, "Poor": 2,
    ]
    static let recoveryMap: [String: Int] = [
        "Excellent": 9, "Good": 7, "Average": 5, "Poor": 2,
    ]
    static let disciplineMap: [String: Int] = [
        "Yes": 9, "Mostly": 6, "Not really": 3,
    ]

    // MARK: - Navigation

    func nextStep() {
        guard currentStepIndex < steps.count - 1 else { return }
        currentStepIndex += 1
    }

    func previousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }

    // MARK: - Init from existing entry

    init(existingEntry: DailyEntry? = nil) {
        guard let entry = existingEntry else { return }
        self.activityType = entry.activityType
        self.didWell = entry.didWell ?? ""
        self.improveNext = entry.improveNext ?? ""

        if let r = entry.responses {
            self.focusLabel = r.focusLabel ?? ""
            self.effortLabel = r.effortLabel ?? ""
            self.workedOn = Set(r.workedOn ?? [])
            self.preGameFeeling = r.preGameFeeling ?? ""
            self.overallPerformance = r.overallPerformance ?? ""
            self.strongestAreas = Set(r.strongestAreas ?? [])
            self.recoveryQuality = r.recoveryQuality ?? ""
            self.restActivities = Set(r.restActivities ?? [])
            self.disciplineLevel = r.discipline ?? ""
            self.recoveryReflection = r.recoveryReflection ?? ""
            self.rotatingAnswer = r.rotatingA ?? ""
        }
    }

    // MARK: - Submit

    func submit() async -> EntrySubmitResponse? {
        isSubmitting = true
        errorMessage = nil

        var responses = EntryResponses()
        switch activityType {
        case "training":
            responses.focusLabel = focusLabel
            responses.effortLabel = effortLabel
            responses.workedOn = Array(workedOn)
            if !rotatingAnswer.isEmpty {
                responses.rotatingQ = "Did you follow your training plan today?"
                responses.rotatingA = rotatingAnswer
            }
        case "game":
            responses.preGameFeeling = preGameFeeling
            responses.overallPerformance = overallPerformance
            responses.strongestAreas = Array(strongestAreas)
        case "rest_day":
            responses.recoveryQuality = recoveryQuality
            responses.restActivities = Array(restActivities)
            responses.discipline = disciplineLevel
            if !recoveryReflection.isEmpty {
                responses.recoveryReflection = recoveryReflection
            }
        default: break
        }

        let request = EntrySubmitRequest(
            entryDate: Date().apiDateString,
            activityType: activityType,
            focusRating: focusRating,
            effortRating: effortRating,
            confidenceRating: confidenceRating,
            didWell: didWell.isEmpty ? nil : didWell,
            improveNext: improveNext.isEmpty ? nil : improveNext,
            rotatingQuestionId: nil,
            rotatingAnswer: nil,
            responses: responses
        )

        do {
            let response = try await EntryService.shared.submitEntry(request)
            submittedResponse = response
            isSubmitting = false
            return response
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return nil
        }
    }

    func fetchInsight() async {
        guard SubscriptionService.shared.isPremium else { return }
        isLoadingInsight = true
        let displayType: String
        switch activityType {
        case "training": displayType = "Training"
        case "game": displayType = "Game"
        case "rest_day": displayType = "Rest Day"
        default: displayType = activityType.capitalized
        }
        var request = InsightRequest(activityType: displayType)

        switch activityType {
        case "training":
            request.focus = focusLabel
            request.effort = effortLabel
            request.trainingAreas = Array(workedOn)
            request.reflectionPositive = didWell.isEmpty ? nil : didWell
            request.reflectionImprove = improveNext.isEmpty ? nil : improveNext
            if !rotatingAnswer.isEmpty {
                request.dailyQuestion = "Did you follow your training plan today?"
                request.dailyAnswer = rotatingAnswer
            }
        case "game":
            request.preGameFeeling = preGameFeeling
            request.overallPerformance = overallPerformance
            request.strongestAreas = Array(strongestAreas)
            request.reflectionPositive = didWell.isEmpty ? nil : didWell
            request.reflectionImprove = improveNext.isEmpty ? nil : improveNext
        case "rest_day":
            request.recoveryQuality = recoveryQuality
            request.restActivities = Array(restActivities)
            request.discipline = disciplineLevel
            request.recoveryReflection = recoveryReflection.isEmpty ? nil : recoveryReflection
        default: break
        }

        do {
            let insight = try await EntryService.shared.generateInsight(request)
            if !insight.isEmpty {
                coachInsight = insight
            }
        } catch {}
        isLoadingInsight = false
    }
}

// MARK: - Flow View

struct DailyEntryFlowView: View {
    @State private var viewModel: DailyEntryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let onComplete: (EntrySubmitResponse) -> Void

    init(existingEntry: DailyEntry? = nil, onComplete: @escaping (EntrySubmitResponse) -> Void) {
        self._viewModel = State(initialValue: DailyEntryViewModel(existingEntry: existingEntry))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background(colorScheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.currentStep != .submitting {
                        progressBar
                            .padding(.top, 8)
                    }

                    currentStepView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStepIndex)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(width: 32, height: 32)
                            .background(ColorTheme.elevatedBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.currentStep {
        case .activityType:
            ActivityTypeView(
                selectedType: $viewModel.activityType,
                onNext: {
                    viewModel.currentStepIndex = 1
                }
            )

        case .singleChoice(let id):
            singleChoiceView(for: id)

        case .multiSelect(let id):
            multiSelectView(for: id)

        case .reflections:
            if viewModel.activityType == "rest_day" {
                RestReflectionStepView(
                    recoveryReflection: $viewModel.recoveryReflection,
                    onNext: { submitEntry() },
                    onBack: { viewModel.previousStep() },
                    isSubmitting: viewModel.isSubmitting,
                    errorMessage: viewModel.errorMessage
                )
            } else {
                ReflectionsView(
                    didWell: $viewModel.didWell,
                    improveNext: $viewModel.improveNext,
                    onNext: {
                        if viewModel.activityType == "training" {
                            viewModel.nextStep()
                        } else {
                            submitEntry()
                        }
                    },
                    onBack: { viewModel.previousStep() },
                    isSubmitStep: viewModel.activityType != "training",
                    isSubmitting: viewModel.isSubmitting,
                    errorMessage: viewModel.errorMessage
                )
            }

        case .optionalQuestion:
            OptionalQuestionStepView(
                answer: $viewModel.rotatingAnswer,
                onSubmit: { submitEntry() },
                onBack: { viewModel.previousStep() },
                isSubmitting: viewModel.isSubmitting,
                errorMessage: viewModel.errorMessage
            )

        case .submitting:
            if let response = viewModel.submittedResponse {
                EntrySubmittedView(
                    response: response,
                    coachInsight: viewModel.coachInsight,
                    isLoadingInsight: viewModel.isLoadingInsight,
                    onDone: {
                        onComplete(response)
                        dismiss()
                    }
                )
            } else {
                LoadingView(message: "Saving your entry...")
            }
        }
    }

    // MARK: - Single Choice Router

    @ViewBuilder
    private func singleChoiceView(for id: String) -> some View {
        switch id {
        case "focus":
            SingleChoiceStepView(
                question: "How was your focus during training?",
                subtitle: "Be honest with yourself",
                options: [
                    ChoiceOption("Very focused", icon: "scope", subtitle: "Locked in the entire session"),
                    ChoiceOption("Mostly focused", icon: "eye", subtitle: "Some moments of drift"),
                    ChoiceOption("Distracted at times", icon: "wind", subtitle: "Mind wandered often"),
                    ChoiceOption("Hard to focus", icon: "cloud.fog", subtitle: "Struggled to stay present"),
                ],
                selection: $viewModel.focusLabel,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        case "effort":
            SingleChoiceStepView(
                question: "How hard did you push yourself?",
                subtitle: "Rate your intensity",
                options: [
                    ChoiceOption("Maximum effort", icon: "flame.fill", subtitle: "Gave everything I had"),
                    ChoiceOption("Good effort", icon: "bolt.fill", subtitle: "Pushed hard, could give more"),
                    ChoiceOption("Average effort", icon: "minus.circle", subtitle: "Went through the motions"),
                    ChoiceOption("Low effort", icon: "battery.25percent", subtitle: "Didn't bring my best"),
                ],
                selection: $viewModel.effortLabel,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        case "preGame":
            SingleChoiceStepView(
                question: "How did you feel before the game?",
                subtitle: "Your pre-game mindset",
                options: [
                    ChoiceOption("Confident", icon: "star.fill", subtitle: "Ready to dominate"),
                    ChoiceOption("Ready", icon: "checkmark.shield", subtitle: "Prepared and steady"),
                    ChoiceOption("Nervous", icon: "heart.fill", subtitle: "Butterflies but pushing through"),
                    ChoiceOption("Unprepared", icon: "exclamationmark.triangle", subtitle: "Didn't feel ready"),
                ],
                selection: $viewModel.preGameFeeling,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        case "performance":
            SingleChoiceStepView(
                question: "How did you perform overall?",
                subtitle: "Your honest self-assessment",
                options: [
                    ChoiceOption("Excellent", icon: "crown.fill", subtitle: "One of my best performances"),
                    ChoiceOption("Good", icon: "hand.thumbsup.fill", subtitle: "Solid, happy with it"),
                    ChoiceOption("Average", icon: "equal.circle", subtitle: "Nothing special, nothing bad"),
                    ChoiceOption("Poor", icon: "arrow.down.circle", subtitle: "Below my standard"),
                ],
                selection: $viewModel.overallPerformance,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        case "recovery":
            SingleChoiceStepView(
                question: "How was your recovery today?",
                subtitle: "Rest is part of the process",
                options: [
                    ChoiceOption("Excellent", icon: "battery.100percent", subtitle: "Feeling fully recharged"),
                    ChoiceOption("Good", icon: "battery.75percent", subtitle: "Solid recovery day"),
                    ChoiceOption("Average", icon: "battery.50percent", subtitle: "Could have been better"),
                    ChoiceOption("Poor", icon: "battery.25percent", subtitle: "Didn't recover much"),
                ],
                selection: $viewModel.recoveryQuality,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        case "discipline":
            SingleChoiceStepView(
                question: "Did you stay disciplined with sleep, nutrition, and recovery?",
                subtitle: "Champions are built off the field",
                options: [
                    ChoiceOption("Yes", icon: "checkmark.seal.fill", subtitle: "Nailed it today"),
                    ChoiceOption("Mostly", icon: "hand.thumbsup", subtitle: "A few slips but mostly good"),
                    ChoiceOption("Not really", icon: "xmark.circle", subtitle: "Room for improvement"),
                ],
                selection: $viewModel.disciplineLevel,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        default:
            EmptyView()
        }
    }

    // MARK: - Sport Config

    private var userSport: String {
        AuthService.shared.currentUser?.sport ?? "soccer"
    }

    private func trainingItems(for sport: String) -> [(String, String)] {
        switch sport {
        case "soccer":
            return [
                ("Shooting", "scope"),
                ("Passing", "arrow.right.arrow.left"),
                ("Dribbling", "figure.run"),
                ("Defense", "shield.fill"),
                ("Set pieces", "sportscourt"),
                ("Conditioning", "flame.fill"),
            ]
        case "basketball":
            return [
                ("Shooting", "scope"),
                ("Defense", "shield.fill"),
                ("Ball handling", "hand.raised.fill"),
                ("Conditioning", "flame.fill"),
                ("Plays", "brain.head.profile"),
                ("Rebounding", "arrow.up.circle"),
            ]
        case "tennis":
            return [
                ("Serve", "arrow.up.forward"),
                ("Groundstrokes", "arrow.left.arrow.right"),
                ("Volleys", "hand.raised.fill"),
                ("Footwork", "figure.walk"),
                ("Strategy", "brain.head.profile"),
                ("Conditioning", "flame.fill"),
            ]
        case "football":
            return [
                ("Throwing", "arrow.up.forward"),
                ("Routes", "point.topleft.down.to.point.bottomright.curvepath"),
                ("Blocking", "shield.fill"),
                ("Tackling", "figure.american.football"),
                ("Conditioning", "flame.fill"),
                ("Film study", "play.rectangle"),
            ]
        case "boxing":
            return [
                ("Sparring", "figure.boxing"),
                ("Bag work", "circle.fill"),
                ("Footwork", "figure.walk"),
                ("Defense", "shield.fill"),
                ("Conditioning", "flame.fill"),
                ("Combinations", "bolt.fill"),
            ]
        case "cricket":
            return [
                ("Batting", "figure.cricket"),
                ("Bowling", "arrow.up.forward"),
                ("Fielding", "hand.raised.fill"),
                ("Fitness", "flame.fill"),
                ("Match scenarios", "brain.head.profile"),
                ("Net practice", "sportscourt"),
            ]
        default:
            return [
                ("Skills", "sportscourt"),
                ("Defense", "shield.fill"),
                ("Conditioning", "flame.fill"),
                ("Tactics", "brain.head.profile"),
                ("Recovery", "heart.circle"),
            ]
        }
    }

    private func gameStrengthItems(for sport: String) -> [(String, String)] {
        switch sport {
        case "soccer":
            return [
                ("Passing", "arrow.right.arrow.left"),
                ("Shooting", "scope"),
                ("Defense", "shield.fill"),
                ("Positioning", "mappin.circle"),
                ("Stamina", "flame.fill"),
                ("Leadership", "person.3.fill"),
            ]
        case "basketball":
            return [
                ("Defense", "shield.fill"),
                ("Shooting", "scope"),
                ("Decision making", "brain.head.profile"),
                ("Energy", "bolt.fill"),
                ("Leadership", "person.3.fill"),
            ]
        case "tennis":
            return [
                ("Serve", "arrow.up.forward"),
                ("Returns", "arrow.left.arrow.right"),
                ("Net play", "hand.raised.fill"),
                ("Mental toughness", "brain.head.profile"),
                ("Consistency", "checkmark.circle"),
            ]
        case "football":
            return [
                ("Execution", "checkmark.circle"),
                ("Blocking", "shield.fill"),
                ("Coverage", "eye"),
                ("Tackling", "figure.american.football"),
                ("Awareness", "brain.head.profile"),
                ("Leadership", "person.3.fill"),
            ]
        case "boxing":
            return [
                ("Offense", "bolt.fill"),
                ("Defense", "shield.fill"),
                ("Footwork", "figure.walk"),
                ("Ring control", "circle.circle"),
                ("Power", "flame.fill"),
                ("Composure", "brain.head.profile"),
            ]
        case "cricket":
            return [
                ("Batting", "figure.cricket"),
                ("Bowling", "arrow.up.forward"),
                ("Fielding", "hand.raised.fill"),
                ("Running", "figure.run"),
                ("Concentration", "brain.head.profile"),
                ("Partnerships", "person.2.fill"),
            ]
        default:
            return [
                ("Offense", "bolt.fill"),
                ("Defense", "shield.fill"),
                ("Decision making", "brain.head.profile"),
                ("Energy", "flame.fill"),
                ("Leadership", "person.3.fill"),
            ]
        }
    }

    // MARK: - Multi Select Router

    @ViewBuilder
    private func multiSelectView(for id: String) -> some View {
        switch id {
        case "workedOn":
            MultiSelectStepView(
                question: "What did you work on today?",
                subtitle: "Select all that apply",
                items: trainingItems(for: userSport),
                selected: $viewModel.workedOn,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        case "strongest":
            MultiSelectStepView(
                question: "What was strongest today?",
                subtitle: "Select your standout areas",
                items: gameStrengthItems(for: userSport),
                selected: $viewModel.strongestAreas,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        case "restActivities":
            MultiSelectStepView(
                question: "What did you do today?",
                subtitle: "Select all that apply",
                items: [
                    ("Stretching", "figure.flexibility"),
                    ("Recovery work", "heart.circle"),
                    ("Light training", "figure.walk"),
                    ("Mental training", "brain.head.profile"),
                    ("Full rest", "bed.double.fill"),
                ],
                selected: $viewModel.restActivities,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        default:
            EmptyView()
        }
    }

    // MARK: - Submit

    private func submitEntry() {
        Task {
            if let _ = await viewModel.submit() {
                withAnimation {
                    viewModel.currentStepIndex = viewModel.steps.count - 1
                }
                HapticManager.notification(.success)
                await viewModel.fetchInsight()
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(ColorTheme.separator(colorScheme))
                    .frame(height: 3)

                RoundedRectangle(cornerRadius: 2)
                    .fill(ColorTheme.accent)
                    .frame(width: max(0, geo.size.width * viewModel.progress), height: 3)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, 24)
    }
}

import SwiftUI

enum EntryStep: Hashable {
    case activityType
    case multiSelect(id: String)
    case shortText(id: String)
    case gameStats
    case gameReflections
    case singleChoice(id: String)
    case restReflection
    case submitting
}

@Observable
final class DailyEntryViewModel {
    var currentStepIndex = 0
    var activityType: String = ""

    // Training
    var workedOn: Set<String> = []
    var skillImproved: String = ""
    var hardestDrill: String = ""
    var commonMistake: String = ""
    var tomorrowFocus: String = ""

    // Game stats
    var gameStats: [String: Int] = [:]
    var bestMoment: String = ""
    var biggestMistake: String = ""
    var improveNextGame: String = ""

    // Rest day
    var recoveryActivities: Set<String> = []
    var sportStudy: String = ""
    var restTomorrowFocus: String = ""

    // Universal
    var didWell: String = ""
    var improveNext: String = ""
    var proudMoment: String = ""

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
                .multiSelect(id: "workedOn"),
                .shortText(id: "skillImproved"),
                .shortText(id: "hardestDrill"),
                .shortText(id: "commonMistake"),
                .shortText(id: "tomorrowFocus"),
            ]
        case "game":
            s += [
                .gameStats,
                .gameReflections,
            ]
        case "rest_day":
            s += [
                .multiSelect(id: "recoveryActivities"),
                .singleChoice(id: "sportStudy"),
                .restReflection,
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

    func nextStep() {
        guard currentStepIndex < steps.count - 1 else { return }
        currentStepIndex += 1
    }

    func previousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }

    // MARK: - Rating Computation

    private func computeRatings() -> (focus: Int, effort: Int, confidence: Int) {
        let sport = AuthService.shared.currentUser?.sport ?? "soccer"

        switch activityType {
        case "training":
            let areaCount = workedOn.count
            let textFields = [skillImproved, hardestDrill, commonMistake, tomorrowFocus]
            let filledTexts = textFields.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count

            let focus = min(4 + areaCount + filledTexts / 2, 9)
            let effort = min(3 + areaCount + filledTexts, 9)
            let confidence = min(4 + filledTexts + (areaCount > 2 ? 1 : 0), 8)
            return (max(focus, 3), max(effort, 3), max(confidence, 3))

        case "game":
            let positiveKeys: Set<String> = ["goals", "assists", "points", "touchdowns",
                "runsScored", "setsWon", "aces", "winners", "cleanPunches",
                "steals", "rebounds", "tackles", "sacks", "interceptions",
                "wicketsTaken", "catches", "receptions", "passCompletions",
                "shotsOnTarget", "keyPasses", "roundsFought", "yardsGained"]
            let negativeKeys: Set<String> = ["turnovers", "doubleFaults", "unforcedErrors",
                "warnings", "setsLost", "knockdowns"]

            let positiveTotal = gameStats.filter { positiveKeys.contains($0.key) && $0.value > 0 }.values.reduce(0, +)
            let negativeTotal = gameStats.filter { negativeKeys.contains($0.key) && $0.value > 0 }.values.reduce(0, +)
            let statCount = gameStats.filter { $0.value > 0 }.count

            let rawStat = Double(positiveTotal) - Double(negativeTotal) * 1.5
            let normalizedStat: Int
            switch sport {
            case "soccer":
                normalizedStat = Int((rawStat / 6.0) * 4.0)
            case "basketball":
                normalizedStat = Int((rawStat / 25.0) * 4.0)
            case "tennis":
                normalizedStat = Int((rawStat / 8.0) * 4.0)
            case "boxing":
                normalizedStat = Int((rawStat / 10.0) * 4.0)
            case "cricket":
                normalizedStat = Int((rawStat / 30.0) * 4.0)
            case "football":
                normalizedStat = Int((rawStat / 10.0) * 4.0)
            default:
                normalizedStat = Int((rawStat / 8.0) * 4.0)
            }

            let base = statCount > 0 ? 5 : 4
            let focus = max(min(base + normalizedStat, 9), 2)

            let reflectionBonus = [bestMoment, biggestMistake, improveNextGame]
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
            let effort = max(min(base + normalizedStat + (reflectionBonus > 1 ? 1 : 0), 9), 2)

            let confidence = max(min(base + normalizedStat + (reflectionBonus > 2 ? 1 : 0), 9), 2)

            return (focus, effort, confidence)

        case "rest_day":
            let activityCount = recoveryActivities.count
            let studied = sportStudy == "Watched match film" || sportStudy == "Studied tactics"
            let hasFocus = !restTomorrowFocus.trimmingCharacters(in: .whitespaces).isEmpty

            let focus = max(min(4 + activityCount + (studied ? 1 : 0), 8), 4)
            let effort = max(min(4 + activityCount + (hasFocus ? 1 : 0), 8), 4)
            let confidence = max(min(4 + activityCount + (studied ? 1 : 0) + (hasFocus ? 1 : 0), 8), 4)
            return (focus, effort, confidence)

        default:
            return (5, 5, 5)
        }
    }

    // MARK: - Init from existing entry

    init(existingEntry: DailyEntry? = nil) {
        guard let entry = existingEntry else { return }
        self.activityType = entry.activityType
        self.didWell = entry.responses?.didWell ?? entry.didWell ?? ""
        self.improveNext = entry.responses?.improveNext ?? entry.improveNext ?? ""
        self.proudMoment = entry.responses?.proudMoment ?? ""

        if let r = entry.responses {
            self.workedOn = Set(r.workedOn ?? [])
            self.skillImproved = r.skillImproved ?? ""
            self.hardestDrill = r.hardestDrill ?? ""
            self.commonMistake = r.commonMistake ?? ""
            self.tomorrowFocus = r.tomorrowFocus ?? ""
            self.gameStats = r.gameStats ?? [:]
            self.bestMoment = r.bestMoment ?? ""
            self.biggestMistake = r.biggestMistake ?? ""
            self.improveNextGame = r.improveNextGame ?? ""
            self.recoveryActivities = Set(r.recoveryActivities ?? r.restActivities ?? [])
            self.sportStudy = r.sportStudy ?? ""
            self.restTomorrowFocus = r.restTomorrowFocus ?? ""
        }
    }

    // MARK: - Submit

    func submit() async -> EntrySubmitResponse? {
        isSubmitting = true
        errorMessage = nil

        var responses = EntryResponses()
        responses.didWell = didWell.isEmpty ? nil : didWell
        responses.improveNext = improveNext.isEmpty ? nil : improveNext
        responses.proudMoment = proudMoment.isEmpty ? nil : proudMoment

        switch activityType {
        case "training":
            responses.workedOn = Array(workedOn)
            responses.skillImproved = skillImproved.isEmpty ? nil : skillImproved
            responses.hardestDrill = hardestDrill.isEmpty ? nil : hardestDrill
            responses.commonMistake = commonMistake.isEmpty ? nil : commonMistake
            responses.tomorrowFocus = tomorrowFocus.isEmpty ? nil : tomorrowFocus
        case "game":
            responses.gameStats = gameStats.isEmpty ? nil : gameStats
            responses.bestMoment = bestMoment.isEmpty ? nil : bestMoment
            responses.biggestMistake = biggestMistake.isEmpty ? nil : biggestMistake
            responses.improveNextGame = improveNextGame.isEmpty ? nil : improveNextGame
        case "rest_day":
            responses.recoveryActivities = Array(recoveryActivities)
            responses.sportStudy = sportStudy.isEmpty ? nil : sportStudy
            responses.restTomorrowFocus = restTomorrowFocus.isEmpty ? nil : restTomorrowFocus
        default: break
        }

        let ratings = computeRatings()
        let request = EntrySubmitRequest(
            entryDate: Date().apiDateString,
            activityType: activityType,
            focusRating: ratings.focus,
            effortRating: ratings.effort,
            confidenceRating: ratings.confidence,
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
            request.trainingAreas = Array(workedOn)
            request.skillImproved = skillImproved.isEmpty ? nil : skillImproved
            request.hardestDrill = hardestDrill.isEmpty ? nil : hardestDrill
            request.commonMistake = commonMistake.isEmpty ? nil : commonMistake
            request.tomorrowFocus = tomorrowFocus.isEmpty ? nil : tomorrowFocus
        case "game":
            request.gameStats = gameStats.isEmpty ? nil : gameStats
            request.bestMoment = bestMoment.isEmpty ? nil : bestMoment
            request.biggestMistake = biggestMistake.isEmpty ? nil : biggestMistake
            request.improveNextGame = improveNextGame.isEmpty ? nil : improveNextGame
        case "rest_day":
            request.recoveryActivities = Array(recoveryActivities)
            request.sportStudy = sportStudy.isEmpty ? nil : sportStudy
            request.restTomorrowFocus = restTomorrowFocus.isEmpty ? nil : restTomorrowFocus
        default: break
        }

        request.reflectionPositive = didWell.isEmpty ? nil : didWell
        request.reflectionImprove = improveNext.isEmpty ? nil : improveNext
        request.proudMoment = proudMoment.isEmpty ? nil : proudMoment

        do {
            let insight = try await EntryService.shared.generateInsight(request)
            if !insight.isEmpty { coachInsight = insight }
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
        if existingEntry == nil {
            AnalyticsManager.log("daily_log_started")
        }
    }

    private var userSport: String {
        AuthService.shared.currentUser?.sport ?? "soccer"
    }

    private var trainingAreasForSport: [(String, String)] {
        switch userSport.lowercased() {
        case "soccer":
            return [
                ("Shooting / scoring", "scope"),
                ("Passing", "arrow.right.arrow.left"),
                ("Defense", "shield.fill"),
                ("Dribbling", "figure.run"),
                ("Fitness / conditioning", "flame.fill"),
                ("Tactics", "brain.head.profile"),
                ("Set pieces", "sportscourt"),
            ]
        case "basketball":
            return [
                ("Shooting", "scope"),
                ("Ball handling", "hand.point.up.fill"),
                ("Passing", "arrow.right.arrow.left"),
                ("Defense", "shield.fill"),
                ("Rebounding", "arrow.up.circle.fill"),
                ("Fitness / conditioning", "flame.fill"),
                ("Court vision / IQ", "brain.head.profile"),
            ]
        case "tennis":
            return [
                ("Serve", "arrow.up.forward"),
                ("Return", "arrow.turn.left.up"),
                ("Groundstrokes", "figure.tennis"),
                ("Volleys", "hand.raised.fill"),
                ("Footwork", "figure.walk"),
                ("Fitness / conditioning", "flame.fill"),
                ("Match strategy", "brain.head.profile"),
            ]
        case "football":
            return [
                ("Throwing / passing", "football.fill"),
                ("Catching / receiving", "hand.raised.fill"),
                ("Blocking", "shield.fill"),
                ("Tackling", "figure.american.football"),
                ("Route running", "arrow.triangle.turn.up.right.diamond"),
                ("Fitness / conditioning", "flame.fill"),
                ("Playbook / film study", "brain.head.profile"),
            ]
        case "cricket":
            return [
                ("Batting", "figure.cricket"),
                ("Bowling", "arrow.up.forward"),
                ("Fielding", "hand.raised.fill"),
                ("Wicket keeping", "shield.fill"),
                ("Running between wickets", "figure.run"),
                ("Fitness / conditioning", "flame.fill"),
                ("Match awareness", "brain.head.profile"),
            ]
        case "boxing":
            return [
                ("Combinations", "hands.sparkles.fill"),
                ("Footwork", "figure.walk"),
                ("Defense / head movement", "shield.fill"),
                ("Body work", "figure.boxing"),
                ("Sparring", "person.2.fill"),
                ("Bag / pad work", "flame.fill"),
                ("Conditioning / cardio", "heart.circle.fill"),
            ]
        default:
            return [
                ("Skill work", "star.fill"),
                ("Technique", "figure.run"),
                ("Defense", "shield.fill"),
                ("Fitness / conditioning", "flame.fill"),
                ("Tactics / strategy", "brain.head.profile"),
                ("Speed / agility", "hare.fill"),
            ]
        }
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
                onNext: { viewModel.currentStepIndex = 1 }
            )

        case .multiSelect(let id):
            multiSelectView(for: id)

        case .shortText(let id):
            shortTextView(for: id)

        case .gameStats:
            GameStatsView(
                sport: userSport,
                stats: $viewModel.gameStats,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        case .gameReflections:
            GameReflectionsView(
                sport: userSport,
                bestMoment: $viewModel.bestMoment,
                biggestMistake: $viewModel.biggestMistake,
                improveNextGame: $viewModel.improveNextGame,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        case .singleChoice(let id):
            singleChoiceView(for: id)

        case .restReflection:
            ShortTextStepView(
                question: "What is your focus for tomorrow?",
                subtitle: "Set your intention",
                icon: "target",
                placeholder: "e.g. Work on first touch, increase sprint speed...",
                text: $viewModel.restTomorrowFocus,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() },
                isOptional: true
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
                    .task { submitEntry() }
            }
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
                items: trainingAreasForSport,
                selected: $viewModel.workedOn,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        case "recoveryActivities":
            MultiSelectStepView(
                question: "What did you do today?",
                subtitle: "Select your recovery activities",
                items: [
                    ("Stretching", "figure.flexibility"),
                    ("Mobility", "figure.walk"),
                    ("Ice bath", "snowflake"),
                    ("Massage", "hand.raised.fill"),
                    ("Rest", "bed.double.fill"),
                ],
                selected: $viewModel.recoveryActivities,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )

        default:
            EmptyView()
        }
    }

    // MARK: - Short Text Router

    @ViewBuilder
    private func shortTextView(for id: String) -> some View {
        switch id {
        case "skillImproved":
            ShortTextStepView(
                question: "What skill improved the most today?",
                subtitle: "Think about what clicked",
                icon: "arrow.up.right",
                placeholder: "e.g. My left foot shooting felt sharper...",
                text: $viewModel.skillImproved,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )
        case "hardestDrill":
            ShortTextStepView(
                question: "What was the hardest drill today?",
                subtitle: "The one that pushed you",
                icon: "bolt.fill",
                placeholder: "e.g. 1v1 defending under pressure...",
                text: $viewModel.hardestDrill,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )
        case "commonMistake":
            ShortTextStepView(
                question: "What mistake happened the most today?",
                subtitle: "Be honest — awareness is growth",
                icon: "exclamationmark.triangle",
                placeholder: "e.g. Losing the ball with my first touch...",
                text: $viewModel.commonMistake,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() }
            )
        case "tomorrowFocus":
            ShortTextStepView(
                question: "What will you focus on tomorrow?",
                subtitle: "Set your intention",
                icon: "target",
                placeholder: "e.g. Keep my head up when receiving the ball...",
                text: $viewModel.tomorrowFocus,
                onNext: { viewModel.nextStep() },
                onBack: { viewModel.previousStep() },
                isOptional: true
            )
        default:
            EmptyView()
        }
    }

    // MARK: - Single Choice Router

    @ViewBuilder
    private func singleChoiceView(for id: String) -> some View {
        switch id {
        case "sportStudy":
            SingleChoiceStepView(
                question: "Did you study your sport today?",
                subtitle: "Mental reps count too",
                options: [
                    ChoiceOption("Watched match film", icon: "play.rectangle.fill", subtitle: "Analyzed game footage"),
                    ChoiceOption("Studied tactics", icon: "brain.head.profile", subtitle: "Reviewed strategy or plays"),
                    ChoiceOption("No", icon: "xmark.circle", subtitle: "Full rest today"),
                ],
                selection: $viewModel.sportStudy,
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
                    viewModel.currentStepIndex = max(viewModel.steps.count - 1, 0)
                }
                HapticManager.notification(.success)

                let type = viewModel.activityType
                AnalyticsManager.log("daily_log_completed", parameters: ["type": type])
                switch type {
                case "training": AnalyticsManager.log("training_logged")
                case "game": AnalyticsManager.log("game_logged")
                case "rest_day": AnalyticsManager.log("rest_day_logged")
                default: break
                }

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

import SwiftUI

enum EntryStep: Int, CaseIterable {
    case activityType
    case ratings
    case reflections
    case rotatingQuestion
    case submitting
}

@Observable
final class DailyEntryViewModel {
    var currentStep: EntryStep = .activityType
    var activityType: String = ""
    var focusRating: Double = 5
    var effortRating: Double = 5
    var confidenceRating: Double = 5
    var didWell: String = ""
    var improveNext: String = ""
    var rotatingQuestionId: Int
    var rotatingAnswer: String = ""
    var isSliderQuestion: Bool
    var rotatingSliderValue: Double = 5
    var isSubmitting = false
    var errorMessage: String?
    var submittedResponse: EntrySubmitResponse?

    let rotatingQuestions: [(id: Int, text: String, type: String)] = [
        (1, "How focused were you during training today?", "slider"),
        (2, "Did you give maximum effort today?", "slider"),
        (3, "How confident did you feel today?", "slider"),
        (4, "How well did you handle mistakes today?", "slider"),
        (5, "How disciplined were you today?", "slider"),
        (6, "How was your energy level today?", "slider"),
        (7, "Did you follow your training plan today?", "slider"),
        (8, "What did you learn today?", "text"),
        (9, "How prepared did you feel today?", "slider"),
        (10, "How satisfied are you with today's performance?", "slider"),
    ]

    var todaysQuestion: (id: Int, text: String, type: String) {
        rotatingQuestions[rotatingQuestionId - 1]
    }

    init() {
        let dayIndex = (Date().dayOfYear % 10)
        let qId = dayIndex == 0 ? 10 : dayIndex
        self.rotatingQuestionId = qId
        self.isSliderQuestion = qId != 8
    }

    func nextStep() {
        guard let next = EntryStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func previousStep() {
        guard let prev = EntryStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    func submit() async -> EntrySubmitResponse? {
        isSubmitting = true
        errorMessage = nil

        let answer = isSliderQuestion ? String(Int(rotatingSliderValue)) : rotatingAnswer
        let request = EntrySubmitRequest(
            entryDate: Date().apiDateString,
            activityType: activityType,
            focusRating: Int(focusRating),
            effortRating: Int(effortRating),
            confidenceRating: Int(confidenceRating),
            didWell: didWell.isEmpty ? nil : didWell,
            improveNext: improveNext.isEmpty ? nil : improveNext,
            rotatingQuestionId: rotatingQuestionId,
            rotatingAnswer: answer.isEmpty ? nil : answer
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
}

struct DailyEntryFlowView: View {
    @State private var viewModel = DailyEntryViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let onComplete: (EntrySubmitResponse) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background(colorScheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    progressBar
                        .padding(.top, 8)

                    Group {
                        switch viewModel.currentStep {
                        case .activityType:
                            ActivityTypeView(
                                selectedType: $viewModel.activityType,
                                onNext: { viewModel.nextStep() }
                            )
                        case .ratings:
                            RatingsView(
                                focus: $viewModel.focusRating,
                                effort: $viewModel.effortRating,
                                confidence: $viewModel.confidenceRating,
                                onNext: { viewModel.nextStep() },
                                onBack: { viewModel.previousStep() }
                            )
                        case .reflections:
                            ReflectionsView(
                                didWell: $viewModel.didWell,
                                improveNext: $viewModel.improveNext,
                                onNext: { viewModel.nextStep() },
                                onBack: { viewModel.previousStep() }
                            )
                        case .rotatingQuestion:
                            RotatingQuestionView(
                                question: viewModel.todaysQuestion,
                                textAnswer: $viewModel.rotatingAnswer,
                                sliderValue: $viewModel.rotatingSliderValue,
                                isSlider: viewModel.isSliderQuestion,
                                onSubmit: { submitEntry() },
                                onBack: { viewModel.previousStep() },
                                isSubmitting: viewModel.isSubmitting,
                                errorMessage: viewModel.errorMessage
                            )
                        case .submitting:
                            if let response = viewModel.submittedResponse {
                                EntrySubmittedView(
                                    response: response,
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
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
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

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(EntryStep.allCases, id: \.rawValue) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step.rawValue <= viewModel.currentStep.rawValue
                          ? ColorTheme.accent
                          : ColorTheme.separator(colorScheme))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
        .padding(.horizontal, 24)
    }

    private func submitEntry() {
        Task {
            if let response = await viewModel.submit() {
                withAnimation { viewModel.currentStep = .submitting }
                HapticManager.notification(.success)
            }
        }
    }
}

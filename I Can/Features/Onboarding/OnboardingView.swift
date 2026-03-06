import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.colorScheme) private var colorScheme
    var startAtStep: OnboardingStep = .welcome

    var body: some View {
        ZStack {
            ColorTheme.background(colorScheme).ignoresSafeArea()

            VStack {
                progressBar

                Group {
                    switch viewModel.currentStep {
                    case .welcome:
                        welcomeView
                    case .sportSelection:
                        SportSelectionView(
                            selectedSport: $viewModel.selectedSport,
                            sports: viewModel.sports,
                            onNext: { viewModel.nextStep() }
                        )
                    case .mantraCreation:
                        MantraCreationView(
                            mantra: $viewModel.mantra,
                            examples: viewModel.mantraExamples,
                            onNext: { viewModel.nextStep() },
                            onBack: { viewModel.previousStep() }
                        )
                    case .notificationFrequency:
                        NotificationFrequencyView(
                            frequency: $viewModel.notificationFrequency,
                            onNext: { viewModel.nextStep() },
                            onBack: { viewModel.previousStep() }
                        )
                    case .accountCreation:
                        AccountCreationView(viewModel: viewModel)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
        .onAppear {
            viewModel.currentStep = startAtStep
        }
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step.rawValue <= viewModel.currentStep.rawValue
                          ? ColorTheme.accent
                          : ColorTheme.cardBackground(colorScheme))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var welcomeView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 80))
                .foregroundColor(ColorTheme.accent)

            VStack(spacing: 12) {
                Text("I Can")
                    .font(Typography.largeTitle)
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Text("Track Your Performance.\nImprove Mentally & Physically.")
                    .font(Typography.body)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            PrimaryButton(title: "Get Started") {
                withAnimation { viewModel.nextStep() }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

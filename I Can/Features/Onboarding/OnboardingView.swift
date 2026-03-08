import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.colorScheme) private var colorScheme
    var startAtStep: OnboardingStep = .welcome

    var body: some View {
        ZStack {
            ColorTheme.background(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.currentStep != .welcome && !viewModel.showLogin {
                    progressBar
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                }

                Group {
                    if viewModel.showLogin {
                        LoginView(viewModel: viewModel)
                    } else { switch viewModel.currentStep {
                    case .welcome:
                        welcomeView
                    case .sportSelection:
                        SportSelectionView(
                            selectedSport: $viewModel.selectedSport,
                            sports: viewModel.sports,
                            onNext: { viewModel.nextStep() },
                            onBack: { viewModel.previousStep() }
                        )
                    case .nameEntry:
                        NameEntryView(
                            name: $viewModel.athleteName,
                            onNext: { viewModel.nextStep() },
                            onBack: { viewModel.previousStep() }
                        )
                    case .ageSelection:
                        AgeSelectionView(
                            age: $viewModel.selectedAge,
                            onNext: { viewModel.nextStep() },
                            onBack: { viewModel.previousStep() }
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
                    }}
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.35), value: viewModel.currentStep)
            }
        }
        .onAppear {
            viewModel.currentStep = startAtStep
        }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
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

    private var welcomeView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 10) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220, height: 220)

                Text("I Can")
                    .font(.system(size: 44, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                Text("Track Your Performance.\nImprove Mentally & Physically.")
                    .font(Typography.body)
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()

            VStack(spacing: 16) {
                PrimaryButton(title: "Get Started") {
                    withAnimation { viewModel.nextStep() }
                }

                Button {
                    withAnimation { viewModel.showLogin = true }
                } label: {
                    Text("Already have an account? **Sign In**")
                        .font(.system(size: 13, weight: .medium).width(.condensed))
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

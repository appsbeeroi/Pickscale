import SwiftUI
import Combine
import CoreData

enum AppPhase {
    case splash
    case onboarding
    case main
}

@MainActor
final class AppStageController: ObservableObject {
    @Published var phase: AppPhase = .splash
}

struct RootStageView: View {
    @EnvironmentObject private var stage: AppStageController
    @EnvironmentObject private var prefs: RoostPreferences
    @EnvironmentObject private var overlay: OverlayOrchestrator

    var body: some View {
        ZStack {
            switch stage.phase {
            case .splash:
                RoostSplashView {
                    finishSplash()
                }
                .transition(.opacity)
            case .onboarding:
                FledglingOnboardingView {
                    finishOnboarding()
                }
                .transition(.opacity)
            case .main:
                MainFlowStack()
                    .transition(.opacity)
            }

            OverlayHostLayer(orchestrator: overlay)
        }
        .animation(.easeInOut(duration: 0.45), value: stagePhaseValue)
    }

    private var stagePhaseValue: Int {
        switch stage.phase {
        case .splash: return 0
        case .onboarding: return 1
        case .main: return 2
        }
    }

    private func finishSplash() {
        stage.phase = prefs.onboardingCompleted ? .main : .onboarding
    }

    private func finishOnboarding() {
        prefs.onboardingCompleted = true
        stage.phase = .main
    }
}

struct MainFlowStack: View {
    @EnvironmentObject private var router: NestRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            HomesteadMenuView()
                .navigationDestination(for: RoostRoute.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: RoostRoute) -> some View {
        switch route {
        case .packs:
            NestPackGalleryView()
        case .yard(let levelKey):
            YardweighSessionCoordinatorView(levelKey: levelKey)
        case .clueLedger(let levelKey):
            ClueScratchpadLedgerView(levelKey: levelKey)
        case .answerBoard(let levelKey):
            AnswerBoardView(levelKey: levelKey)
        case .roundResult(let payload):
            RoundResultView(payload: payload)
        case .progressBarn:
            NestpackProgressBarn()
        case .howToPlay:
            HowToPlayView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    RootStageView()
        .environmentObject(AppStageController())
        .environmentObject(RoostPreferences())
        .environmentObject(OverlayOrchestrator())
        .environmentObject(NestRouter())
        .environmentObject(ProgressVault(context: PersistenceController.preview.container.viewContext))
}

import SwiftUI
import Combine

enum RoostRoute: Hashable {
    case packs
    case yard(levelKey: String)
    case clueLedger(levelKey: String)
    case answerBoard(levelKey: String)
    case roundResult(RoundResultPayload)
    case progressBarn
    case howToPlay
    case settings
}

struct RoundResultPayload: Hashable {
    let levelKey: String
    let weighingsUsed: Int
    let stars: Int
    let newBest: Bool
    let readOnly: Bool
}

@MainActor
final class NestRouter: ObservableObject {
    @Published var path: [RoostRoute] = []
    @Published var activeSession: YardweighSessionCoordinator?

    func push(_ route: RoostRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    func popTo(_ route: RoostRoute) {
        if let index = path.lastIndex(of: route) {
            path.removeSubrange((index + 1)...)
        }
    }

    func openYard(level: FlockLevel, vault: ProgressVault, prefs: RoostPreferences) {
        let session = YardweighSessionCoordinator(level: level, vault: vault, prefs: prefs)
        activeSession = session
        vault.touchLastPlayed(level)
        push(.yard(levelKey: level.key))
    }

    func startTutorial(vault: ProgressVault, prefs: RoostPreferences) {
        openYard(level: OddbirdDeductionRulebook.tutorialLevel, vault: vault, prefs: prefs)
    }
}

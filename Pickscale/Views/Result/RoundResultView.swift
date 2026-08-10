import SwiftUI
import CoreData

struct RoundResultView: View {
    @EnvironmentObject private var router: NestRouter
    @EnvironmentObject private var vault: ProgressVault
    @EnvironmentObject private var prefs: RoostPreferences
    @EnvironmentObject private var overlay: OverlayOrchestrator

    let payload: RoundResultPayload

    @State private var revealedStars = 0
    @State private var titlePop = false

    private var level: FlockLevel? {
        OddbirdDeductionRulebook.level(forKey: payload.levelKey)
    }

    var body: some View {
        ZStack {
            YardBackdrop()

            VStack(spacing: 18) {
                Spacer(minLength: 8)

                Text(payload.readOnly ? "Level Complete" : "Puzzle Solved")
                    .font(RoostFont.bold(42))
                    .foregroundStyle(RoostPalette.cream)
                    .shadow(color: RoostPalette.dusk.opacity(0.8), radius: 2, x: 0, y: 2)
                    .scaleEffect(titlePop ? 1 : 0.7)
                    .opacity(titlePop ? 1 : 0)

                starRow

                ParchmentPanel {
                    VStack(spacing: 8) {
                        statRow(label: "Moves used", value: "\(payload.weighingsUsed)")
                        if let level {
                            statRow(label: "Best result", value: "\(bestResult(level)) weighings")
                        }
                        if payload.newBest {
                            Text("New best!")
                                .font(RoostFont.bold(22))
                                .foregroundStyle(RoostPalette.leafGreen)
                        }
                    }
                }
                .padding(.horizontal, 26)

                Spacer(minLength: 8)

                VStack(spacing: 12) {
                    RusticButton(title: "View Optimal Route", kind: .secondary, height: 58, fontSize: 21) {
                        showOptimalRoute()
                    }
                    if payload.readOnly {
                        RusticButton(title: "Replay Level", kind: .primary, height: 62, fontSize: 24) {
                            replay()
                        }
                        RusticButton(title: "Back to Progress", kind: .secondary, height: 56, fontSize: 20) {
                            router.pop()
                        }
                    } else {
                        RusticButton(title: nextTitle, kind: .primary, height: 62, fontSize: 24) {
                            goNext()
                        }
                        RusticButton(title: "Back to Packs", kind: .secondary, height: 56, fontSize: 20) {
                            router.path = [.packs]
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: animateEntrance)
    }

    private var starRow: some View {
        HStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { index in
                Image(index < revealedStars ? "star_filled" : "star_empty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 66, height: 66)
                    .scaleEffect(index < revealedStars ? 1 : 0.6)
                    .rotationEffect(.degrees(index < revealedStars ? 0 : -25))
                    .animation(.spring(response: 0.5, dampingFraction: 0.5), value: revealedStars)
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(RoostFont.medium(20))
                .foregroundStyle(RoostPalette.bark)
            Spacer()
            Text(value)
                .font(RoostFont.bold(20))
                .foregroundStyle(RoostPalette.barkDark)
        }
    }

    private var nextTitle: String {
        guard let level, OddbirdDeductionRulebook.nextLevel(after: level) != nil else {
            return "Continue"
        }
        return "Next Level"
    }

    private func bestResult(_ level: FlockLevel) -> Int {
        let best = vault.record(forKey: level.key).bestWeighings
        return best == 0 ? payload.weighingsUsed : best
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            titlePop = true
        }
        for step in 1...payload.stars {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35 * Double(step)) {
                withAnimation { revealedStars = step }
                AppAudioConductor.shared.play(.star)
                HapticPulse.tap()
            }
        }
    }

    private func showOptimalRoute() {
        guard let level else { return }
        let route = FlockmassPuzzleEngine(level: level).optimalRoute()
        overlay.present {
            OptimalRouteCard(route: route) {
                overlay.dismiss()
            }
        }
    }

    private func goNext() {
        guard let level, let next = OddbirdDeductionRulebook.nextLevel(after: level) else {
            router.path = [.packs]
            return
        }
        router.path = [.packs]
        router.openYard(level: next, vault: vault, prefs: prefs)
    }

    private func replay() {
        guard let level else { return }
        router.pop()
        router.openYard(level: level, vault: vault, prefs: prefs)
    }
}

struct OptimalRouteCard: View {
    let route: [FlockComparison]
    let onDismiss: () -> Void

    var body: some View {
        ParchmentPanel(padding: 20) {
            VStack(spacing: 12) {
                Text("Optimal Route")
                    .font(RoostFont.bold(28))
                    .foregroundStyle(RoostPalette.barkDark)
                Text("A tidy sequence of comparisons.")
                    .font(RoostFont.medium(16))
                    .foregroundStyle(RoostPalette.bark)
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(route.enumerated()), id: \.element.id) { pair in
                            HStack {
                                Text("Step \(pair.offset + 1)")
                                    .font(RoostFont.semibold(16))
                                    .foregroundStyle(RoostPalette.bark)
                                Text("\(letters(pair.element.left)) vs \(letters(pair.element.right))")
                                    .font(RoostFont.medium(18))
                                    .foregroundStyle(RoostPalette.barkDark)
                                Spacer()
                                Text(verdict(pair.element.verdict))
                                    .font(RoostFont.semibold(16))
                                    .foregroundStyle(RoostPalette.leafGreen)
                            }
                            Divider().background(RoostPalette.bark.opacity(0.3))
                        }
                    }
                }
                .frame(maxHeight: 300)
                RusticButton(title: "Close", kind: .primary, height: 54, fontSize: 20) {
                    onDismiss()
                }
            }
        }
        .frame(maxWidth: 360)
        .padding(.horizontal, 24)
    }

    private func letters(_ indices: [Int]) -> String {
        indices.isEmpty ? "—" : indices.map { HenGlyph.letter(for: $0) }.joined()
    }

    private func verdict(_ verdict: WeighVerdict) -> String {
        switch verdict {
        case .leftHeavier: return "Left"
        case .rightHeavier: return "Right"
        case .balanced: return "Balanced"
        }
    }
}

#Preview {
    RoundResultView(payload: RoundResultPayload(levelKey: "hatchling_run-1", weighingsUsed: 2, stars: 3, newBest: true, readOnly: false))
        .environmentObject(NestRouter())
        .environmentObject(ProgressVault(context: PersistenceController.preview.container.viewContext))
        .environmentObject(RoostPreferences())
        .environmentObject(OverlayOrchestrator())
}

import SwiftUI
import Combine
import CoreData

enum PanSide {
    case left
    case right
}

@MainActor
final class YardweighSessionCoordinator: ObservableObject {
    let level: FlockLevel
    let engine: FlockmassPuzzleEngine
    private let vault: ProgressVault
    private let prefs: RoostPreferences

    @Published var draft: DraftSnapshot
    @Published var lastVerdict: WeighVerdict?
    let answerMatrix: PeckOrderAnswerMatrix

    private var ledgerUndoStack: [ClueScratchpadState] = []

    var isTutorial: Bool { level.packId == "tutorial" }

    init(level: FlockLevel, vault: ProgressVault, prefs: RoostPreferences) {
        self.level = level
        self.vault = vault
        self.prefs = prefs
        self.engine = FlockmassPuzzleEngine(level: level)
        self.answerMatrix = PeckOrderAnswerMatrix(level: level)

        if let saved = vault.loadDraft(forKey: level.key) {
            self.draft = saved
        } else {
            self.draft = DraftSnapshot(movesRemaining: level.moveLimit)
        }
        self.lastVerdict = draft.history.last?.verdict
    }

    var panLeft: [Int] { draft.panLeft }
    var panRight: [Int] { draft.panRight }

    var unplaced: [Int] {
        engine.birdIndices.filter { !draft.panLeft.contains($0) && !draft.panRight.contains($0) }
    }

    var movesUsed: Int { level.moveLimit - draft.movesRemaining }

    var canWeigh: Bool {
        draft.movesRemaining > 0 && (!draft.panLeft.isEmpty || !draft.panRight.isEmpty)
    }

    func place(_ index: Int, on side: PanSide) {
        draft.panLeft.removeAll { $0 == index }
        draft.panRight.removeAll { $0 == index }
        switch side {
        case .left: draft.panLeft.append(index)
        case .right: draft.panRight.append(index)
        }
        AppAudioConductor.shared.play(.place)
        HapticPulse.tap()
        persist()
    }

    func removeFromPans(_ index: Int) {
        draft.panLeft.removeAll { $0 == index }
        draft.panRight.removeAll { $0 == index }
        AppAudioConductor.shared.play(.tap)
        persist()
    }

    func clearPans() {
        guard !draft.panLeft.isEmpty || !draft.panRight.isEmpty else { return }
        draft.panLeft.removeAll()
        draft.panRight.removeAll()
        AppAudioConductor.shared.play(.tap)
        HapticPulse.tap()
        persist()
    }

    func weigh() {
        guard canWeigh else { return }
        let verdict = engine.verdict(left: draft.panLeft, right: draft.panRight)
        let entry = FlockComparison(left: draft.panLeft, right: draft.panRight, verdict: verdict)
        draft.history.append(entry)
        draft.movesRemaining -= 1
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            lastVerdict = verdict
        }
        AppAudioConductor.shared.play(.weigh)
        HapticPulse.firm()
        persist()
    }

    func setLedgerRelation(_ relation: LedgerRelation?, a: Int, b: Int) {
        pushUndo()
        draft.ledger.setRelation(relation, a: a, b: b)
        persist()
    }

    func toggleEliminated(_ index: Int) {
        pushUndo()
        if let pos = draft.ledger.eliminated.firstIndex(of: index) {
            draft.ledger.eliminated.remove(at: pos)
        } else {
            draft.ledger.eliminated.append(index)
        }
        persist()
    }

    func undoLastMark() {
        guard let previous = ledgerUndoStack.popLast() else { return }
        draft.ledger = previous
        AppAudioConductor.shared.play(.tap)
        persist()
    }

    func resetNotes() {
        pushUndo()
        draft.ledger = ClueScratchpadState()
        persist()
    }

    var canUndoLedger: Bool { !ledgerUndoStack.isEmpty }

    private func pushUndo() {
        ledgerUndoStack.append(draft.ledger)
        if ledgerUndoStack.count > 40 {
            ledgerUndoStack.removeFirst()
        }
    }

    func persist() {
        vault.saveDraft(draft, forKey: level.key)
    }

    func submit() -> RoundResultPayload? {
        let correct = answerMatrix.evaluate(with: engine)
        if correct {
            let stars = engine.stars(forRemaining: draft.movesRemaining)
            var newBest = false
            if isTutorial {
                prefs.tutorialCompleted = true
            } else {
                newBest = vault.registerSolve(level: level, weighingsUsed: movesUsed, stars: stars)
                vault.discardDraft(forKey: level.key)
            }
            AppAudioConductor.shared.play(.correct)
            HapticPulse.success()
            return RoundResultPayload(
                levelKey: level.key,
                weighingsUsed: movesUsed,
                stars: stars,
                newBest: newBest,
                readOnly: false
            )
        } else {
            AppAudioConductor.shared.play(.wrong)
            HapticPulse.warning()
            return nil
        }
    }
}

struct YardweighSessionCoordinatorView: View {
    @EnvironmentObject private var router: NestRouter

    let levelKey: String

    var body: some View {
        Group {
            if let session = router.activeSession, session.level.key == levelKey {
                YardStageContent(session: session)
            } else {
                fallback
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var fallback: some View {
        ZStack {
            YardBackdrop()
            VStack(spacing: 16) {
                Text("This puzzle is no longer active.")
                    .font(RoostFont.medium(22))
                    .foregroundStyle(RoostPalette.cream)
                RusticButton(title: "Back to Packs", kind: .secondary) {
                    router.popToRoot()
                    router.push(.packs)
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

private struct YardStageContent: View {
    @ObservedObject var session: YardweighSessionCoordinator
    @EnvironmentObject private var router: NestRouter

    var body: some View {
        ZStack {
            YardBackdrop()

            VStack(spacing: 8) {
                topBar

                taskBadge

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        flockTray

                        RoostBalanceBeamView(session: session)

                        resultPanel

                        HStack(spacing: 14) {
                            RusticButton(title: "Clear Pans", kind: .secondary, height: 56, fontSize: 20) {
                                session.clearPans()
                            }
                            RusticButton(title: "Weigh", kind: .primary, height: 56, fontSize: 22, enabled: session.canWeigh) {
                                session.weigh()
                            }
                        }
                        .padding(.horizontal, 18)

                        historyStrip
                    }
                    .padding(.bottom, 8)
                }

                HStack(spacing: 14) {
                    RusticButton(title: "Clue Ledger", kind: .secondary, height: 58, fontSize: 20) {
                        router.push(.clueLedger(levelKey: session.level.key))
                    }
                    RusticButton(title: "Answer Board", kind: .primary, height: 58, fontSize: 20) {
                        router.push(.answerBoard(levelKey: session.level.key))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 6)
            }
        }
    }

    private var topBar: some View {
        HStack {
            NestBackButton { router.pop() }
            Spacer()
            VStack(spacing: 0) {
                Text(session.isTutorial ? "Tutorial Weigh" : levelTitle)
                    .font(RoostFont.bold(22))
                    .foregroundStyle(RoostPalette.cream)
                Text(packTitle)
                    .font(RoostFont.medium(15))
                    .foregroundStyle(RoostPalette.cream.opacity(0.9))
            }
            .shadow(color: RoostPalette.dusk.opacity(0.7), radius: 1, x: 0, y: 1)
            Spacer()
            movesBadge
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private var levelTitle: String {
        "Level \(session.level.ordinal)"
    }

    private var packTitle: String {
        OddbirdDeductionRulebook.pack(for: session.level.packId)?.title ?? "Tutorial"
    }

    private var movesBadge: some View {
        VStack(spacing: 0) {
            Text("Moves")
                .font(RoostFont.medium(13))
                .foregroundStyle(RoostPalette.barkDark)
            Text("\(session.draft.movesRemaining)")
                .font(RoostFont.bold(24))
                .foregroundStyle(session.draft.movesRemaining == 0 ? RoostPalette.ember : RoostPalette.leafGreen)
        }
        .frame(width: 58, height: 48)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(RoostPalette.cream.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(RoostPalette.bark, lineWidth: 3))
        )
    }

    private var taskBadge: some View {
        HStack(spacing: 8) {
            Image(session.level.task.iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
            Text(session.level.task.badgeTitle)
                .font(RoostFont.semibold(19))
                .foregroundStyle(RoostPalette.barkDark)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(RoostPalette.parchment.opacity(0.95))
                .overlay(Capsule().stroke(RoostPalette.bark, lineWidth: 3))
        )
    }

    private var flockTray: some View {
        VStack(spacing: 4) {
            Text("Flock — drag or tap a hen onto a pan")
                .font(RoostFont.medium(14))
                .foregroundStyle(RoostPalette.cream)
                .shadow(color: RoostPalette.dusk.opacity(0.7), radius: 1, x: 0, y: 1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if session.unplaced.isEmpty {
                        Text("All hens are on the pans")
                            .font(RoostFont.medium(15))
                            .foregroundStyle(RoostPalette.bark)
                            .padding(.vertical, 14)
                    } else {
                        ForEach(session.unplaced, id: \.self) { index in
                            Button {
                                let side: PanSide = session.panLeft.count <= session.panRight.count ? .left : .right
                                session.place(index, on: side)
                            } label: {
                                HenTokenChip(index: index, size: 54)
                            }
                            .buttonStyle(RusticButtonStyle())
                            .draggable(String(index))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 84)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RoostPalette.bark.opacity(0.45))
        )
        .padding(.horizontal, 14)
    }

    private var resultPanel: some View {
        HStack(spacing: 12) {
            Image(verdictAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
            Text(verdictText)
                .font(RoostFont.bold(24))
                .foregroundStyle(RoostPalette.barkDark)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RoostPalette.cream.opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(RoostPalette.bark, lineWidth: 3))
        )
        .padding(.horizontal, 18)
    }

    private var verdictAsset: String {
        switch session.lastVerdict {
        case .leftHeavier: return "result_left_heavier"
        case .rightHeavier: return "result_right_heavier"
        case .balanced: return "result_balanced"
        case nil: return "result_balanced"
        }
    }

    private var verdictText: String {
        switch session.lastVerdict {
        case .leftHeavier: return "Left heavier"
        case .rightHeavier: return "Right heavier"
        case .balanced: return "Balanced"
        case nil: return "Weigh to compare"
        }
    }

    private var historyStrip: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Weighing history")
                .font(RoostFont.medium(14))
                .foregroundStyle(RoostPalette.cream)
                .shadow(color: RoostPalette.dusk.opacity(0.7), radius: 1, x: 0, y: 1)
                .padding(.leading, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if session.draft.history.isEmpty {
                        Text("No weighings yet")
                            .font(RoostFont.medium(14))
                            .foregroundStyle(RoostPalette.bark)
                            .padding(10)
                    } else {
                        ForEach(Array(session.draft.history.enumerated()), id: \.element.id) { pair in
                            historyCell(order: pair.offset + 1, entry: pair.element)
                        }
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private func historyCell(order: Int, entry: FlockComparison) -> some View {
        VStack(spacing: 3) {
            Text("#\(order)")
                .font(RoostFont.semibold(13))
                .foregroundStyle(RoostPalette.bark)
            Text("\(letters(entry.left)) vs \(letters(entry.right))")
                .font(RoostFont.medium(14))
                .foregroundStyle(RoostPalette.barkDark)
            Text(shortVerdict(entry.verdict))
                .font(RoostFont.semibold(13))
                .foregroundStyle(RoostPalette.leafGreen)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RoostPalette.cream.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(RoostPalette.bark, lineWidth: 2))
        )
    }

    private func letters(_ indices: [Int]) -> String {
        indices.isEmpty ? "—" : indices.map { HenGlyph.letter(for: $0) }.joined()
    }

    private func shortVerdict(_ verdict: WeighVerdict) -> String {
        switch verdict {
        case .leftHeavier: return "L>R"
        case .rightHeavier: return "R>L"
        case .balanced: return "L=R"
        }
    }
}

#Preview {
    let prefs = RoostPreferences()
    let vault = ProgressVault(context: PersistenceController.preview.container.viewContext)
    let router = NestRouter()
    let session = YardweighSessionCoordinator(level: OddbirdDeductionRulebook.tutorialLevel, vault: vault, prefs: prefs)
    router.activeSession = session
    return NavigationStack {
        YardweighSessionCoordinatorView(levelKey: session.level.key)
            .environmentObject(router)
            .environmentObject(vault)
            .environmentObject(prefs)
    }
}

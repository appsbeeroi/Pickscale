import SwiftUI
import CoreData

struct ClueScratchpadLedgerView: View {
    @EnvironmentObject private var router: NestRouter

    let levelKey: String

    var body: some View {
        Group {
            if let session = router.activeSession, session.level.key == levelKey {
                ClueLedgerContent(session: session)
            } else {
                ZStack {
                    YardBackdrop()
                    RusticButton(title: "Back", kind: .secondary) { router.pop() }
                        .padding(.horizontal, 60)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ClueLedgerContent: View {
    @ObservedObject var session: YardweighSessionCoordinator
    @EnvironmentObject private var router: NestRouter
    @EnvironmentObject private var overlay: OverlayOrchestrator

    private var pairs: [(Int, Int)] {
        var result: [(Int, Int)] = []
        let n = session.level.birdCount
        for i in 0..<n {
            for j in (i + 1)..<n {
                result.append((i, j))
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            YardBackdrop()

            VStack(spacing: 10) {
                header

                Text(session.level.task.prompt)
                    .font(RoostFont.medium(17))
                    .foregroundStyle(RoostPalette.cream)
                    .multilineTextAlignment(.center)
                    .shadow(color: RoostPalette.dusk.opacity(0.7), radius: 1, x: 0, y: 1)
                    .padding(.horizontal, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        relationsPanel
                        eliminatedPanel
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }

                HStack(spacing: 14) {
                    RusticButton(title: "Undo Mark", kind: .secondary, height: 56, fontSize: 20, enabled: session.canUndoLedger) {
                        session.undoLastMark()
                    }
                    RusticButton(title: "Reset Notes", kind: .destructive, height: 56, fontSize: 20) {
                        confirmReset()
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
            }
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                NestBackButton { router.pop() }
                Spacer()
            }
            ScreenTitle(text: "Clue Ledger", size: 32)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    private var relationsPanel: some View {
        ParchmentPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("Pair Relations")
                    .font(RoostFont.bold(22))
                    .foregroundStyle(RoostPalette.barkDark)
                ForEach(pairs.indices, id: \.self) { idx in
                    let pair = pairs[idx]
                    relationRow(a: pair.0, b: pair.1)
                    if idx < pairs.count - 1 {
                        Divider().background(RoostPalette.bark.opacity(0.3))
                    }
                }
            }
        }
    }

    private func relationRow(a: Int, b: Int) -> some View {
        let current = session.draft.ledger.relation(a, b)
        return HStack(spacing: 10) {
            HStack(spacing: 4) {
                letterChip(a)
                Text("vs")
                    .font(RoostFont.medium(16))
                    .foregroundStyle(RoostPalette.bark)
                letterChip(b)
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(LedgerRelation.allCases, id: \.self) { relation in
                    relationButton(relation: relation, current: current, a: a, b: b)
                }
            }
        }
    }

    private func relationButton(relation: LedgerRelation, current: LedgerRelation?, a: Int, b: Int) -> some View {
        let active = current == relation
        return Button {
            HapticPulse.tap()
            AppAudioConductor.shared.play(.tap)
            session.setLedgerRelation(active ? nil : relation, a: a, b: b)
        } label: {
            Text(relation.symbol)
                .font(RoostFont.bold(22))
                .foregroundStyle(active ? RoostPalette.cream : RoostPalette.barkDark)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(active ? RoostPalette.leafGreen : RoostPalette.parchment)
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(RoostPalette.bark, lineWidth: 2))
                )
        }
        .buttonStyle(RusticButtonStyle())
    }

    private func letterChip(_ index: Int) -> some View {
        Text(HenGlyph.letter(for: index))
            .font(RoostFont.bold(18))
            .foregroundStyle(RoostPalette.cream)
            .frame(width: 34, height: 34)
            .background(Circle().fill(RoostPalette.bark))
    }

    private var eliminatedPanel: some View {
        ParchmentPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("Eliminated")
                    .font(RoostFont.bold(22))
                    .foregroundStyle(RoostPalette.barkDark)
                Text("Tap a hen to rule it out or bring it back.")
                    .font(RoostFont.medium(15))
                    .foregroundStyle(RoostPalette.bark)
                let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<session.level.birdCount, id: \.self) { index in
                        eliminatedChip(index)
                    }
                }
            }
        }
    }

    private func eliminatedChip(_ index: Int) -> some View {
        let eliminated = session.draft.ledger.eliminated.contains(index)
        return Button {
            HapticPulse.tap()
            AppAudioConductor.shared.play(.tap)
            session.toggleEliminated(index)
        } label: {
            VStack(spacing: 2) {
                HenPortrait(index: index, size: 40)
                Text(HenGlyph.letter(for: index))
                    .font(RoostFont.semibold(14))
                    .foregroundStyle(RoostPalette.barkDark)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(eliminated ? RoostPalette.ember.opacity(0.35) : RoostPalette.parchment)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(eliminated ? RoostPalette.ember : RoostPalette.bark, lineWidth: 2))
            )
            .overlay(alignment: .topTrailing) {
                if eliminated {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(RoostPalette.ember)
                        .background(Circle().fill(RoostPalette.cream))
                        .offset(x: 4, y: -4)
                }
            }
        }
        .buttonStyle(RusticButtonStyle())
    }

    private func confirmReset() {
        overlay.present(dismissOnBackdrop: false) {
            ConfirmOverlayCard(
                title: "Reset notes?",
                message: "This clears only your manual ledger marks for this level.",
                confirmTitle: "Reset",
                cancelTitle: "Keep notes",
                confirmKind: .destructive,
                onConfirm: {
                    session.resetNotes()
                    overlay.dismiss()
                },
                onCancel: { overlay.dismiss() }
            )
        }
    }
}

#Preview {
    let prefs = RoostPreferences()
    let vault = ProgressVault(context: PersistenceController.preview.container.viewContext)
    let router = NestRouter()
    let session = YardweighSessionCoordinator(level: OddbirdDeductionRulebook.allLevels[2], vault: vault, prefs: prefs)
    router.activeSession = session
    return NavigationStack {
        ClueScratchpadLedgerView(levelKey: session.level.key)
            .environmentObject(router)
            .environmentObject(vault)
            .environmentObject(prefs)
            .environmentObject(OverlayOrchestrator())
    }
}

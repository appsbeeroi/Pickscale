import SwiftUI
import CoreData

struct AnswerBoardView: View {
    @EnvironmentObject private var router: NestRouter

    let levelKey: String

    var body: some View {
        Group {
            if let session = router.activeSession, session.level.key == levelKey {
                AnswerBoardContent(session: session, answer: session.answerMatrix)
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

private struct AnswerBoardContent: View {
    @ObservedObject var session: YardweighSessionCoordinator
    @ObservedObject var answer: PeckOrderAnswerMatrix
    @EnvironmentObject private var router: NestRouter
    @EnvironmentObject private var overlay: OverlayOrchestrator

    var body: some View {
        ZStack {
            YardBackdrop()

            VStack(spacing: 10) {
                header

                Text(session.level.task.prompt)
                    .font(RoostFont.medium(18))
                    .foregroundStyle(RoostPalette.cream)
                    .multilineTextAlignment(.center)
                    .shadow(color: RoostPalette.dusk.opacity(0.7), radius: 1, x: 0, y: 1)
                    .padding(.horizontal, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        switch session.level.task {
                        case .heaviestHen, .lightOddbird:
                            singleSelectPanel
                        case .fullPeckOrder:
                            peckOrderPanel
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }

                Text("Moves used: \(session.movesUsed)")
                    .font(RoostFont.semibold(18))
                    .foregroundStyle(RoostPalette.cream)
                    .shadow(color: RoostPalette.dusk.opacity(0.7), radius: 1, x: 0, y: 1)

                VStack(spacing: 12) {
                    RusticButton(title: "Review Weighings", kind: .secondary, height: 54, fontSize: 20) {
                        reviewWeighings()
                    }
                    RusticButton(title: "Submit Answer", kind: .primary, height: 62, fontSize: 24, enabled: answer.isSubmittable) {
                        submit()
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
            ScreenTitle(text: "Answer Board", size: 30)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    private var singleSelectPanel: some View {
        ParchmentPanel {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<session.level.birdCount, id: \.self) { index in
                    let selected = isSelected(index)
                    Button {
                        HapticPulse.tap()
                        AppAudioConductor.shared.play(.tap)
                        if session.level.task == .heaviestHen {
                            answer.selectHeaviest(index)
                        } else {
                            answer.selectOddbird(index)
                        }
                    } label: {
                        VStack(spacing: 2) {
                            HenPortrait(index: index, size: 52)
                            Text(HenGlyph.letter(for: index))
                                .font(RoostFont.semibold(15))
                                .foregroundStyle(RoostPalette.barkDark)
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selected ? RoostPalette.leafGreen.opacity(0.35) : RoostPalette.parchment.opacity(0.6))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(selected ? RoostPalette.leafGreen : RoostPalette.bark, lineWidth: selected ? 4 : 2))
                        )
                    }
                    .buttonStyle(RusticButtonStyle())
                }
            }
        }
    }

    private func isSelected(_ index: Int) -> Bool {
        session.level.task == .heaviestHen ? answer.heaviestSelection == index : answer.oddbirdSelection == index
    }

    private var peckOrderPanel: some View {
        VStack(spacing: 12) {
            ParchmentPanel {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Order: lightest → heaviest")
                        .font(RoostFont.bold(20))
                        .foregroundStyle(RoostPalette.barkDark)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if answer.orderedLine.isEmpty {
                                Text("Tap hens below to build the order")
                                    .font(RoostFont.medium(15))
                                    .foregroundStyle(RoostPalette.bark)
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(Array(answer.orderedLine.enumerated()), id: \.element) { pair in
                                    Button {
                                        HapticPulse.tap()
                                        AppAudioConductor.shared.play(.tap)
                                        answer.removeFromLine(pair.element)
                                    } label: {
                                        VStack(spacing: 2) {
                                            Text("\(pair.offset + 1)")
                                                .font(RoostFont.semibold(13))
                                                .foregroundStyle(RoostPalette.bark)
                                            HenPortrait(index: pair.element, size: 46)
                                            Text(HenGlyph.letter(for: pair.element))
                                                .font(RoostFont.semibold(14))
                                                .foregroundStyle(RoostPalette.barkDark)
                                        }
                                        .padding(6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(RoostPalette.sunAmber.opacity(0.35))
                                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(RoostPalette.bark, lineWidth: 2))
                                        )
                                    }
                                    .buttonStyle(RusticButtonStyle())
                                }
                            }
                        }
                        .frame(minHeight: 92)
                    }
                }
            }

            ParchmentPanel {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Remaining hens")
                        .font(RoostFont.bold(20))
                        .foregroundStyle(RoostPalette.barkDark)
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
                    if answer.pool.isEmpty {
                        Text("All hens placed")
                            .font(RoostFont.medium(15))
                            .foregroundStyle(RoostPalette.bark)
                    } else {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(answer.pool, id: \.self) { index in
                                Button {
                                    HapticPulse.tap()
                                    AppAudioConductor.shared.play(.place)
                                    answer.placeIntoLine(index)
                                } label: {
                                    VStack(spacing: 2) {
                                        HenPortrait(index: index, size: 48)
                                        Text(HenGlyph.letter(for: index))
                                            .font(RoostFont.semibold(14))
                                            .foregroundStyle(RoostPalette.barkDark)
                                    }
                                    .padding(6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(RoostPalette.parchment.opacity(0.6))
                                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(RoostPalette.bark, lineWidth: 2))
                                    )
                                }
                                .buttonStyle(RusticButtonStyle())
                            }
                        }
                    }
                }
            }
        }
    }

    private func submit() {
        if let payload = session.submit() {
            if session.isTutorial {
                overlay.present(dismissOnBackdrop: false) {
                    MessageOverlayCard(
                        title: "Tutorial Complete!",
                        message: "You read the scales like a pro. Ready for the campaign?",
                        imageAsset: "icon_pickscale",
                        buttonTitle: "Done"
                    ) {
                        overlay.dismiss()
                        router.popTo(.howToPlay)
                    }
                }
            } else {
                router.path = [.packs, .roundResult(payload)]
            }
        } else {
            overlay.present {
                MessageOverlayCard(
                    title: "Not quite",
                    message: "Revisit your clues and try a different deduction.",
                    imageAsset: "decor_clue_nail",
                    buttonTitle: "Keep Trying"
                ) {
                    overlay.dismiss()
                }
            }
        }
    }

    private func reviewWeighings() {
        overlay.present {
            WeighingReviewCard(history: session.draft.history) {
                overlay.dismiss()
            }
        }
    }
}

struct WeighingReviewCard: View {
    let history: [FlockComparison]
    let onDismiss: () -> Void

    var body: some View {
        ParchmentPanel(padding: 20) {
            VStack(spacing: 12) {
                Text("Weighings")
                    .font(RoostFont.bold(26))
                    .foregroundStyle(RoostPalette.barkDark)
                if history.isEmpty {
                    Text("No weighings recorded.")
                        .font(RoostFont.medium(18))
                        .foregroundStyle(RoostPalette.bark)
                        .padding(.vertical, 10)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(Array(history.enumerated()), id: \.element.id) { pair in
                                HStack {
                                    Text("#\(pair.offset + 1)")
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
                    .frame(maxHeight: 280)
                }
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
    let prefs = RoostPreferences()
    let vault = ProgressVault(context: PersistenceController.preview.container.viewContext)
    let router = NestRouter()
    let session = YardweighSessionCoordinator(level: OddbirdDeductionRulebook.allLevels.first(where: { $0.task == .fullPeckOrder }) ?? OddbirdDeductionRulebook.allLevels[0], vault: vault, prefs: prefs)
    router.activeSession = session
    return NavigationStack {
        AnswerBoardView(levelKey: session.level.key)
            .environmentObject(router)
            .environmentObject(vault)
            .environmentObject(prefs)
            .environmentObject(OverlayOrchestrator())
    }
}

import SwiftUI
import CoreData

struct NestPackGalleryView: View {
    @EnvironmentObject private var router: NestRouter
    @EnvironmentObject private var vault: ProgressVault
    @EnvironmentObject private var prefs: RoostPreferences

    @State private var expandedPackId: String?

    var body: some View {
        ZStack {
            YardBackdrop()

            VStack(spacing: 12) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(OddbirdDeductionRulebook.packs) { pack in
                            packCard(pack)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { _ = vault.revision }
    }

    private var header: some View {
        ZStack {
            HStack {
                NestBackButton { router.pop() }
                Spacer()
            }
            ScreenTitle(text: "Nest Packs", size: 34)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    private func packCard(_ pack: NestPack) -> some View {
        let unlocked = vault.isPackUnlocked(pack.id)
        let solved = vault.solvedCount(inPack: pack.id)
        let stars = vault.stars(inPack: pack.id)
        let isExpanded = expandedPackId == pack.id

        return VStack(spacing: 12) {
            Button {
                guard unlocked else {
                    HapticPulse.warning()
                    return
                }
                HapticPulse.tap()
                AppAudioConductor.shared.play(.tap)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                    expandedPackId = isExpanded ? nil : pack.id
                }
            } label: {
                HStack(spacing: 14) {
                    Image(pack.coverAsset)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 82, height: 82)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(RoostPalette.bark, lineWidth: 3))
                        .saturation(unlocked ? 1 : 0.15)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pack.title)
                            .font(RoostFont.bold(25))
                            .foregroundStyle(RoostPalette.barkDark)
                        Text("\(OddbirdDeductionRulebook.levelsPerPack) levels")
                            .font(RoostFont.medium(17))
                            .foregroundStyle(RoostPalette.bark)
                        HStack(spacing: 8) {
                            Label("\(solved)/\(OddbirdDeductionRulebook.levelsPerPack)", systemImage: "checkmark.seal.fill")
                                .font(RoostFont.semibold(16))
                                .foregroundStyle(RoostPalette.leafGreen)
                            HStack(spacing: 3) {
                                Image("star_filled").resizable().scaledToFit().frame(width: 16, height: 16)
                                Text("\(stars)")
                                    .font(RoostFont.semibold(16))
                                    .foregroundStyle(RoostPalette.bark)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: unlocked ? (isExpanded ? "chevron.up" : "chevron.down") : "lock.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(RoostPalette.bark)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(RoostPalette.cream.opacity(0.95))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(RoostPalette.bark, lineWidth: 4))
                        .shadow(color: RoostPalette.dusk.opacity(0.3), radius: 6, x: 0, y: 3)
                )
            }
            .buttonStyle(RusticButtonStyle())

            if !unlocked {
                Text("Solve \(OddbirdDeductionRulebook.unlockThreshold) puzzles in the previous pack to unlock.")
                    .font(RoostFont.medium(15))
                    .foregroundStyle(RoostPalette.cream)
                    .multilineTextAlignment(.center)
                    .shadow(color: RoostPalette.dusk.opacity(0.7), radius: 1, x: 0, y: 1)
            }

            if isExpanded && unlocked {
                levelGrid(pack)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func levelGrid(_ pack: NestPack) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(OddbirdDeductionRulebook.levels(in: pack.id)) { level in
                levelTile(level)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RoostPalette.parchment.opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(RoostPalette.bark, lineWidth: 3))
        )
    }

    private func levelTile(_ level: FlockLevel) -> some View {
        let info = vault.record(forKey: level.key)
        let cardAsset = info.isSolved ? "level_card_solved" : "level_card_unlocked"

        return Button {
            HapticPulse.tap()
            AppAudioConductor.shared.play(.tap)
            router.openYard(level: level, vault: vault, prefs: prefs)
        } label: {
            ZStack {
                Image(cardAsset)
                    .resizable()
                    .scaledToFit()
                VStack(spacing: 2) {
                    Text("\(level.ordinal)")
                        .font(RoostFont.bold(30))
                        .foregroundStyle(RoostPalette.barkDark)
                    if info.isSolved {
                        StarStrip(filled: info.stars, size: 13)
                        Text("Best: \(info.bestWeighings)")
                            .font(RoostFont.medium(11))
                            .foregroundStyle(RoostPalette.bark)
                    } else {
                        Text("Not solved")
                            .font(RoostFont.medium(11))
                            .foregroundStyle(RoostPalette.bark)
                    }
                }
                .padding(.top, 6)
            }
            .frame(height: 96)
        }
        .buttonStyle(RusticButtonStyle())
    }
}

#Preview {
    NavigationStack {
        NestPackGalleryView()
            .environmentObject(NestRouter())
            .environmentObject(ProgressVault(context: PersistenceController.preview.container.viewContext))
            .environmentObject(RoostPreferences())
    }
}

import SwiftUI
import CoreData

private enum TaskFilter: String, CaseIterable, Identifiable {
    case all
    case heaviest
    case oddbird
    case peckOrder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .heaviest: return "Heaviest"
        case .oddbird: return "Oddbird"
        case .peckOrder: return "Peck Order"
        }
    }

    var kind: FlockTaskKind? {
        switch self {
        case .all: return nil
        case .heaviest: return .heaviestHen
        case .oddbird: return .lightOddbird
        case .peckOrder: return .fullPeckOrder
        }
    }
}

struct NestpackProgressBarn: View {
    @EnvironmentObject private var router: NestRouter
    @EnvironmentObject private var vault: ProgressVault
    @EnvironmentObject private var prefs: RoostPreferences

    @State private var filter: TaskFilter = .all

    private var totalLevels: Int { OddbirdDeductionRulebook.allLevels.count }

    var body: some View {
        ZStack {
            YardBackdrop()

            VStack(spacing: 12) {
                header

                summaryRow

                filterRow

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if filter == .all {
                            ForEach(OddbirdDeductionRulebook.packs) { pack in
                                packSummary(pack)
                            }
                        } else {
                            filteredLevels
                        }
                        lastSolvedCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
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
            ScreenTitle(text: "Progress Barn", size: 32)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            summaryPill(icon: "star_filled", value: "\(vault.totalStars)", caption: "Total stars")
            summaryPill(icon: nil, value: "\(vault.solvedCount)/\(totalLevels)", caption: "Solved")
        }
        .padding(.horizontal, 18)
    }

    private func summaryPill(icon: String?, value: String, caption: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                if let icon {
                    Image(icon).resizable().scaledToFit().frame(width: 22, height: 22)
                }
                Text(value)
                    .font(RoostFont.bold(24))
                    .foregroundStyle(RoostPalette.barkDark)
            }
            Text(caption)
                .font(RoostFont.medium(14))
                .foregroundStyle(RoostPalette.bark)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RoostPalette.cream.opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(RoostPalette.bark, lineWidth: 3))
        )
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskFilter.allCases) { option in
                    let active = filter == option
                    Button {
                        HapticPulse.tap()
                        AppAudioConductor.shared.play(.tap)
                        withAnimation(.easeOut(duration: 0.2)) { filter = option }
                    } label: {
                        Text(option.title)
                            .font(RoostFont.semibold(17))
                            .foregroundStyle(active ? RoostPalette.cream : RoostPalette.barkDark)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(active ? RoostPalette.leafGreen : RoostPalette.cream.opacity(0.9))
                                    .overlay(Capsule().stroke(RoostPalette.bark, lineWidth: 2))
                            )
                    }
                    .buttonStyle(RusticButtonStyle())
                }
            }
            .padding(.horizontal, 18)
        }
    }

    private func packSummary(_ pack: NestPack) -> some View {
        let solved = vault.solvedCount(inPack: pack.id)
        let stars = vault.stars(inPack: pack.id)
        return HStack(spacing: 14) {
            Image(pack.coverAsset)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(RoostPalette.bark, lineWidth: 3))
            VStack(alignment: .leading, spacing: 4) {
                Text(pack.title)
                    .font(RoostFont.bold(22))
                    .foregroundStyle(RoostPalette.barkDark)
                Text("Solved \(solved)/\(OddbirdDeductionRulebook.levelsPerPack)")
                    .font(RoostFont.medium(16))
                    .foregroundStyle(RoostPalette.bark)
            }
            Spacer()
            HStack(spacing: 3) {
                Image("star_filled").resizable().scaledToFit().frame(width: 18, height: 18)
                Text("\(stars)")
                    .font(RoostFont.semibold(18))
                    .foregroundStyle(RoostPalette.bark)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RoostPalette.cream.opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(RoostPalette.bark, lineWidth: 3))
        )
    }

    private var filteredLevels: some View {
        let levels = OddbirdDeductionRulebook.allLevels.filter { $0.task == filter.kind }
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(levels) { level in
                levelTile(level)
            }
        }
    }

    private func levelTile(_ level: FlockLevel) -> some View {
        let info = vault.record(forKey: level.key)
        let packTitle = OddbirdDeductionRulebook.pack(for: level.packId)?.title ?? ""
        return Button {
            HapticPulse.tap()
            AppAudioConductor.shared.play(.tap)
            if info.isSolved {
                let payload = RoundResultPayload(levelKey: level.key, weighingsUsed: info.bestWeighings, stars: info.stars, newBest: false, readOnly: true)
                router.push(.roundResult(payload))
            } else {
                router.openYard(level: level, vault: vault, prefs: prefs)
            }
        } label: {
            ZStack {
                Image(info.isSolved ? "level_card_solved" : "level_card_unlocked")
                    .resizable()
                    .scaledToFit()
                VStack(spacing: 2) {
                    Text("\(level.ordinal)")
                        .font(RoostFont.bold(26))
                        .foregroundStyle(RoostPalette.barkDark)
                    Text(packTitle.prefix(1))
                        .font(RoostFont.medium(12))
                        .foregroundStyle(RoostPalette.bark)
                    StarStrip(filled: info.stars, size: 12)
                }
                .padding(.top, 4)
            }
            .frame(height: 92)
        }
        .buttonStyle(RusticButtonStyle())
    }

    @ViewBuilder
    private var lastSolvedCard: some View {
        if let key = vault.lastPlayedLevelKey, let level = OddbirdDeductionRulebook.level(forKey: key) {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Image(level.task.iconAsset)
                        .resizable().scaledToFit().frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last puzzle")
                            .font(RoostFont.medium(15))
                            .foregroundStyle(RoostPalette.bark)
                        Text("\(OddbirdDeductionRulebook.pack(for: level.packId)?.title ?? "Tutorial") · Level \(level.ordinal)")
                            .font(RoostFont.bold(19))
                            .foregroundStyle(RoostPalette.barkDark)
                    }
                    Spacer()
                }
                RusticButton(title: "Continue Last Puzzle", kind: .primary, height: 56, fontSize: 21) {
                    router.openYard(level: level, vault: vault, prefs: prefs)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(RoostPalette.parchment.opacity(0.92))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(RoostPalette.bark, lineWidth: 3))
            )
        }
    }
}

#Preview {
    NavigationStack {
        NestpackProgressBarn()
            .environmentObject(NestRouter())
            .environmentObject(ProgressVault(context: PersistenceController.preview.container.viewContext))
            .environmentObject(RoostPreferences())
    }
}

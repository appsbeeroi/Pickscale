import SwiftUI
import CoreData

private struct HowToSection: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
    let isSystemIcon: Bool
}

struct HowToPlayView: View {
    @EnvironmentObject private var router: NestRouter
    @EnvironmentObject private var vault: ProgressVault
    @EnvironmentObject private var prefs: RoostPreferences

    private let sections: [HowToSection] = [
        HowToSection(icon: "result_balanced", title: "The Scale", body: "Place hens on either pan and weigh. The scale reveals only Left heavier, Right heavier, or Balanced — never numbers.", isSystemIcon: false),
        HowToSection(icon: "hourglass", title: "Move Limit", body: "Every weighing costs one move. Plan carefully — thoughtful comparisons beat guessing.", isSystemIcon: true),
        HowToSection(icon: "icon_peck_order", title: "Task Types", body: "Find the Heaviest Hen, spot the Light Oddbird, or restore the Full Peck Order from lightest to heaviest.", isSystemIcon: false),
        HowToSection(icon: "decor_clue_nail", title: "Clue Ledger", body: "Mark hens as heavier, lighter, or equal, and rule out those that cannot be the answer.", isSystemIcon: false),
        HowToSection(icon: "star_filled", title: "Stars", body: "Solve with moves to spare for more stars. Fewer weighings means a brighter result.", isSystemIcon: false)
    ]

    var body: some View {
        ZStack {
            YardBackdrop()

            VStack(spacing: 12) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(sections) { section in
                            sectionCard(section)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                RusticButton(title: "Try Tutorial Level", kind: .primary, height: 60, fontSize: 22) {
                    router.startTutorial(vault: vault, prefs: prefs)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        ZStack {
            HStack {
                NestBackButton { router.pop() }
                Spacer()
            }
            ScreenTitle(text: "How to Play", size: 32)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    private func sectionCard(_ section: HowToSection) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if section.isSystemIcon {
                    Image(systemName: section.icon)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(RoostPalette.leafGreen)
                        .frame(width: 44, height: 44)
                } else {
                    Image(section.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(section.title)
                    .font(RoostFont.bold(22))
                    .foregroundStyle(RoostPalette.barkDark)
                Text(section.body)
                    .font(RoostFont.medium(17))
                    .foregroundStyle(RoostPalette.bark)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RoostPalette.cream.opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(RoostPalette.bark, lineWidth: 3))
        )
    }
}

#Preview {
    NavigationStack {
        HowToPlayView()
            .environmentObject(NestRouter())
            .environmentObject(ProgressVault(context: PersistenceController.preview.container.viewContext))
            .environmentObject(RoostPreferences())
    }
}

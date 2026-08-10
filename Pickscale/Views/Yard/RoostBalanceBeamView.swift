import SwiftUI
import CoreData

struct RoostBalanceBeamView: View {
    @ObservedObject var session: YardweighSessionCoordinator

    @State private var dropTargeting: PanSide?

    var body: some View {
        VStack(spacing: 8) {
            Image(beamAsset)
                .resizable()
                .scaledToFit()
                .frame(height: 116)
                .id(beamAsset)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .animation(.spring(response: 0.5, dampingFraction: 0.65), value: beamAsset)

            HStack(spacing: 12) {
                panZone(.left, hens: session.panLeft)
                panZone(.right, hens: session.panRight)
            }
            .padding(.horizontal, 14)
        }
    }

    private var beamAsset: String {
        switch session.lastVerdict {
        case .leftHeavier: return "balance_scale_2"
        case .rightHeavier: return "balance_scale_3"
        case .balanced, nil: return "balance_scale_1"
        }
    }

    private func panZone(_ side: PanSide, hens: [Int]) -> some View {
        let title = side == .left ? "Left Pan" : "Right Pan"
        let targeting = dropTargeting == side
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

        return VStack(spacing: 6) {
            Text(title)
                .font(RoostFont.semibold(16))
                .foregroundStyle(RoostPalette.cream)
                .shadow(color: RoostPalette.dusk.opacity(0.7), radius: 1, x: 0, y: 1)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(hens, id: \.self) { index in
                    Button {
                        session.removeFromPans(index)
                    } label: {
                        HenTokenChip(index: index, size: 44)
                    }
                    .buttonStyle(RusticButtonStyle())
                }
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .top)
            .padding(8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RoostPalette.bark.opacity(targeting ? 0.72 : 0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(targeting ? RoostPalette.sunAmber : RoostPalette.bark, style: StrokeStyle(lineWidth: 3, dash: hens.isEmpty ? [7, 5] : []))
                )
        )
        .dropDestination(for: String.self) { items, _ in
            var handled = false
            for token in items {
                if let index = Int(token) {
                    session.place(index, on: side)
                    handled = true
                }
            }
            return handled
        } isTargeted: { targeted in
            withAnimation(.easeOut(duration: 0.15)) {
                dropTargeting = targeted ? side : nil
            }
        }
    }
}

#Preview {
    let prefs = RoostPreferences()
    let vault = ProgressVault(context: PersistenceController.preview.container.viewContext)
    let session = YardweighSessionCoordinator(level: OddbirdDeductionRulebook.tutorialLevel, vault: vault, prefs: prefs)
    return ZStack {
        YardBackdrop()
        RoostBalanceBeamView(session: session)
    }
}

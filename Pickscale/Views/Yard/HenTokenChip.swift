import SwiftUI

struct HenTokenChip: View {
    let index: Int
    var size: CGFloat = 58
    var dimmed: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            Image(HenGlyph.asset(for: index))
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
            Text(HenGlyph.letter(for: index))
                .font(RoostFont.bold(15))
                .foregroundStyle(RoostPalette.cream)
                .padding(.horizontal, 8)
                .padding(.vertical, 1)
                .background(
                    Capsule().fill(RoostPalette.bark)
                )
        }
        .opacity(dimmed ? 0.4 : 1.0)
    }
}

#Preview {
    HStack {
        HenTokenChip(index: 0)
        HenTokenChip(index: 1)
        HenTokenChip(index: 2, dimmed: true)
    }
    .padding()
    .background(RoostPalette.leafGreen)
}

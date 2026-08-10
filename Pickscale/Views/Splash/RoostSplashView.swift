import SwiftUI

struct RoostSplashView: View {
    let onFinish: () -> Void

    @State private var rock = false
    @State private var logoPop = false
    @State private var featherDrift = false

    var body: some View {
        ZStack {
            YardBackdrop()

            VStack(spacing: 26) {
                Spacer()

                Image("logo_pickscale")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                    .scaleEffect(logoPop ? 1.0 : 0.86)
                    .opacity(logoPop ? 1 : 0)
                    .shadow(color: RoostPalette.dusk.opacity(0.5), radius: 10, x: 0, y: 6)

                Image("balance_scale_1")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 230)
                    .rotationEffect(.degrees(rock ? 5 : -5), anchor: .top)
                    .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: rock)

                Spacer()

                Text("Weigh the flock. Trust the clues.")
                    .font(RoostFont.medium(22))
                    .foregroundStyle(RoostPalette.cream)
                    .shadow(color: RoostPalette.dusk.opacity(0.8), radius: 2, x: 0, y: 2)
                    .padding(.bottom, 46)
                    .opacity(logoPop ? 1 : 0)
            }
            .padding()

            Image("decor_feather")
                .resizable()
                .scaledToFit()
                .frame(width: 60)
                .rotationEffect(.degrees(featherDrift ? 12 : -8))
                .offset(x: featherDrift ? 120 : -110, y: featherDrift ? -220 : -260)
                .opacity(0.85)
                .animation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true), value: featherDrift)
        }
        .onAppear {
            rock = true
            featherDrift = true
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                logoPop = true
            }
            let delay = Double.random(in: 3.17...6.61)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                onFinish()
            }
        }
    }
}

#Preview {
    RoostSplashView {}
}

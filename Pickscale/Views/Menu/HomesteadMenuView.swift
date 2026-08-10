import SwiftUI
import CoreData

struct HomesteadMenuView: View {
    @EnvironmentObject private var router: NestRouter
    @EnvironmentObject private var vault: ProgressVault
    @EnvironmentObject private var prefs: RoostPreferences

    @State private var breathe = false

    var body: some View {
        ZStack {
            YardBackdrop()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    starBadge
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer(minLength: 4)

                Image("logo_pickscale")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                    .scaleEffect(breathe ? 1.02 : 0.98)
                    .shadow(color: RoostPalette.dusk.opacity(0.5), radius: 10, x: 0, y: 6)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: breathe)

                Text("Weigh wisely. Deduce boldly.")
                    .font(RoostFont.medium(22))
                    .foregroundStyle(RoostPalette.cream)
                    .shadow(color: RoostPalette.dusk.opacity(0.7), radius: 2, x: 0, y: 2)
                    .padding(.top, 2)

                Spacer(minLength: 12)

                VStack(spacing: 16) {
                    RusticButton(title: "Play Campaign", kind: .primary, systemIcon: "play.fill", height: 76, fontSize: 30) {
                        router.push(.packs)
                    }

                    HStack(spacing: 14) {
                        RusticButton(title: "Progress", kind: .secondary, height: 64, fontSize: 22) {
                            router.push(.progressBarn)
                        }
                        RusticButton(title: "How to Play", kind: .secondary, height: 64, fontSize: 22) {
                            router.push(.howToPlay)
                        }
                    }

                    RusticButton(title: "Settings", kind: .secondary, systemIcon: "gearshape.fill", height: 64, fontSize: 24) {
                        router.push(.settings)
                    }
                }
                .padding(.horizontal, 26)

                Spacer(minLength: 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            breathe = true
            _ = vault.revision
            AppAudioConductor.shared.syncPreferences(sound: prefs.soundEffectsEnabled, music: prefs.musicEnabled)
        }
    }

    private var starBadge: some View {
        HStack(spacing: 6) {
            Image("star_filled")
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
            Text("\(vault.totalStars)")
                .font(RoostFont.bold(24))
                .foregroundStyle(RoostPalette.barkDark)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(RoostPalette.cream.opacity(0.94))
                .overlay(Capsule().stroke(RoostPalette.bark, lineWidth: 3))
                .shadow(color: RoostPalette.dusk.opacity(0.4), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    NavigationStack {
        HomesteadMenuView()
            .environmentObject(NestRouter())
            .environmentObject(ProgressVault(context: PersistenceController.preview.container.viewContext))
            .environmentObject(RoostPreferences())
    }
}

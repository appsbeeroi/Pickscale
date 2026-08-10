import SwiftUI
import WebKit
import CoreData

struct SettingsView: View {
    @EnvironmentObject private var router: NestRouter
    @EnvironmentObject private var vault: ProgressVault
    @EnvironmentObject private var prefs: RoostPreferences
    @EnvironmentObject private var overlay: OverlayOrchestrator
    @EnvironmentObject private var stage: AppStageController

    @State private var showPrivacy = false

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return short
    }

    var body: some View {
        ZStack {
            YardBackdrop()

            VStack(spacing: 12) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        togglePanel
                        actionPanel
                        aboutPanel
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPrivacy) {
            PrivacyWebSheet(url: URL(string: "https://www.apple.com"))
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                NestBackButton { router.pop() }
                Spacer()
            }
            ScreenTitle(text: "Settings", size: 34)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    private var togglePanel: some View {
        ParchmentPanel {
            VStack(spacing: 14) {
                toggleRow(title: "Sound Effects", isOn: Binding(
                    get: { prefs.soundEffectsEnabled },
                    set: { newValue in
                        prefs.soundEffectsEnabled = newValue
                        AppAudioConductor.shared.syncPreferences(sound: prefs.soundEffectsEnabled, music: prefs.musicEnabled)
                        if newValue { AppAudioConductor.shared.play(.tap) }
                    }
                ))
                Divider().background(RoostPalette.bark.opacity(0.3))
                toggleRow(title: "Music", isOn: Binding(
                    get: { prefs.musicEnabled },
                    set: { newValue in
                        prefs.musicEnabled = newValue
                        AppAudioConductor.shared.syncPreferences(sound: prefs.soundEffectsEnabled, music: prefs.musicEnabled)
                    }
                ))
            }
        }
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(RoostFont.semibold(21))
                .foregroundStyle(RoostPalette.barkDark)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(RoostPalette.leafGreen)
        }
    }

    private var actionPanel: some View {
        VStack(spacing: 12) {
            RusticButton(title: "Replay Tutorial", kind: .secondary, height: 58, fontSize: 21) {
                prefs.onboardingCompleted = false
                router.popToRoot()
                stage.phase = .onboarding
            }
            RusticButton(title: "Reset All Progress", kind: .destructive, height: 58, fontSize: 21) {
                confirmReset()
            }
        }
    }

    private var aboutPanel: some View {
        ParchmentPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(RoostFont.bold(24))
                    .foregroundStyle(RoostPalette.barkDark)
                Text("Pickscale")
                    .font(RoostFont.semibold(20))
                    .foregroundStyle(RoostPalette.barkDark)
                Text("Version \(appVersion)")
                    .font(RoostFont.medium(16))
                    .foregroundStyle(RoostPalette.bark)
                Text("A quiet farm logic puzzle. Weigh hens on a two-pan scale, track clues, and deduce the answer.")
                    .font(RoostFont.medium(16))
                    .foregroundStyle(RoostPalette.bark)
                    .fixedSize(horizontal: false, vertical: true)
                Label("Plays fully offline. No accounts, ads, or purchases.", systemImage: "wifi.slash")
                    .font(RoostFont.medium(15))
                    .foregroundStyle(RoostPalette.leafGreen)
                Button {
                    HapticPulse.tap()
                    AppAudioConductor.shared.play(.tap)
                    showPrivacy = true
                } label: {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                        Text("Privacy Policy")
                            .font(RoostFont.semibold(18))
                    }
                    .foregroundStyle(RoostPalette.skyBlue)
                }
                .padding(.top, 4)
            }
        }
    }

    private func confirmReset() {
        overlay.present(dismissOnBackdrop: false) {
            ConfirmOverlayCard(
                title: "Reset all progress?",
                message: "This erases stars, best results, solved levels, drafts, and tutorial state. Sound and music stay as they are.",
                confirmTitle: "Reset",
                cancelTitle: "Cancel",
                confirmKind: .destructive,
                onConfirm: {
                    vault.resetEverything()
                    prefs.tutorialCompleted = false
                    HapticPulse.success()
                    overlay.dismiss()
                },
                onCancel: { overlay.dismiss() }
            )
        }
    }
}

struct PrivacyWebSheet: View {
    let url: URL?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let url {
                    RoostWebView(url: url)
                } else {
                    Text("Unable to load page.")
                        .font(RoostFont.medium(18))
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct RoostWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(NestRouter())
            .environmentObject(ProgressVault(context: PersistenceController.preview.container.viewContext))
            .environmentObject(RoostPreferences())
            .environmentObject(OverlayOrchestrator())
            .environmentObject(AppStageController())
    }
}

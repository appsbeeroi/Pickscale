import SwiftUI
import Combine

@MainActor
final class RoostPreferences: ObservableObject {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let onboarding = "pickscale.onboardingCompleted"
        static let sound = "pickscale.soundEffectsEnabled"
        static let music = "pickscale.musicEnabled"
        static let tutorial = "pickscale.tutorialCompleted"
    }

    @Published var onboardingCompleted: Bool {
        didSet { defaults.set(onboardingCompleted, forKey: Keys.onboarding) }
    }

    @Published var soundEffectsEnabled: Bool {
        didSet { defaults.set(soundEffectsEnabled, forKey: Keys.sound) }
    }

    @Published var musicEnabled: Bool {
        didSet { defaults.set(musicEnabled, forKey: Keys.music) }
    }

    @Published var tutorialCompleted: Bool {
        didSet { defaults.set(tutorialCompleted, forKey: Keys.tutorial) }
    }

    init() {
        if defaults.object(forKey: Keys.sound) == nil {
            defaults.set(true, forKey: Keys.sound)
        }
        if defaults.object(forKey: Keys.music) == nil {
            defaults.set(true, forKey: Keys.music)
        }
        onboardingCompleted = defaults.bool(forKey: Keys.onboarding)
        soundEffectsEnabled = defaults.bool(forKey: Keys.sound)
        musicEnabled = defaults.bool(forKey: Keys.music)
        tutorialCompleted = defaults.bool(forKey: Keys.tutorial)
    }
}

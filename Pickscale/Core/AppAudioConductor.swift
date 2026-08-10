import AVFoundation

enum RoostSound: String, CaseIterable {
    case tap = "sfx_tap"
    case weigh = "sfx_weigh"
    case correct = "sfx_correct"
    case wrong = "sfx_wrong"
    case star = "sfx_star"
    case place = "sfx_place"
}

@MainActor
final class AppAudioConductor {
    static let shared = AppAudioConductor()

    private var musicPlayer: AVAudioPlayer?
    private var effectPlayers: [RoostSound: AVAudioPlayer] = [:]
    private var sessionConfigured = false

    var soundEffectsEnabled = true
    var musicEnabled = true

    private init() {}

    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    func syncPreferences(sound: Bool, music: Bool) {
        soundEffectsEnabled = sound
        musicEnabled = music
        if music {
            startMusic()
        } else {
            stopMusic()
        }
    }

    func startMusic() {
        guard musicEnabled else { return }
        configureSessionIfNeeded()
        if musicPlayer == nil {
            guard let url = Self.url(for: "music_loop") else { return }
            musicPlayer = try? AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = 0.35
            musicPlayer?.prepareToPlay()
        }
        if musicPlayer?.isPlaying == false {
            musicPlayer?.play()
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
    }

    func play(_ sound: RoostSound) {
        guard soundEffectsEnabled else { return }
        configureSessionIfNeeded()
        if let player = effectPlayers[sound] {
            player.currentTime = 0
            player.play()
            return
        }
        guard let url = Self.url(for: sound.rawValue) else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = 0.7
        player.prepareToPlay()
        effectPlayers[sound] = player
        player.play()
    }

    private static func url(for name: String) -> URL? {
        for ext in ["wav", "m4a", "caf", "mp3"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}

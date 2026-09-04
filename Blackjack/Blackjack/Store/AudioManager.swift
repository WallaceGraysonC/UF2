import AVFoundation
import Combine
import Foundation

/// Background theme music. Off by default on a fresh install -- a game that
/// starts making noise the first time you open it is a game people mute at
/// the system level and never unmute, so this waits to be asked for.
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    /// 0 is silent, 1 is full. Persisted per device: how loud you want a
    /// game is about where you are, not which account you're signed into,
    /// so this deliberately doesn't ride along on the iCloud sync.
    @Published var musicVolume: Double {
        didSet {
            guard musicVolume != oldValue else { return }
            defaults.set(musicVolume, forKey: Keys.musicVolume)
            apply()
        }
    }

    private var player: AVAudioPlayer?
    private let defaults = UserDefaults.standard
    private enum Keys { static let musicVolume = "audio.musicVolume" }

    private init() {
        musicVolume = defaults.object(forKey: Keys.musicVolume) as? Double ?? 0
    }

    /// Call once the UI is up. Loads nothing at all while the music is off,
    /// so the default install pays no launch cost for a feature it isn't using.
    func startIfEnabled() {
        guard musicVolume > 0 else { return }
        apply()
    }

    private func apply() {
        guard musicVolume > 0 else {
            player?.pause()
            return
        }
        if player == nil { loadPlayer() }
        player?.volume = Float(musicVolume)
        if player?.isPlaying == false { player?.play() }
    }

    private func loadPlayer() {
        guard let url = Bundle.main.url(forResource: "BlackjackTheme", withExtension: "wav") else { return }
        // `.ambient` + `.mixWithOthers`: never interrupt whatever the player
        // already had going, and stay quiet when the ring switch is off.
        // Background music in a card game is a garnish, not the main course.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        player = try? AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1
        player?.volume = Float(musicVolume)
        player?.prepareToPlay()
    }
}

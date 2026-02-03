import Foundation
import AVFoundation

/// Identifiers for all game sound effects.
public enum SoundEffect: String, CaseIterable {
    case start
    case bip
    case fail
}

public enum SoundPreferences {
    public static let volumeKey = "sfxVolume"
    public static let defaultVolume: Double = 0.8
}

/// Abstract audio player used by the shared game logic.
/// Implementations must be thread-safe enough for main-thread calls from SpriteKit.
public protocol SoundEffectPlayer: Sendable {
    /// Plays the given effect. When provided, `completion` executes after playback finishes.
    func play(_ effect: SoundEffect, completion: (() -> Void)?)
    /// Stops all sounds. A short fade keeps the UX soft when leaving the game.
    func stopAll(fadeDuration: TimeInterval)
    /// Sets global SFX volume (0.0...1.0). Implementations clamp as needed.
    func setVolume(_ volume: Double)
}

/// AVFoundation-backed implementation stored in the shared framework.
/// Loads audio files from the bundle passed in at init.
public final class AVSoundEffectPlayer: NSObject, SoundEffectPlayer, AVAudioPlayerDelegate, @unchecked Sendable {
    private let bundle: Bundle
    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private let queue = DispatchQueue(label: "com.retroracing.soundplayer")
    private var volume: Float = 0.8

    public init(bundle: Bundle) {
        self.bundle = bundle
        super.init()
        preloadPlayers()
    }

    public func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        queue.async { [weak self] in
            guard let self else { return }
            guard let player = self.players[effect] else { return }
            player.currentTime = 0
            player.volume = self.volume
            player.delegate = completion == nil ? nil : self
            if let completion {
                let key = ObjectIdentifier(player)
                self.completions[key] = completion
            }
            player.play()
        }
    }

    public func stopAll(fadeDuration: TimeInterval) {
        queue.async { [weak self] in
            guard let self else { return }
            let duration = max(0, fadeDuration)
            for player in self.players.values where player.isPlaying {
                // Do not fire completion when manually stopping; leave paused state unchanged.
                self.completions.removeValue(forKey: ObjectIdentifier(player))
                if duration == 0 {
                    player.stop()
                } else {
                    self.fadeOutAndStop(player: player, duration: duration)
                }
            }
        }
    }

    public func setVolume(_ volume: Double) {
        queue.async { [weak self] in
            guard let self else { return }
            self.volume = Float(min(max(volume, 0), 1))
        }
    }

    // MARK: - Private

    private var completions: [ObjectIdentifier: (() -> Void)] = [:]

    private func preloadPlayers() {
        for effect in SoundEffect.allCases {
            guard let url = bundle.url(forResource: effect.rawValue, withExtension: "m4a", subdirectory: "Resources/Audio")
                    ?? bundle.url(forResource: effect.rawValue, withExtension: "m4a", subdirectory: "Audio")
                    ?? bundle.url(forResource: effect.rawValue, withExtension: "m4a") else {
                continue
            }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[effect] = player
            }
        }
    }

    private func fadeOutAndStop(player: AVAudioPlayer, duration: TimeInterval) {
        let steps = 10
        let stepDuration = duration / Double(steps)
        let originalVolume = player.volume
        for i in 0..<steps {
            queue.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                guard let self else { return }
                let fraction = Float(1.0 - Double(i) / Double(steps))
                player.volume = originalVolume * fraction
                if i == steps - 1 {
                    player.stop()
                    player.volume = self.volume
                }
            }
        }
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let key = ObjectIdentifier(player)
        let completion = queue.sync { completions.removeValue(forKey: key) }
        completion?()
    }
}

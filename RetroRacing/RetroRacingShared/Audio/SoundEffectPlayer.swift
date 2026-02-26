import Foundation

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
/// Implementations are invoked from the SpriteKit loop; keep them lightweight and cancellation-friendly.
public protocol SoundEffectPlayer {
    /// Plays the given effect. When provided, `completion` executes after playback finishes.
    func play(_ effect: SoundEffect, completion: (() -> Void)?)
    /// Stops all sounds. A short fade keeps the UX soft when leaving the game.
    func stopAll(fadeDuration: TimeInterval)
    /// Sets global SFX volume (0.0...1.0). Implementations clamp as needed.
    func setVolume(_ volume: Double)
}

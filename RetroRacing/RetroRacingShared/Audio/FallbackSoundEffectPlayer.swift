import Foundation

/// Routes playback through the primary player whenever possible and falls back to assets when unavailable.
public final class FallbackSoundEffectPlayer: SoundEffectPlayer {
    private let primary: SoundEffectPlayer
    private let fallback: SoundEffectPlayer

    public init(primary: SoundEffectPlayer, fallback: SoundEffectPlayer) {
        self.primary = primary
        self.fallback = fallback
    }

    public func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        if canUsePrimary(for: effect) {
            primary.play(effect, completion: completion)
            return
        }

        AppLog.info(AppLog.sound, "🔊 Falling back to bundled SFX asset for \(effect.rawValue)")
        fallback.play(effect, completion: completion)
    }

    public func stopAll(fadeDuration: TimeInterval) {
        primary.stopAll(fadeDuration: fadeDuration)
        fallback.stopAll(fadeDuration: fadeDuration)
    }

    public func setVolume(_ volume: Double) {
        primary.setVolume(volume)
        fallback.setVolume(volume)
    }

    private func canUsePrimary(for effect: SoundEffect) -> Bool {
        guard let availabilityProvider = primary as? GeneratedSFXAvailabilityProviding else {
            return true
        }
        return availabilityProvider.canPlay(effect)
    }
}

import Foundation
import AVFoundation

/// Generated SoundEffectPlayer backed by AVAudioEngine and precomputed PCM buffers.
public final class AVGeneratedSoundEffectPlayer: SoundEffectPlayer {
    private let graph: GeneratedSFXPlaybackGraph

    // MARK: - Internal test hooks
    var _testForceStartEngineFailure: Bool {
        get { graph.testForceStartEngineFailure }
        set { graph.testForceStartEngineFailure = newValue }
    }

    public init(sampleRate: Double = 44_100, profile: GeneratedSFXProfile = .defaultProfile) {
        self.graph = GeneratedSFXPlaybackGraph(
            sampleRate: sampleRate,
            profile: profile,
            initialVolume: Float(SoundPreferences.defaultVolume)
        )
    }

    public func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.play(effect, completion: completion)
            }
            return
        }
        graph.play(effect, completion: completion)
    }

    public func stopAll(fadeDuration: TimeInterval) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.stopAll(fadeDuration: fadeDuration)
            }
            return
        }
        graph.stopAll(fadeDuration: fadeDuration)
    }

    public func setVolume(_ volume: Double) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.setVolume(volume)
            }
            return
        }
        graph.setVolume(volume)
    }

    // MARK: - Internal test hooks

    var _testAvailableEffects: Set<SoundEffect> { graph.testAvailableEffects }

    func _testFrameCount(for effect: SoundEffect) -> AVAudioFrameCount? {
        graph.testFrameCount(for: effect)
    }

    func _testIsPlaying(effect: SoundEffect) -> Bool {
        graph.testIsPlaying(effect: effect)
    }

    var _testCurrentVolume: Float { graph.testCurrentVolume }

    func _testNodeVolume(effect: SoundEffect) -> Float? {
        graph.testNodeVolume(effect: effect)
    }

    var _testPlaybackSkippedCount: Int { graph.testPlaybackSkippedCount }
    var _testGraphRebuildCount: Int { graph.testGraphRebuildCount }
    var _testEngineRestartAttemptCount: Int { graph.testEngineRestartAttemptCount }
    var _testEngineRestartSuccessCount: Int { graph.testEngineRestartSuccessCount }
    var _testEngineRestartFailureCount: Int { graph.testEngineRestartFailureCount }

    func _testMarkGraphDirty() {
        if Thread.isMainThread {
            graph.markGraphDirtyForTesting()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.graph.markGraphDirtyForTesting()
            }
        }
    }
}

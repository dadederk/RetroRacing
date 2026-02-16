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

// Minimal surface for AVAudioPlayer to allow mocking in tests.
protocol AudioPlayer: AnyObject {
    var isPlaying: Bool { get }
    var volume: Float { get set }
    var currentTime: TimeInterval { get set }
    var delegate: AVAudioPlayerDelegate? { get set }
    var objectID: ObjectIdentifier { get }

    func prepareToPlay()
    func play()
    func stop()
}

/// Wrapper that exposes only the minimal API we need and aligns identity with the underlying AVAudioPlayer.
private final class AVAudioPlayerBox: AudioPlayer {
    private let player: AVAudioPlayer

    init?(url: URL) {
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return nil }
        self.player = p
    }

    var isPlaying: Bool { player.isPlaying }
    var volume: Float {
        get { player.volume }
        set { player.volume = newValue }
    }
    var currentTime: TimeInterval {
        get { player.currentTime }
        set { player.currentTime = newValue }
    }
    var delegate: AVAudioPlayerDelegate? {
        get { player.delegate }
        set { player.delegate = newValue }
    }
    var objectID: ObjectIdentifier { ObjectIdentifier(player) }

    func prepareToPlay() { player.prepareToPlay() }
    func play() { player.play() }
    func stop() { player.stop() }

    var underlyingPlayer: AVAudioPlayer { player }
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

/// Internal worker actor so the public API remains synchronous while playback state stays thread-safe.
private actor SoundEffectPlayerActor {
    private struct PlayerPool {
        var players: [AudioPlayer]
        var nextIndex: Int = 0
    }

    private var pools: [SoundEffect: PlayerPool] = [:]
    private var completions: [ObjectIdentifier: (() -> Void)] = [:]

    init(bundle: Bundle, playerFactory: (URL) -> AudioPlayer?) {
        pools = Self.loadPools(bundle: bundle, playerFactory: playerFactory)
    }

    init(players: [SoundEffect: AudioPlayer]) {
        pools = players.reduce(into: [SoundEffect: PlayerPool]()) { result, entry in
            result[entry.key] = PlayerPool(players: [entry.value])
        }
    }

    func prepareAndPlay(
        _ effect: SoundEffect,
        delegate: AVAudioPlayerDelegate,
        volume: Float,
        completion: (() -> Void)?
    ) {
        guard var pool = pools[effect], !pool.players.isEmpty else { return }
        let playerIndex = selectPlayerIndex(in: pool)
        let player = pool.players[playerIndex]
        completions.removeValue(forKey: player.objectID)
        player.currentTime = 0
        player.volume = volume
        player.delegate = completion == nil ? nil : delegate
        if let completion {
            completions[player.objectID] = completion
        }
        player.play()
        pool.nextIndex = (playerIndex + 1) % pool.players.count
        pools[effect] = pool
    }

    func finish(for player: AVAudioPlayer) -> (() -> Void)? {
        completions.removeValue(forKey: ObjectIdentifier(player))
    }

    func invokeCompletion(for effect: SoundEffect) -> (() -> Void)? {
        guard let pool = pools[effect] else { return nil }
        for player in pool.players {
            if let completion = completions.removeValue(forKey: player.objectID) {
                return completion
            }
        }
        return nil
    }

    func stopAll(fadeDuration: TimeInterval, targetVolume: Float) async {
        let duration = max(0, fadeDuration)
        for player in pools.values.flatMap(\.players) where player.isPlaying {
            completions.removeValue(forKey: ObjectIdentifier(player))
            if duration == 0 {
                player.stop()
                continue
            }
            await fadeOutAndStop(player: player, duration: duration, targetVolume: targetVolume)
        }
    }

    // MARK: - Private helpers

    private static func loadPools(bundle: Bundle, playerFactory: (URL) -> AudioPlayer?) -> [SoundEffect: PlayerPool] {
        var result: [SoundEffect: PlayerPool] = [:]
        for effect in SoundEffect.allCases {
            guard let url = bundle.url(forResource: effect.rawValue, withExtension: "m4a", subdirectory: "Resources/Audio")
                    ?? bundle.url(forResource: effect.rawValue, withExtension: "Audio")
                    ?? bundle.url(forResource: effect.rawValue, withExtension: "m4a") else {
                continue
            }

            var players = [AudioPlayer]()
            for _ in 0..<poolSize(for: effect) {
                guard let player = playerFactory(url) else { continue }
                player.prepareToPlay()
                players.append(player)
            }

            if !players.isEmpty {
                result[effect] = PlayerPool(players: players)
            }
        }
        return result
    }

    private static func poolSize(for effect: SoundEffect) -> Int {
        switch effect {
        case .bip:
            return 4
        case .start, .fail:
            return 1
        }
    }

    private func selectPlayerIndex(in pool: PlayerPool) -> Int {
        let count = pool.players.count
        guard count > 0 else { return 0 }
        for offset in 0..<count {
            let index = (pool.nextIndex + offset) % count
            if pool.players[index].isPlaying == false {
                return index
            }
        }
        return pool.nextIndex % count
    }

    private func fadeOutAndStop(player: AudioPlayer, duration: TimeInterval, targetVolume: Float) async {
        let steps = 10
        let stepDuration = duration / Double(steps)
        let originalVolume = player.volume
        for i in 0..<steps {
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
            let fraction = Float(1.0 - Double(i) / Double(steps))
            player.volume = originalVolume * fraction
        }
        player.stop()
        player.volume = targetVolume
    }
}

/// AVFoundation-backed implementation stored in the shared framework.
/// Loads audio files from the bundle passed in at init.
public final class AVSoundEffectPlayer: NSObject, SoundEffectPlayer, AVAudioPlayerDelegate {
        private let worker: SoundEffectPlayerActor
        private var volume: Float = Float(SoundPreferences.defaultVolume)

        public init(bundle: Bundle) {
            self.worker = SoundEffectPlayerActor(bundle: bundle) { url in
                AVAudioPlayerBox(url: url)
            }
            super.init()
        }

    /// Internal test-only initializer that bypasses bundle loading.
    init(testPlayers: [SoundEffect: AudioPlayer]) {
        self.worker = SoundEffectPlayerActor(players: testPlayers)
        super.init()
    }

    public func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        let currentVolume = volume
        Task { [worker] in
            await worker.prepareAndPlay(effect, delegate: self, volume: currentVolume, completion: completion)
        }
    }

    public func stopAll(fadeDuration: TimeInterval) {
        let currentVolume = volume
        Task { [worker] in
            await worker.stopAll(fadeDuration: fadeDuration, targetVolume: currentVolume)
        }
    }

    public func setVolume(_ volume: Double) {
        self.volume = Float(min(max(volume, 0), 1))
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { [worker] in
            if let completion = await worker.finish(for: player) {
                await MainActor.run {
                    completion()
                }
            }
        }
    }

    /// Test-only helper: triggers completion for the given effect without relying on AVAudioPlayer callbacks.
    @discardableResult
    func _testComplete(effect: SoundEffect) async -> Bool {
        if let completion = await worker.invokeCompletion(for: effect) {
            await MainActor.run {
                completion()
            }
            return true
        }
        return false
    }
}

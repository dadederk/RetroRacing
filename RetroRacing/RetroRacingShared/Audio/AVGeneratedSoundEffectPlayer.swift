import Foundation
import AVFoundation

private final class GeneratedSFXPlaybackSlot {
    let node: AVAudioPlayerNode
    var token: UInt64 = 0
    var completion: (() -> Void)?
    var completionTask: Task<Void, Never>?

    init(node: AVAudioPlayerNode) {
        self.node = node
    }
}

private struct GeneratedSFXEffectPool {
    var slots: [GeneratedSFXPlaybackSlot]
    let buffer: AVAudioPCMBuffer
    let duration: TimeInterval
    var nextIndex: Int = 0
}

enum GeneratedSFXRenderer {
    static func makeBuffer(recipe: GeneratedSFXRecipe, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let segmentFrames = recipe.expandedSegments.map { segment in
            max(1, Int((segment.duration * sampleRate).rounded()))
        }
        let totalFrames = segmentFrames.reduce(0, +)

        guard totalFrames > 0,
              let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(totalFrames)
              ),
              let channel = buffer.floatChannelData?[0] else {
            return nil
        }

        buffer.frameLength = AVAudioFrameCount(totalFrames)
        for sampleIndex in 0..<totalFrames {
            channel[sampleIndex] = 0
        }

        var globalIndex = 0
        for (segment, frameCount) in zip(recipe.expandedSegments, segmentFrames) {
            let attackFrames = max(1, Int((segment.attack * sampleRate).rounded()))
            let decayFrames = max(1, Int((segment.decay * sampleRate).rounded()))
            let sustainFrames = max(0, frameCount - attackFrames - decayFrames)
            var phase = 0.0

            for localIndex in 0..<frameCount {
                let progress = frameCount > 1 ? Double(localIndex) / Double(frameCount - 1) : 1
                let frequency = segment.frequency.value(at: progress)
                phase += frequency / sampleRate
                let wave = waveformValue(waveform: segment.waveform, phase: phase)
                let envelope = envelopeValue(
                    sampleIndex: localIndex,
                    totalSamples: frameCount,
                    attackSamples: attackFrames,
                    decaySamples: decayFrames,
                    sustainSamples: sustainFrames
                )
                let sample = wave * segment.amplitude * envelope
                channel[globalIndex] = Float(min(max(sample, -1), 1))
                globalIndex += 1
            }
        }

        return buffer
    }

    private static func waveformValue(waveform: GeneratedSFXWaveform, phase: Double) -> Double {
        let wrappedPhase = phase.truncatingRemainder(dividingBy: 1)
        switch waveform {
        case .sine:
            return sin(2.0 * .pi * wrappedPhase)
        case .triangle:
            return (4.0 * abs(wrappedPhase - 0.5)) - 1.0
        case .square:
            return wrappedPhase < 0.5 ? 1.0 : -1.0
        }
    }

    private static func envelopeValue(
        sampleIndex: Int,
        totalSamples: Int,
        attackSamples: Int,
        decaySamples: Int,
        sustainSamples: Int
    ) -> Double {
        guard totalSamples > 0 else { return 0 }
        if sampleIndex < attackSamples {
            return Double(sampleIndex) / Double(max(1, attackSamples))
        }
        if sampleIndex < attackSamples + sustainSamples {
            return 1.0
        }

        let decayIndex = sampleIndex - attackSamples - sustainSamples
        return max(0.0, 1.0 - (Double(decayIndex) / Double(max(1, decaySamples))))
    }
}

/// Generated SoundEffectPlayer backed by AVAudioEngine and precomputed PCM buffers.
public final class AVGeneratedSoundEffectPlayer: SoundEffectPlayer {
    private let engine = AVAudioEngine()
    private let format: AVAudioFormat?
    private let profile: GeneratedSFXProfile

    private var pools: [SoundEffect: GeneratedSFXEffectPool] = [:]
    private var availableEffects = Set<SoundEffect>()
    private var volume: Float = Float(SoundPreferences.defaultVolume)
    private var fadeTask: Task<Void, Never>?
    private var engineHealthy = true

    public init(sampleRate: Double = 44_100, profile: GeneratedSFXProfile = .defaultProfile) {
        self.profile = profile
        self.format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        buildPools()
    }

    deinit {
        fadeTask?.cancel()
        cancelAllCompletionTasks()
    }

    public func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        guard isPlaybackReady(for: effect), var pool = pools[effect], pool.slots.isEmpty == false else {
            return
        }

        fadeTask?.cancel()
        let slotIndex = selectSlotIndex(in: pool)
        let slot = pool.slots[slotIndex]
        slot.token &+= 1
        let token = slot.token
        slot.completionTask?.cancel()
        slot.completionTask = nil
        slot.completion = completion

        slot.node.stop()
        slot.node.volume = volume
        slot.node.scheduleBuffer(pool.buffer, at: nil, options: [.interrupts], completionHandler: nil)
        if slot.node.isPlaying == false {
            slot.node.play()
        }

        if completion != nil {
            slot.completionTask = Task { [weak self] in
                let delay = max(pool.duration, 0)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard Task.isCancelled == false else { return }
                guard let self else { return }
                await MainActor.run {
                    self.completeIfCurrent(effect: effect, slotIndex: slotIndex, token: token)
                }
            }
        }

        pool.nextIndex = (slotIndex + 1) % pool.slots.count
        pools[effect] = pool
    }

    public func stopAll(fadeDuration: TimeInterval) {
        fadeTask?.cancel()
        let duration = max(0, fadeDuration)
        guard duration > 0 else {
            stopImmediately()
            return
        }

        let startVolume = volumeForActiveNodes()
        let targetVolume = volume
        fadeTask = Task { [weak self] in
            guard let self else { return }
            let steps = 10
            let stepDuration = duration / Double(steps)

            for step in 0..<steps {
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                guard Task.isCancelled == false else { return }
                let fraction = Float(1.0 - (Double(step + 1) / Double(steps)))
                await MainActor.run {
                    self.setNodeVolumes(startVolume * fraction)
                }
            }

            await MainActor.run {
                self.stopImmediately()
                self.setNodeVolumes(targetVolume)
            }
        }
    }

    public func setVolume(_ volume: Double) {
        self.volume = Float(min(max(volume, 0), 1))
        setNodeVolumes(self.volume)
    }

    // MARK: - Internal test hooks

    var _testAvailableEffects: Set<SoundEffect> { availableEffects }

    func _testFrameCount(for effect: SoundEffect) -> AVAudioFrameCount? {
        pools[effect]?.buffer.frameLength
    }

    func _testIsPlaying(effect: SoundEffect) -> Bool {
        guard let pool = pools[effect] else { return false }
        return pool.slots.contains { $0.node.isPlaying }
    }

    var _testCurrentVolume: Float { volume }

    func _testNodeVolume(effect: SoundEffect) -> Float? {
        pools[effect]?.slots.first?.node.volume
    }

    // MARK: - Private

    private func buildPools() {
        guard let format else {
            engineHealthy = false
            AppLog.error(AppLog.sound, "🔊 Generated SFX unavailable: invalid audio format")
            return
        }

        for effect in SoundEffect.allCases {
            let recipe = profile.recipe(for: effect)
            guard let buffer = GeneratedSFXRenderer.makeBuffer(recipe: recipe, format: format) else {
                AppLog.error(AppLog.sound, "🔊 Failed to render generated SFX buffer for \(effect.rawValue)")
                continue
            }

            let slots = makeSlots(for: effect, format: format)
            guard slots.isEmpty == false else {
                AppLog.error(AppLog.sound, "🔊 Failed to create playback slots for \(effect.rawValue)")
                continue
            }

            pools[effect] = GeneratedSFXEffectPool(
                slots: slots,
                buffer: buffer,
                duration: recipe.duration,
                nextIndex: 0
            )
            availableEffects.insert(effect)
        }

        guard availableEffects.isEmpty == false else {
            engineHealthy = false
            AppLog.error(AppLog.sound, "🔊 Generated SFX unavailable: no playable effects")
            return
        }

        _ = startEngineIfNeeded()
    }

    private func makeSlots(for effect: SoundEffect, format: AVAudioFormat) -> [GeneratedSFXPlaybackSlot] {
        var slots: [GeneratedSFXPlaybackSlot] = []
        for _ in 0..<poolSize(for: effect) {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            node.volume = volume
            slots.append(GeneratedSFXPlaybackSlot(node: node))
        }
        return slots
    }

    private func poolSize(for effect: SoundEffect) -> Int {
        switch effect {
        case .bip:
            return 4
        case .start, .fail:
            return 1
        }
    }

    private func selectSlotIndex(in pool: GeneratedSFXEffectPool) -> Int {
        let count = pool.slots.count
        guard count > 0 else { return 0 }
        for offset in 0..<count {
            let candidate = (pool.nextIndex + offset) % count
            if pool.slots[candidate].node.isPlaying == false {
                return candidate
            }
        }
        return pool.nextIndex % count
    }

    private func isPlaybackReady(for effect: SoundEffect) -> Bool {
        guard availableEffects.contains(effect) else { return false }
        return startEngineIfNeeded()
    }

    @discardableResult
    private func startEngineIfNeeded() -> Bool {
        guard engineHealthy else { return false }
        guard engine.isRunning == false else { return true }
        do {
            try engine.start()
            return true
        } catch {
            engineHealthy = false
            AppLog.error(AppLog.sound, "🔊 Generated SFX engine failed to start: \(error.localizedDescription)")
            return false
        }
    }

    private func completeIfCurrent(effect: SoundEffect, slotIndex: Int, token: UInt64) {
        guard let pool = pools[effect], slotIndex < pool.slots.count else { return }
        let slot = pool.slots[slotIndex]
        guard slot.token == token else { return }
        slot.completionTask = nil
        let completion = slot.completion
        slot.completion = nil
        pools[effect] = pool
        completion?()
    }

    private func stopImmediately() {
        cancelAllCompletionTasks()
        for pool in pools.values {
            for slot in pool.slots {
                slot.node.stop()
            }
        }
    }

    private func cancelAllCompletionTasks() {
        for pool in pools.values {
            for slot in pool.slots {
                slot.completionTask?.cancel()
                slot.completionTask = nil
                slot.completion = nil
                slot.token &+= 1
            }
        }
    }

    private func setNodeVolumes(_ volume: Float) {
        for pool in pools.values {
            for slot in pool.slots {
                slot.node.volume = volume
            }
        }
    }

    private func volumeForActiveNodes() -> Float {
        for pool in pools.values {
            for slot in pool.slots where slot.node.isPlaying {
                return slot.node.volume
            }
        }
        return volume
    }
}

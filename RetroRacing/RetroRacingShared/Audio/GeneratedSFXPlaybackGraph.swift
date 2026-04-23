//
//  GeneratedSFXPlaybackGraph.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 21/04/2026.
//

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

final class GeneratedSFXPlaybackGraph {
    private var engine = AVAudioEngine()
    private let format: AVAudioFormat?
    private let profile: GeneratedSFXProfile

    private var pools: [SoundEffect: GeneratedSFXEffectPool] = [:]
    private var availableEffects = Set<SoundEffect>()
    private var volume: Float
    private var fadeTask: Task<Void, Never>?
    private var engineHealthy = true
    private var needsGraphRebuild = false
    private var graphRebuildCount = 0
    private var engineRestartAttemptCount = 0
    private var engineRestartSuccessCount = 0
    private var engineRestartFailureCount = 0
    private var playbackSkippedCount = 0
    private var audioSessionObserverTokens: [NSObjectProtocol] = []
    private var engineObserverToken: NSObjectProtocol?

    var testForceStartEngineFailure = false

    init(sampleRate: Double, profile: GeneratedSFXProfile, initialVolume: Float) {
        self.profile = profile
        self.volume = initialVolume
        self.format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        buildPools()
        startObservingSystemAudioChanges()
    }

    deinit {
        fadeTask?.cancel()
        cancelAllCompletionTasks()
        stopObservingSystemAudioChanges()
    }

    func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        guard isPlaybackReady(for: effect), var pool = pools[effect], pool.slots.isEmpty == false else {
            markPlaybackSkipped(effect: effect, reason: "engine unavailable or missing pool")
            invokeCompletionForUnavailablePlayback(completion)
            return
        }

        fadeTask?.cancel()
        let slotIndex = selectSlotIndex(in: pool)
        let slot = pool.slots[slotIndex]
        slot.token &+= 1
        let token = slot.token
        slot.completionTask?.cancel()
        slot.completionTask = nil
        slot.completion = nil

        slot.node.stop()
        slot.node.volume = volume
        slot.node.scheduleBuffer(pool.buffer, at: nil, options: [.interrupts], completionHandler: nil)
        guard engine.isRunning, slot.node.engine === engine else {
            markGraphDirty(reason: "player node detached before play for \(effect.rawValue)")
            markPlaybackSkipped(effect: effect, reason: "engine not running or node detached before play")
            slot.node.stop()
            pool.nextIndex = (slotIndex + 1) % pool.slots.count
            pools[effect] = pool
            invokeCompletionForUnavailablePlayback(completion)
            return
        }
        if slot.node.isPlaying == false {
            slot.node.play()
        }

        if let completion {
            slot.completion = completion
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

    func stopAll(fadeDuration: TimeInterval) {
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

    func setVolume(_ volume: Double) {
        self.volume = Float(min(max(volume, 0), 1))
        setNodeVolumes(self.volume)
    }

    func markGraphDirtyForTesting() {
        markGraphDirty(reason: "test hook")
    }

    var testAvailableEffects: Set<SoundEffect> { availableEffects }

    func testFrameCount(for effect: SoundEffect) -> AVAudioFrameCount? {
        pools[effect]?.buffer.frameLength
    }

    func testIsPlaying(effect: SoundEffect) -> Bool {
        guard let pool = pools[effect] else { return false }
        return pool.slots.contains { $0.node.isPlaying }
    }

    var testCurrentVolume: Float { volume }

    func testNodeVolume(effect: SoundEffect) -> Float? {
        pools[effect]?.slots.first?.node.volume
    }

    var testPlaybackSkippedCount: Int { playbackSkippedCount }
    var testGraphRebuildCount: Int { graphRebuildCount }
    var testEngineRestartAttemptCount: Int { engineRestartAttemptCount }
    var testEngineRestartSuccessCount: Int { engineRestartSuccessCount }
    var testEngineRestartFailureCount: Int { engineRestartFailureCount }

    private func buildPools() {
        cancelAllCompletionTasks()
        pools.removeAll()
        availableEffects.removeAll()

        guard let format else {
            engineHealthy = false
            AppLog.error(
                AppLog.sound,
                "GENERATED_SFX_POOL_BUILD",
                outcome: .failed,
                fields: [.reason("invalid_audio_format")]
            )
            return
        }

        for effect in SoundEffect.allCases {
            let recipe = profile.recipe(for: effect)
            guard let buffer = GeneratedSFXRenderer.makeBuffer(recipe: recipe, format: format) else {
                AppLog.warning(
                    AppLog.sound,
                    "GENERATED_SFX_EFFECT_BUFFER_RENDER",
                    outcome: .failed,
                    fields: [
                        .reason("buffer_render_failed"),
                        .string("effect", effect.rawValue)
                    ]
                )
                continue
            }

            let slots = makeSlots(for: effect, format: format)
            guard slots.isEmpty == false else {
                AppLog.warning(
                    AppLog.sound,
                    "GENERATED_SFX_EFFECT_SLOT_CREATE",
                    outcome: .failed,
                    fields: [
                        .reason("slot_creation_failed"),
                        .string("effect", effect.rawValue)
                    ]
                )
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
            AppLog.error(
                AppLog.sound,
                "GENERATED_SFX_POOL_BUILD",
                outcome: .failed,
                fields: [.reason("no_playable_effects")]
            )
            return
        }
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
        return ensureEngineReady(context: "play \(effect.rawValue)")
    }

    @discardableResult
    private func ensureEngineReady(context: String) -> Bool {
        guard engineHealthy else { return false }

        if needsGraphRebuild {
            rebuildGraph(reason: "pending dirty graph before \(context)")
        }
        guard engineHealthy else { return false }

        if engine.isRunning {
            return true
        }
        if startEngineIfNeeded(context: context) {
            return true
        }

        markGraphDirty(reason: "engine start failed during \(context)")
        rebuildGraph(reason: "retry after start failure for \(context)")
        guard engineHealthy else { return false }
        return engine.isRunning || startEngineIfNeeded(context: "\(context) (post-rebuild)")
    }

    @discardableResult
    private func startEngineIfNeeded(context: String) -> Bool {
        guard engineHealthy else { return false }
        guard engine.isRunning == false else { return true }

        engineRestartAttemptCount += 1
        do {
            if testForceStartEngineFailure {
                throw NSError(
                    domain: "RetroRacing.Audio.Test",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Forced engine start failure"]
                )
            }
            try engine.start()
            engineRestartSuccessCount += 1
            AppLog.info(
                AppLog.sound,
                "GENERATED_SFX_ENGINE_START",
                outcome: .succeeded,
                fields: [
                    .string("context", context),
                    .int("successCount", engineRestartSuccessCount),
                    .int("attemptCount", engineRestartAttemptCount)
                ]
            )
            return true
        } catch {
            engine.stop()
            engine.reset()
            engineRestartFailureCount += 1
            AppLog.error(
                AppLog.sound,
                "GENERATED_SFX_ENGINE_START",
                outcome: .failed,
                fields: [
                    .reason("engine_start_failed"),
                    .string("context", context),
                    .int("failureCount", engineRestartFailureCount),
                    .int("attemptCount", engineRestartAttemptCount)
                ] + AppLog.Field.error(error)
            )
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

    private func invokeCompletionForUnavailablePlayback(_ completion: (() -> Void)?) {
        guard let completion else { return }
        DispatchQueue.main.async {
            completion()
        }
    }

    private func markPlaybackSkipped(effect: SoundEffect, reason: String) {
        playbackSkippedCount += 1
        AppLog.warning(
            AppLog.sound,
            "GENERATED_SFX_PLAYBACK",
            outcome: .skipped,
            fields: [
                .reason("engine_unavailable"),
                .string("effect", effect.rawValue),
                .string("detail", reason),
                .int("skippedCount", playbackSkippedCount),
                .int("rebuildCount", graphRebuildCount),
                .int("restartFailureCount", engineRestartFailureCount)
            ]
        )
    }

    private func markGraphDirty(reason: String) {
        needsGraphRebuild = true
        AppLog.debug(
            AppLog.sound,
            "GENERATED_SFX_GRAPH_DIRTY",
            outcome: .completed,
            fields: [.string("reason", reason)]
        )
    }

    private func rebuildGraph(reason: String) {
        graphRebuildCount += 1
        AppLog.info(
            AppLog.sound,
            "GENERATED_SFX_GRAPH_REBUILD",
            outcome: .started,
            fields: [
                .string("reason", reason),
                .int("rebuildCount", graphRebuildCount)
            ]
        )

        fadeTask?.cancel()
        fadeTask = nil
        cancelAllCompletionTasks()
        engine.stop()
        engine.reset()
        engineHealthy = true
        needsGraphRebuild = false
        engine = AVAudioEngine()
        buildPools()
        refreshEngineObserver()

        guard engineHealthy else {
            AppLog.error(
                AppLog.sound,
                "GENERATED_SFX_GRAPH_REBUILD",
                outcome: .failed,
                fields: [.reason("player_unhealthy")]
            )
            return
        }

        if startEngineIfNeeded(context: "graph rebuild") == false {
            markGraphDirty(reason: "graph rebuild start failure")
        }
    }

    private func startObservingSystemAudioChanges() {
        let center = NotificationCenter.default
#if !os(macOS)
        audioSessionObserverTokens.append(
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleAudioInterruption(notification)
            }
        )
        audioSessionObserverTokens.append(
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.markGraphDirty(reason: "audio route change")
            }
        )
        audioSessionObserverTokens.append(
            center.addObserver(
                forName: AVAudioSession.mediaServicesWereResetNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.markGraphDirty(reason: "media services reset")
            }
        )
#endif
        refreshEngineObserver()
    }

    private func refreshEngineObserver() {
        let center = NotificationCenter.default
        if let engineObserverToken {
            center.removeObserver(engineObserverToken)
        }
        engineObserverToken = center.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            self?.markGraphDirty(reason: "audio engine configuration changed")
        }
    }

    private func stopObservingSystemAudioChanges() {
        let center = NotificationCenter.default
        for token in audioSessionObserverTokens {
            center.removeObserver(token)
        }
        audioSessionObserverTokens.removeAll()
        if let engineObserverToken {
            center.removeObserver(engineObserverToken)
            self.engineObserverToken = nil
        }
    }

#if !os(macOS)
    private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return
        }
        guard type == .ended else { return }
        markGraphDirty(reason: "audio interruption ended")
    }
#endif
}

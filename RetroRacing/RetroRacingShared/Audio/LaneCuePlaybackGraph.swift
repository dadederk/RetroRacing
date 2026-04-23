//
//  LaneCuePlaybackGraph.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 21/04/2026.
//

import Foundation
import AVFoundation

enum LaneCuePlaybackRole {
    case tick
    case move
}

final class LaneCuePlaybackGraph {
    private var engine = AVAudioEngine()
    private var tickPlayer = AVAudioPlayerNode()
    private var movePlayer = AVAudioPlayerNode()
    private let format: AVAudioFormat?

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

    init(format: AVAudioFormat?, initialVolume: Float) {
        self.format = format
        self.volume = initialVolume

        guard let format else {
            engineHealthy = false
            AppLog.error(
                AppLog.sound,
                "LANE_CUE_GRAPH_INIT",
                outcome: .failed,
                fields: [.reason("invalid_audio_format")]
            )
            return
        }

        configureAudioGraph(format: format)
        startObservingSystemAudioChanges()
    }

    deinit {
        fadeTask?.cancel()
        stopObservingSystemAudioChanges()
    }

    func play(buffer: AVAudioPCMBuffer, role: LaneCuePlaybackRole, context: String) {
        fadeTask?.cancel()
        tickPlayer.volume = volume
        movePlayer.volume = volume

        guard ensureEngineReady(context: context) else {
            markPlaybackSkipped(reason: "engine unavailable for \(context)")
            return
        }
        let node = playerNode(for: role)
        guard node.engine === engine else {
            markGraphDirty(reason: "node detached before \(context)")
            markPlaybackSkipped(reason: "node detached before \(context)")
            return
        }

        node.stop()
        node.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
        guard engine.isRunning else {
            markGraphDirty(reason: "engine stopped before \(context)")
            markPlaybackSkipped(reason: "engine stopped before \(context)")
            node.stop()
            return
        }
        if !node.isPlaying {
            node.play()
        }
    }

    func setVolume(_ volume: Double) {
        self.volume = Float(min(max(volume, 0), 1))
        tickPlayer.volume = self.volume
        movePlayer.volume = self.volume
    }

    func stopAll(fadeDuration: TimeInterval) {
        fadeTask?.cancel()
        let duration = max(0, fadeDuration)
        guard duration > 0 else {
            stopImmediately()
            return
        }

        let startTickVolume = tickPlayer.volume
        let startMoveVolume = movePlayer.volume
        let targetVolume = volume

        fadeTask = Task { [weak self] in
            guard let self else { return }
            let steps = 10
            let stepDuration = duration / Double(steps)

            for step in 0..<steps {
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                let fraction = Float(1.0 - Double(step + 1) / Double(steps))
                await MainActor.run {
                    self.tickPlayer.volume = startTickVolume * fraction
                    self.movePlayer.volume = startMoveVolume * fraction
                }
            }

            await MainActor.run {
                self.stopImmediately()
                self.tickPlayer.volume = targetVolume
                self.movePlayer.volume = targetVolume
            }
        }
    }

    func markGraphDirtyForTesting() {
        markGraphDirty(reason: "test hook")
    }

    var testPlaybackSkippedCount: Int { playbackSkippedCount }
    var testGraphRebuildCount: Int { graphRebuildCount }
    var testEngineRestartAttemptCount: Int { engineRestartAttemptCount }
    var testEngineRestartSuccessCount: Int { engineRestartSuccessCount }
    var testEngineRestartFailureCount: Int { engineRestartFailureCount }

    private func playerNode(for role: LaneCuePlaybackRole) -> AVAudioPlayerNode {
        switch role {
        case .tick: return tickPlayer
        case .move: return movePlayer
        }
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
                "LANE_CUE_ENGINE_START",
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
                "LANE_CUE_ENGINE_START",
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

    private func stopImmediately() {
        tickPlayer.stop()
        movePlayer.stop()
    }

    private func configureAudioGraph(format: AVAudioFormat) {
        engine.attach(tickPlayer)
        engine.attach(movePlayer)
        engine.connect(tickPlayer, to: engine.mainMixerNode, format: format)
        engine.connect(movePlayer, to: engine.mainMixerNode, format: format)
        tickPlayer.volume = volume
        movePlayer.volume = volume
        refreshEngineObserver()
    }

    private func markPlaybackSkipped(reason: String) {
        playbackSkippedCount += 1
        AppLog.warning(
            AppLog.sound,
            "LANE_CUE_PLAYBACK",
            outcome: .skipped,
            fields: [
                .reason("engine_unavailable"),
                .string("detail", reason),
                .int("skippedCount", playbackSkippedCount),
                .int("rebuildCount", graphRebuildCount),
                .int("restartFailureCount", engineRestartFailureCount)
            ]
        )
    }

    private func markGraphDirty(reason: String) {
        needsGraphRebuild = true
        AppLog.debug(AppLog.sound, "LANE_CUE_GRAPH_DIRTY", outcome: .completed, fields: [.string("reason", reason)])
    }

    private func rebuildGraph(reason: String) {
        graphRebuildCount += 1
        AppLog.info(
            AppLog.sound,
            "LANE_CUE_GRAPH_REBUILD",
            outcome: .started,
            fields: [
                .string("reason", reason),
                .int("rebuildCount", graphRebuildCount)
            ]
        )

        fadeTask?.cancel()
        fadeTask = nil
        engine.stop()
        engine.reset()
        needsGraphRebuild = false
        engineHealthy = true

        guard let format else {
            engineHealthy = false
            AppLog.error(
                AppLog.sound,
                "LANE_CUE_GRAPH_REBUILD",
                outcome: .failed,
                fields: [.reason("invalid_audio_format")]
            )
            return
        }

        engine = AVAudioEngine()
        tickPlayer = AVAudioPlayerNode()
        movePlayer = AVAudioPlayerNode()
        configureAudioGraph(format: format)

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

//
//  AudioPlaybackReadiness.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 07/06/2026.
//

import AVFoundation

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

struct AudioPlaybackReadinessResult: Equatable {
    let isReady: Bool
    let reason: String

    static let ready = AudioPlaybackReadinessResult(isReady: true, reason: "ready")

    static func unavailable(_ reason: String) -> AudioPlaybackReadinessResult {
        AudioPlaybackReadinessResult(isReady: false, reason: reason)
    }
}

enum AudioPlaybackReadiness {
    static func playerNodeCanStart(
        engine: AVAudioEngine,
        node: AVAudioPlayerNode,
        context: String
    ) -> AudioPlaybackReadinessResult {
        guard isAppActiveForPlayback else {
            return .unavailable("app_not_active")
        }
        guard activateSessionIfNeeded(context: context) else {
            return .unavailable("audio_session_activation_failed")
        }
        guard engine.isRunning else {
            return .unavailable("engine_not_running")
        }
        guard node.engine === engine else {
            return .unavailable("player_node_detached")
        }
        guard isPlayable(format: engine.outputNode.inputFormat(forBus: 0)) else {
            return .unavailable("output_format_unavailable")
        }
        guard isPlayable(format: engine.mainMixerNode.outputFormat(forBus: 0)) else {
            return .unavailable("mixer_format_unavailable")
        }
        guard isPlayable(format: node.outputFormat(forBus: 0)) else {
            return .unavailable("player_format_unavailable")
        }
        return .ready
    }

    static func prepareSessionForEngineStart(context: String) -> Bool {
        guard isAppActiveForPlayback else {
            AppLog.warning(
                AppLog.sound,
                "AUDIO_ENGINE_PREPLAY",
                outcome: .skipped,
                fields: [
                    .reason("app_not_active"),
                    .string("context", context)
                ]
            )
            return false
        }
        return activateSessionIfNeeded(context: context)
    }

    private static var isAppActiveForPlayback: Bool {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return true
        }
        #if canImport(UIKit) && !os(watchOS)
        return UIApplication.shared.applicationState == .active
        #else
        return true
        #endif
    }

    private static func activateSessionIfNeeded(context: String) -> Bool {
        #if !os(macOS)
        do {
            try AVAudioSessionActivation.activateBlocking()
            return true
        } catch {
            AppLog.warning(
                AppLog.sound,
                "AUDIO_SESSION_PREPLAY_ACTIVATION",
                outcome: .skipped,
                fields: [
                    .reason("activation_failed"),
                    .string("context", context)
                ] + AppLog.Field.error(error)
            )
            return false
        }
        #else
        return true
        #endif
    }

    private static func isPlayable(format: AVAudioFormat) -> Bool {
        format.sampleRate > 0 && format.channelCount > 0
    }
}

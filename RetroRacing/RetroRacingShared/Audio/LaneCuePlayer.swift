//
//  LaneCuePlayer.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 17/02/2026.
//

import Foundation
import AVFoundation

public enum CueColumn: Int, CaseIterable, Sendable {
    case left = 0
    case middle = 1
    case right = 2
}

/// Central tuning profile for generated lane cues.
public struct LaneCueProfile: Equatable, Sendable {
    public let frequenciesHz: [CueColumn: Double]
    public let warningFrequencyHz: Double
    public let safeFeedbackFrequencyHz: Double
    public let unsafeFeedbackFrequencyHz: Double
    public let tickAmplitude: Double
    public let moveSafeAmplitude: Double
    public let moveUnsafeAmplitude: Double
    public let unsafeFrequencyMultiplier: Double
    public let chordDuration: TimeInterval
    public let arpeggioNoteDuration: TimeInterval
    public let lanePulseSlotDuration: TimeInterval
    public let moveLaneDuration: TimeInterval
    public let moveSafetyDuration: TimeInterval
    public let moveLaneToSafetyGapDuration: TimeInterval
    public let attack: TimeInterval
    public let decay: TimeInterval

    public init(
        frequenciesHz: [CueColumn: Double],
        warningFrequencyHz: Double,
        safeFeedbackFrequencyHz: Double,
        unsafeFeedbackFrequencyHz: Double,
        tickAmplitude: Double,
        moveSafeAmplitude: Double,
        moveUnsafeAmplitude: Double,
        unsafeFrequencyMultiplier: Double,
        chordDuration: TimeInterval,
        arpeggioNoteDuration: TimeInterval,
        lanePulseSlotDuration: TimeInterval,
        moveLaneDuration: TimeInterval,
        moveSafetyDuration: TimeInterval,
        moveLaneToSafetyGapDuration: TimeInterval,
        attack: TimeInterval,
        decay: TimeInterval
    ) {
        self.frequenciesHz = frequenciesHz
        self.warningFrequencyHz = warningFrequencyHz
        self.safeFeedbackFrequencyHz = safeFeedbackFrequencyHz
        self.unsafeFeedbackFrequencyHz = unsafeFeedbackFrequencyHz
        self.tickAmplitude = tickAmplitude
        self.moveSafeAmplitude = moveSafeAmplitude
        self.moveUnsafeAmplitude = moveUnsafeAmplitude
        self.unsafeFrequencyMultiplier = unsafeFrequencyMultiplier
        self.chordDuration = chordDuration
        self.arpeggioNoteDuration = arpeggioNoteDuration
        self.lanePulseSlotDuration = lanePulseSlotDuration
        self.moveLaneDuration = moveLaneDuration
        self.moveSafetyDuration = moveSafetyDuration
        self.moveLaneToSafetyGapDuration = moveLaneToSafetyGapDuration
        self.attack = attack
        self.decay = decay
    }

    public static let defaultPleasant = LaneCueProfile(
        frequenciesHz: [
            .left: 523.251,
            .middle: 659.255,
            .right: 783.991
        ],
        warningFrequencyHz: 440,
        safeFeedbackFrequencyHz: 987.767,
        unsafeFeedbackFrequencyHz: 415.305,
        tickAmplitude: 0.18,
        moveSafeAmplitude: 0.2,
        moveUnsafeAmplitude: 0.22,
        unsafeFrequencyMultiplier: 0.94,
        chordDuration: 0.07,
        arpeggioNoteDuration: 0.036,
        lanePulseSlotDuration: 0.03,
        moveLaneDuration: 0.045,
        moveSafetyDuration: 0.04,
        moveLaneToSafetyGapDuration: 0.006,
        attack: 0.003,
        decay: 0.02
    )
}

/// Audio guidance cues for lane safety and movement.
public protocol LaneCuePlayer {
    func playTickCue(safeColumns: Set<CueColumn>, mode: AudioFeedbackMode)
    func playMoveCue(
        column: CueColumn,
        isSafe: Bool,
        mode: AudioFeedbackMode,
        style: LaneMoveCueStyle
    )
    func playSpeedWarningCue()
    func setVolume(_ volume: Double)
    func stopAll(fadeDuration: TimeInterval)
}

public final class AVLaneCuePlayer: LaneCuePlayer {
    private let buffers: LaneCueBuffers
    private let graph: LaneCuePlaybackGraph

    // MARK: - Internal test hooks
    var _testForceStartEngineFailure: Bool {
        get { graph.testForceStartEngineFailure }
        set { graph.testForceStartEngineFailure = newValue }
    }

    public init(sampleRate: Double = 44_100, profile: LaneCueProfile = .defaultPleasant) {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        self.buffers = LaneCueBufferFactory(format: format, profile: profile).makeBuffers()
        self.graph = LaneCuePlaybackGraph(
            format: format,
            initialVolume: Float(SoundPreferences.defaultVolume)
        )
    }

    public func playTickCue(safeColumns: Set<CueColumn>, mode: AudioFeedbackMode) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.playTickCue(safeColumns: safeColumns, mode: mode)
            }
            return
        }
        playTickCueOnMain(safeColumns: safeColumns, mode: mode)
    }

    public func playMoveCue(
        column: CueColumn,
        isSafe: Bool,
        mode: AudioFeedbackMode,
        style: LaneMoveCueStyle
    ) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.playMoveCue(column: column, isSafe: isSafe, mode: mode, style: style)
            }
            return
        }
        playMoveCueOnMain(column: column, isSafe: isSafe, mode: mode, style: style)
    }

    public func playSpeedWarningCue() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.playSpeedWarningCue()
            }
            return
        }
        playSpeedWarningCueOnMain()
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

    public func stopAll(fadeDuration: TimeInterval) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.stopAll(fadeDuration: fadeDuration)
            }
            return
        }
        graph.stopAll(fadeDuration: fadeDuration)
    }

    // MARK: - Internal test hooks

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

    private func playTickCueOnMain(safeColumns: Set<CueColumn>, mode: AudioFeedbackMode) {
        guard mode != .retro else { return }
        guard let modeBuffers = buffers.tickBuffers[mode] else { return }
        let mask = Self.mask(for: safeColumns)
        guard let buffer = modeBuffers[mask] else { return }
        graph.play(buffer: buffer, role: .tick, context: "tick cue")
    }

    private func playMoveCueOnMain(
        column: CueColumn,
        isSafe: Bool,
        mode: AudioFeedbackMode,
        style: LaneMoveCueStyle
    ) {
        guard mode != .retro else { return }
        let buffer: AVAudioPCMBuffer?
        switch style {
        case .laneConfirmation:
            buffer = buffers.laneMoveBuffers[column]
        case .safetyOnly:
            buffer = buffers.safetyMoveBuffers[isSafe]
        case .laneConfirmationAndSafety:
            buffer = buffers.combinedMoveBuffers[isSafe]?[column]
        case .haptics:
            buffer = nil
        }
        guard let buffer else { return }
        graph.play(buffer: buffer, role: .move, context: "move cue")
    }

    private func playSpeedWarningCueOnMain() {
        guard let speedWarningBuffer = buffers.speedWarningBuffer else { return }
        graph.play(buffer: speedWarningBuffer, role: .tick, context: "speed warning cue")
    }

    private static func mask(for columns: Set<CueColumn>) -> UInt8 {
        columns.reduce(0) { partialResult, column in
            partialResult | (1 << UInt8(column.rawValue))
        }
    }
}

//
//  GameplayAudioFeedbackCoordinator.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 07/08/2026.
//

import Foundation

/// Renderer-neutral gameplay feedback events shared by SpriteKit, SwiftUI, and RealityKit.
public enum GameplayAudioFeedbackEvent: Equatable, Sendable {
    case tick
    case move(destinationColumn: Int)
}

/// The user-controlled audio settings read immediately before each cue is played.
public struct GameplayAudioFeedbackPreferences {
    public let volume: @MainActor () -> Double
    public let mode: @MainActor () -> AudioFeedbackMode
    public let laneMoveStyle: @MainActor () -> LaneMoveCueStyle
    public let speedWarningMode: @MainActor () -> SpeedWarningFeedbackMode

    public init(
        volume: @escaping @MainActor () -> Double,
        mode: @escaping @MainActor () -> AudioFeedbackMode,
        laneMoveStyle: @escaping @MainActor () -> LaneMoveCueStyle,
        speedWarningMode: @escaping @MainActor () -> SpeedWarningFeedbackMode
    ) {
        self.volume = volume
        self.mode = mode
        self.laneMoveStyle = laneMoveStyle
        self.speedWarningMode = speedWarningMode
    }
}

/// Central audio dispatcher for gameplay rendered outside `GameScene`.
///
/// It also owns completion fallbacks so a lost audio-route callback can never leave gameplay
/// permanently paused on the start or collision frames.
@MainActor
public final class GameplayAudioFeedbackCoordinator {
    private let soundPlayer: any SoundEffectPlayer
    private let laneCuePlayer: (any LaneCuePlayer)?
    private let hapticController: HapticFeedbackController?
    private let speedWarningPlayer: any SpeedIncreaseWarningFeedbackPlaying
    private let preferences: GameplayAudioFeedbackPreferences
    private let startFallbackDuration: Duration
    private let collisionFallbackDuration: Duration

    private var startFallbackTask: Task<Void, Never>?
    private var collisionFallbackTask: Task<Void, Never>?
    private var startGeneration: UInt64 = 0
    private var collisionGeneration: UInt64 = 0
    private var countdownCueScheduler = SharePlayCountdownCueScheduler()

    public init(
        soundPlayer: any SoundEffectPlayer,
        laneCuePlayer: (any LaneCuePlayer)?,
        hapticController: HapticFeedbackController?,
        speedWarningPlayer: any SpeedIncreaseWarningFeedbackPlaying,
        preferences: GameplayAudioFeedbackPreferences,
        startFallbackDuration: Duration = .seconds(2),
        collisionFallbackDuration: Duration = .seconds(8)
    ) {
        self.soundPlayer = soundPlayer
        self.laneCuePlayer = laneCuePlayer
        self.hapticController = hapticController
        self.speedWarningPlayer = speedWarningPlayer
        self.preferences = preferences
        self.startFallbackDuration = startFallbackDuration
        self.collisionFallbackDuration = collisionFallbackDuration
    }

    deinit {
        startFallbackTask?.cancel()
        collisionFallbackTask?.cancel()
    }

    public func refreshVolume() {
        let volume = preferences.volume()
        soundPlayer.setVolume(volume)
        laneCuePlayer?.setVolume(volume)
    }

    public func playStart(completion: @escaping @MainActor () -> Void) {
        startGeneration &+= 1
        let generation = startGeneration
        startFallbackTask?.cancel()
        startFallbackTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.startFallbackDuration)
            guard Task.isCancelled == false else { return }
            self.completeStart(generation: generation, completion: completion)
        }
        soundPlayer.play(.start) { [weak self] in
            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self?.completeStart(generation: generation, completion: completion)
                }
            } else {
                Task { @MainActor in
                    self?.completeStart(generation: generation, completion: completion)
                }
            }
        }
    }

    public func playCollision(completion: @escaping @MainActor () -> Void) {
        collisionGeneration &+= 1
        let generation = collisionGeneration
        collisionFallbackTask?.cancel()
        hapticController?.triggerCrashHaptic()
        collisionFallbackTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.collisionFallbackDuration)
            guard Task.isCancelled == false else { return }
            self.completeCollision(generation: generation, completion: completion)
        }
        soundPlayer.play(.fail) { [weak self] in
            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self?.completeCollision(generation: generation, completion: completion)
                }
            } else {
                Task { @MainActor in
                    self?.completeCollision(generation: generation, completion: completion)
                }
            }
        }
    }

    public func process(
        previousSnapshot: GameSnapshot,
        snapshot: GameSnapshot,
        events: [GameEvent]
    ) {
        let didResetRoadPhase = events.contains { event in
            switch event {
            case .started, .restarted, .collisionResolved:
                return true
            case .scoreChanged, .laneChanged, .collision, .levelChangeImminent,
                 .pauseChanged, .gameOver, .finished:
                return false
            }
        }
        if didResetRoadPhase == false,
           previousSnapshot.roadPhase != snapshot.roadPhase,
           snapshot.phase == .running {
            playFeedback(.tick, snapshot: snapshot)
        }

        for event in events {
            switch event {
            case .laneChanged(let column):
                playFeedback(.move(destinationColumn: column), snapshot: snapshot)
            case .levelChangeImminent(true):
                speedWarningPlayer.play(mode: preferences.speedWarningMode())
            case .started, .scoreChanged, .collision, .collisionResolved,
                 .levelChangeImminent(false), .pauseChanged, .gameOver,
                 .restarted, .finished:
                break
            }
        }
    }

    public func playFeedback(_ event: GameplayAudioFeedbackEvent, snapshot: GameSnapshot) {
        GameplayAudioFeedbackRouter.play(
            event,
            grid: snapshot.grid,
            playerRowIndex: max(0, snapshot.numberOfRows - 1),
            mode: preferences.mode(),
            laneMoveStyle: preferences.laneMoveStyle(),
            laneCuePlayer: laneCuePlayer,
            hapticController: hapticController
        )
    }

    public func playSharePlayCountdown(displayValue: Int) {
        guard let effect = countdownCueScheduler.cue(for: displayValue) else { return }
        soundPlayer.play(effect, completion: nil)
    }

    public func playSharePlayGo() {
        countdownCueScheduler.reset()
        soundPlayer.play(.sharePlayCountdownGo, completion: nil)
    }

    public func resetSharePlayCountdown() {
        countdownCueScheduler.reset()
    }

    public func stopAll(fadeDuration: TimeInterval = 0.15) {
        invalidatePendingPlayback()
        soundPlayer.stopAll(fadeDuration: fadeDuration)
        laneCuePlayer?.stopAll(fadeDuration: fadeDuration)
    }

    public func invalidatePendingPlayback() {
        startGeneration &+= 1
        collisionGeneration &+= 1
        startFallbackTask?.cancel()
        collisionFallbackTask?.cancel()
        startFallbackTask = nil
        collisionFallbackTask = nil
    }

    private func completeStart(
        generation: UInt64,
        completion: @escaping @MainActor () -> Void
    ) {
        guard generation == startGeneration else { return }
        startGeneration &+= 1
        startFallbackTask?.cancel()
        startFallbackTask = nil
        completion()
    }

    private func completeCollision(
        generation: UInt64,
        completion: @escaping @MainActor () -> Void
    ) {
        guard generation == collisionGeneration else { return }
        collisionGeneration &+= 1
        collisionFallbackTask?.cancel()
        collisionFallbackTask = nil
        completion()
    }
}

/// The single lane-safety routing policy used by SpriteKit and visionOS gameplay.
@MainActor
public enum GameplayAudioFeedbackRouter {
    public static func play(
        _ event: GameplayAudioFeedbackEvent,
        grid: [[GameGridOccupant]],
        playerRowIndex: Int,
        mode: AudioFeedbackMode,
        laneMoveStyle: LaneMoveCueStyle,
        laneCuePlayer: (any LaneCuePlayer)?,
        hapticController: HapticFeedbackController?
    ) {
        guard let laneCuePlayer else { return }

        if mode == .retro {
            playRetro(event, laneCuePlayer: laneCuePlayer)
            return
        }

        switch event {
        case .tick:
            laneCuePlayer.playTickCue(
                safeColumns: safeColumns(in: grid, playerRowIndex: playerRowIndex),
                mode: mode
            )
        case .move(let destinationColumn):
            let isSafe = isSafe(
                destinationColumn: destinationColumn,
                grid: grid,
                playerRowIndex: playerRowIndex
            )
            if laneMoveStyle == .haptics {
                if isSafe {
                    hapticController?.triggerSuccessHaptic()
                } else {
                    hapticController?.triggerMoveHaptic()
                }
                return
            }
            guard let column = CueColumn(rawValue: destinationColumn) else { return }
            laneCuePlayer.playMoveCue(
                column: column,
                isSafe: isSafe,
                mode: mode,
                style: laneMoveStyle
            )
        }
    }

    private static func playRetro(
        _ event: GameplayAudioFeedbackEvent,
        laneCuePlayer: any LaneCuePlayer
    ) {
        switch event {
        case .tick:
            laneCuePlayer.playTickCue(
                safeColumns: Set(CueColumn.allCases),
                mode: .cueArpeggio
            )
        case .move:
            laneCuePlayer.playMoveCue(
                column: .middle,
                isSafe: true,
                mode: .cueArpeggio,
                style: .laneConfirmation
            )
        }
    }

    private static func safeColumns(
        in grid: [[GameGridOccupant]],
        playerRowIndex: Int
    ) -> Set<CueColumn> {
        let candidateRow = playerRowIndex - 1
        guard grid.indices.contains(candidateRow) else {
            return Set(CueColumn.allCases)
        }

        return Set(grid[candidateRow].indices.compactMap { column in
            guard grid[candidateRow][column] != .rival else { return nil }
            return CueColumn(rawValue: column)
        })
    }

    private static func isSafe(
        destinationColumn: Int,
        grid: [[GameGridOccupant]],
        playerRowIndex: Int
    ) -> Bool {
        let candidateRow = playerRowIndex - 1
        guard grid.indices.contains(candidateRow),
              grid[candidateRow].indices.contains(destinationColumn) else {
            return true
        }
        return grid[candidateRow][destinationColumn] != .rival
    }
}

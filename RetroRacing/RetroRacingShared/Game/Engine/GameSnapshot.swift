//
//  GameSnapshot.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation

/// A renderer-neutral occupant in the visible race grid.
public enum GameGridOccupant: Equatable, Sendable {
    case empty
    case rival
    case player
    case crash
}

/// The lifecycle phase of a gameplay run.
public enum GamePhase: Equatable, Sendable {
    case ready
    case running
    case paused
    case collision
    case gameOver
    case finished
}

/// Independent reasons that can keep an otherwise active run paused.
public enum GamePauseReason: Hashable, Sendable {
    case startup
    case user
    case overlay
    case presentationTransition
    case appInactive
    case sharePlay
}

/// Directional lane movement understood by every renderer and input adapter.
public enum GameMoveDirection: Equatable, Sendable {
    case left
    case right
}

/// Resolves absolute lane selections into one bounded movement command.
public enum GameLaneSelectionResolver {
    public static func direction(
        selectedLane: Int,
        currentLane: Int,
        laneCount: Int
    ) -> GameMoveDirection? {
        guard laneCount > 0,
              (0..<laneCount).contains(selectedLane),
              (0..<laneCount).contains(currentLane),
              selectedLane != currentLane else {
            return nil
        }
        return selectedLane < currentLane ? .left : .right
    }
}

/// Traffic generation mode used for solo and synchronized runs.
public enum GameTrafficMode: Equatable, Sendable {
    case random
    case seeded(UInt64)
}

/// Commands accepted by the shared gameplay engine.
public enum GameCommand: Equatable, Sendable {
    case start
    case tick(elapsedTime: TimeInterval)
    case move(GameMoveDirection)
    case resolveCollision
    case setPause(reason: GamePauseReason, isActive: Bool)
    case restart
    case finish
    case setDifficulty(GameDifficulty)
    case setTrafficMode(GameTrafficMode)
}

/// Discrete side effects emitted while applying a command.
public enum GameEvent: Equatable, Sendable {
    case started
    case laneChanged(column: Int)
    case scoreChanged(score: Int)
    case collision(livesRemaining: Int)
    case collisionResolved(livesRemaining: Int)
    case levelChangeImminent(Bool)
    case pauseChanged(Bool)
    case gameOver(score: Int)
    case restarted
    case finished
}

/// Immutable state consumed by SpriteKit, Canvas, and RealityKit renderers.
public struct GameSnapshot: Equatable, Sendable {
    public let phase: GamePhase
    public let grid: [[GameGridOccupant]]
    public let playerColumn: Int
    public let score: Int
    public let lives: Int
    public let level: Int
    public let roadPhase: Int
    public let safetyMarkerRows: [Int]
    public let difficulty: GameDifficulty
    public let activePauseReasons: Set<GamePauseReason>

    public var numberOfRows: Int { grid.count }
    public var numberOfColumns: Int { grid.first?.count ?? 0 }
    public var isPaused: Bool { phase != .running }

    init(
        phase: GamePhase,
        grid: [[GameGridOccupant]],
        playerColumn: Int,
        score: Int,
        lives: Int,
        level: Int,
        roadPhase: Int,
        safetyMarkerRows: [Int],
        difficulty: GameDifficulty,
        activePauseReasons: Set<GamePauseReason>
    ) {
        self.phase = phase
        self.grid = grid
        self.playerColumn = playerColumn
        self.score = score
        self.lives = lives
        self.level = level
        self.roadPhase = roadPhase
        self.safetyMarkerRows = safetyMarkerRows
        self.difficulty = difficulty
        self.activePauseReasons = activePauseReasons
    }

    /// Builds a non-production snapshot only when its renderer-facing invariants hold.
    static func fixture(
        phase: GamePhase,
        grid: [[GameGridOccupant]],
        playerColumn: Int,
        score: Int,
        lives: Int,
        level: Int,
        roadPhase: Int,
        safetyMarkerRows: [Int],
        difficulty: GameDifficulty,
        activePauseReasons: Set<GamePauseReason>
    ) -> GameSnapshot? {
        let snapshot = GameSnapshot(
            phase: phase,
            grid: grid,
            playerColumn: playerColumn,
            score: score,
            lives: lives,
            level: level,
            roadPhase: roadPhase,
            safetyMarkerRows: safetyMarkerRows,
            difficulty: difficulty,
            activePauseReasons: activePauseReasons
        )
        return snapshot.hasValidFixtureInvariants ? snapshot : nil
    }

    var hasValidFixtureInvariants: Bool {
        guard numberOfRows > 0,
              numberOfColumns > 0,
              grid.allSatisfy({ $0.count == numberOfColumns }),
              (0..<numberOfColumns).contains(playerColumn),
              score >= 0,
              lives >= 0,
              lives <= GameState.initialLives,
              level > 0,
              (0..<numberOfRows).contains(roadPhase),
              safetyMarkerRows.allSatisfy({ (0..<numberOfRows).contains($0) }) else {
            return false
        }

        let playerCells = grid.last?.enumerated().compactMap { column, occupant in
            occupant == .player || occupant == .crash ? column : nil
        } ?? []
        guard playerCells == [playerColumn] else { return false }
        if phase == .collision || phase == .gameOver {
            return grid.last?[playerColumn] == .crash
        }
        return true
    }
}

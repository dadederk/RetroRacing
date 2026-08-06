//
//  GameEngine.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation

/// Renderer-independent interface for a single RetroRapid! gameplay run.
@MainActor
public protocol GameEngineProtocol: AnyObject {
    var snapshot: GameSnapshot { get }

    @discardableResult
    func handle(_ command: GameCommand) -> [GameEvent]
}

/// Deterministic gameplay engine shared by all presentation technologies.
@MainActor
public final class GameEngine: GameEngineProtocol {
    private enum Configuration {
        static let numberOfRows = 5
        static let numberOfColumns = 3
        static let preLevelForecastRows = 4
        static let safetyRowOffsetsBeforeLevelChange: Set<Int> = [2, 3]
        static let collisionDuration: TimeInterval = 0.75
    }

    private let randomSource: RandomSource
    private var trafficMode: GameTrafficMode
    private var trafficRowSource: TrafficRowSource
    private var gridCalculator: GridStateCalculator
    private var gridState: GridState
    private var gameState = GameState()
    private var basePhase: GamePhase = .ready
    private var pauseReasons = Set<GamePauseReason>()
    private var elapsedTimeAccumulator: TimeInterval = 0
    private var collisionElapsedTime: TimeInterval = 0
    private var roadPhase = 0
    private var safetyMarkerRows = [Int]()
    private var lastLevelChangeImminent = false
    private var difficulty: GameDifficulty

    public init(
        randomSource: RandomSource,
        difficulty: GameDifficulty,
        trafficMode: GameTrafficMode = .random
    ) {
        self.randomSource = randomSource
        self.difficulty = difficulty
        self.trafficMode = trafficMode
        let trafficRowSource = Self.makeTrafficRowSource(mode: trafficMode, randomSource: randomSource)
        self.trafficRowSource = trafficRowSource
        self.gridCalculator = GridStateCalculator(
            trafficRowSource: trafficRowSource,
            timingConfiguration: difficulty.timingConfiguration
        )
        self.gridState = GridState(
            numberOfRows: Configuration.numberOfRows,
            numberOfColumns: Configuration.numberOfColumns
        )
    }

    public var snapshot: GameSnapshot {
        GameSnapshot(
            phase: presentedPhase,
            grid: gridState.grid.map { row in row.map(Self.occupant(for:)) },
            playerColumn: playerColumn,
            score: gameState.score,
            lives: gameState.lives,
            level: gameState.level,
            roadPhase: roadPhase,
            safetyMarkerRows: safetyMarkerRows,
            difficulty: difficulty,
            activePauseReasons: pauseReasons
        )
    }

    @discardableResult
    public func handle(_ command: GameCommand) -> [GameEvent] {
        switch command {
        case .start:
            resetRun()
            basePhase = .running
            return [.started]
        case .tick(let elapsedTime):
            return tick(elapsedTime: elapsedTime)
        case .move(let direction):
            return move(direction)
        case .resolveCollision:
            return completeCollision()
        case .setPause(let reason, let isActive):
            return setPause(reason: reason, isActive: isActive)
        case .restart:
            resetRun()
            basePhase = .running
            return [.restarted]
        case .finish:
            basePhase = .finished
            pauseReasons.removeAll()
            return [.finished]
        case .setDifficulty(let difficulty):
            setDifficulty(difficulty)
            return []
        case .setTrafficMode(let trafficMode):
            setTrafficMode(trafficMode)
            return []
        }
    }

    private var presentedPhase: GamePhase {
        guard basePhase == .running, pauseReasons.isEmpty == false else { return basePhase }
        return .paused
    }

    private var playerColumn: Int {
        gridState.playerRow().firstIndex(of: .Player)
            ?? gridState.playerRow().firstIndex(of: .Crash)
            ?? (Configuration.numberOfColumns / 2)
    }

    private func tick(elapsedTime: TimeInterval) -> [GameEvent] {
        guard elapsedTime.isFinite, elapsedTime > 0 else { return [] }
        guard pauseReasons.isEmpty else { return [] }

        if basePhase == .collision {
            collisionElapsedTime += elapsedTime
            guard collisionElapsedTime >= Configuration.collisionDuration else { return [] }
            return completeCollision()
        }
        guard basePhase == .running else { return [] }

        elapsedTimeAccumulator += elapsedTime
        var events = [GameEvent]()
        var interval = gridCalculator.intervalForLevel(gameState.level)

        while elapsedTimeAccumulator >= interval, basePhase == .running {
            elapsedTimeAccumulator -= interval
            events.append(contentsOf: advanceGrid())
            interval = gridCalculator.intervalForLevel(gameState.level)
        }
        return events
    }

    private func advanceGrid() -> [GameEvent] {
        let action: GridStateCalculator.Action = shouldInsertSafetyRowBeforeNextLevel()
            ? .updateWithEmptyRow
            : .update
        let effects: [GridStateCalculator.Effect]
        (gridState, effects) = gridCalculator.nextGrid(previousGrid: gridState, actions: [action])
        roadPhase = (roadPhase + 1) % Configuration.numberOfRows
        updateSafetyMarkerRows(for: action)

        var events = [GameEvent]()
        for effect in effects {
            switch effect {
            case .scored(let points):
                gameState.score += points
                events.append(.scoreChanged(score: gameState.score))
                let isImminent = GameState.isLevelChangeImminent(
                    score: gameState.score,
                    windowPoints: difficulty.speedAlertWindowPoints
                )
                if isImminent != lastLevelChangeImminent {
                    lastLevelChangeImminent = isImminent
                    events.append(.levelChangeImminent(isImminent))
                }
            case .crashed:
                gameState.lives = max(0, gameState.lives - 1)
                basePhase = .collision
                elapsedTimeAccumulator = 0
                collisionElapsedTime = 0
                events.append(.collision(livesRemaining: gameState.lives))
            }
        }
        return events
    }

    private func move(_ direction: GameMoveDirection) -> [GameEvent] {
        guard basePhase == .running, pauseReasons.isEmpty else { return [] }
        let previousColumn = playerColumn
        let calculatorDirection: GridStateCalculator.Direction = direction == .left ? .left : .right
        (gridState, _) = gridCalculator.nextGrid(
            previousGrid: gridState,
            actions: [.moveCar(direction: calculatorDirection)]
        )
        let currentColumn = playerColumn
        guard currentColumn != previousColumn else { return [] }
        return [.laneChanged(column: currentColumn)]
    }

    private func setPause(reason: GamePauseReason, isActive: Bool) -> [GameEvent] {
        let wasPaused = presentedPhase == .paused
        if isActive {
            pauseReasons.insert(reason)
        } else {
            pauseReasons.remove(reason)
        }
        let isPaused = presentedPhase == .paused
        guard isPaused != wasPaused else { return [] }
        return [.pauseChanged(isPaused)]
    }

    private func completeCollision() -> [GameEvent] {
        guard basePhase == .collision else { return [] }
        collisionElapsedTime = 0
        if gameState.lives == 0 {
            basePhase = .gameOver
            return [.gameOver(score: gameState.score)]
        }

        elapsedTimeAccumulator = 0
        roadPhase = 0
        safetyMarkerRows.removeAll()
        gridState = GridState(
            numberOfRows: Configuration.numberOfRows,
            numberOfColumns: Configuration.numberOfColumns
        )
        basePhase = .running
        return [.collisionResolved(livesRemaining: gameState.lives)]
    }

    private func resetRun() {
        elapsedTimeAccumulator = 0
        collisionElapsedTime = 0
        roadPhase = 0
        safetyMarkerRows.removeAll()
        pauseReasons.removeAll()
        trafficRowSource.reset()
        gridState = GridState(
            numberOfRows: Configuration.numberOfRows,
            numberOfColumns: Configuration.numberOfColumns
        )
        gameState = GameState()
        lastLevelChangeImminent = false
    }

    private func setDifficulty(_ difficulty: GameDifficulty) {
        self.difficulty = difficulty
        rebuildGridCalculator()
    }

    private func setTrafficMode(_ trafficMode: GameTrafficMode) {
        self.trafficMode = trafficMode
        trafficRowSource = Self.makeTrafficRowSource(mode: trafficMode, randomSource: randomSource)
        rebuildGridCalculator()
    }

    private func rebuildGridCalculator() {
        gridCalculator = GridStateCalculator(
            trafficRowSource: trafficRowSource,
            timingConfiguration: difficulty.timingConfiguration
        )
    }

    /// Applies a validated non-production state used by previews and screenshot fixtures.
    @discardableResult
    func applyFixture(_ snapshot: GameSnapshot) -> Bool {
        guard snapshot.hasValidFixtureInvariants,
              snapshot.numberOfRows == Configuration.numberOfRows,
              snapshot.numberOfColumns == Configuration.numberOfColumns,
              snapshot.safetyMarkerRows.allSatisfy({ $0 < Configuration.numberOfRows }) else {
            return false
        }

        var restoredGrid = GridState(
            numberOfRows: Configuration.numberOfRows,
            numberOfColumns: Configuration.numberOfColumns
        )
        restoredGrid.grid = snapshot.grid.map { row in
            row.map(Self.cellState(for:))
        }
        gridState = restoredGrid
        gameState.score = snapshot.score
        gameState.lives = snapshot.lives
        difficulty = snapshot.difficulty
        roadPhase = snapshot.roadPhase
        safetyMarkerRows = snapshot.safetyMarkerRows
        pauseReasons = snapshot.activePauseReasons
        if snapshot.phase == .paused, pauseReasons.isEmpty {
            pauseReasons.insert(.overlay)
        }
        basePhase = snapshot.phase == .paused ? .running : snapshot.phase
        elapsedTimeAccumulator = 0
        collisionElapsedTime = 0
        lastLevelChangeImminent = GameState.isLevelChangeImminent(
            score: snapshot.score,
            windowPoints: snapshot.difficulty.speedAlertWindowPoints
        )
        rebuildGridCalculator()
        return true
    }

    private func shouldInsertSafetyRowBeforeNextLevel() -> Bool {
        let upcomingRowPoints = (1...Configuration.preLevelForecastRows).map { offset in
            carsCount(inRow: gridState.playerRowIndex - offset)
        }
        guard let levelChangeOffset = GameState.updatesUntilNextLevelChange(
            score: gameState.score,
            upcomingRowPoints: upcomingRowPoints
        ) else {
            return false
        }
        return Configuration.safetyRowOffsetsBeforeLevelChange.contains(levelChangeOffset)
    }

    private func carsCount(inRow rowIndex: Int) -> Int {
        guard rowIndex >= 0, rowIndex < gridState.numberOfRows else { return 0 }
        return gridState.grid[rowIndex].reduce(0) { partialResult, cell in
            cell == .Car ? partialResult + 1 : partialResult
        }
    }

    private func updateSafetyMarkerRows(for action: GridStateCalculator.Action) {
        let shiftedRows = safetyMarkerRows.compactMap { row -> Int? in
            guard row <= (Configuration.numberOfRows - 1) else { return nil }
            return row + 1
        }
        switch action {
        case .update:
            safetyMarkerRows = Array(shiftedRows.prefix(2))
        case .updateWithEmptyRow:
            safetyMarkerRows = Array(([0] + shiftedRows).prefix(2))
        case .moveCar:
            break
        }
    }

    private static func makeTrafficRowSource(
        mode: GameTrafficMode,
        randomSource: RandomSource
    ) -> TrafficRowSource {
        switch mode {
        case .random:
            RandomTrafficRowSource(randomSource: randomSource)
        case .seeded(let seed):
            IndexedTrafficRowSource(seed: seed)
        }
    }

    private static func occupant(for cell: GridState.CellState) -> GameGridOccupant {
        switch cell {
        case .Empty: .empty
        case .Car: .rival
        case .Player: .player
        case .Crash: .crash
        }
    }

    private static func cellState(for occupant: GameGridOccupant) -> GridState.CellState {
        switch occupant {
        case .empty: .Empty
        case .rival: .Car
        case .player: .Player
        case .crash: .Crash
        }
    }
}

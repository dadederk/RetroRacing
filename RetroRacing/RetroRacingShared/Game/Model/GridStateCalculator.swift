//
//  GridStateCalculator.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Pure grid engine that advances the race lanes and reports scoring or crash effects.
public final class GridStateCalculator {
    private let randomSource: RandomSource
    private let timingConfiguration: GridUpdateTimingConfiguration

    public init(randomSource: RandomSource, timingConfiguration: GridUpdateTimingConfiguration = .defaultTiming) {
        self.randomSource = randomSource
        self.timingConfiguration = timingConfiguration
    }

    public enum Effect: Equatable {
        case scored(points: Int)
        case crashed
    }

    public enum Action {
        case update
        case updateWithEmptyRow
        case moveCar(direction: Direction)
    }

    public enum Direction {
        case left
        case right
    }

    public func intervalForLevel(_ level: Int) -> TimeInterval {
        timingConfiguration.updateInterval(forLevel: level)
    }

    public func nextGrid(previousGrid: GridState,
                  actions: [Action] = []) -> (GridState, [Effect]) {
        var nextGridState = previousGrid
        var effects = [Effect]()

        for action in actions {
            var nextEffects = [Effect]()
            switch action {
            case .update:
                let randomRow = rowWithRandomValues(size: nextGridState.numberOfColumns)
                (nextGridState, nextEffects) = insert(row: randomRow, at: 0, forPreviousGridState: nextGridState)
                nextGridState = ensure(requiredNumberOfEmptyCells: 1, atRowIndex: 0, forPreviousGridState: nextGridState)
            case .updateWithEmptyRow:
                let emptyRow = rowWithEmptyValues(size: nextGridState.numberOfColumns)
                (nextGridState, nextEffects) = insert(row: emptyRow, at: 0, forPreviousGridState: nextGridState)
            case .moveCar(direction: let direction):
                nextGridState = movePlayer(toDirection: direction, forPreviousGridState: nextGridState)
            }
            effects.append(contentsOf: nextEffects)
        }

        return (nextGridState, effects)
    }

    /// Returns a new grid state by moving the player in the specified direction within the last row, if possible.
    private func movePlayer(toDirection direction: Direction, forPreviousGridState previousGridState: GridState) -> GridState {
        guard let playerPosition = previousGridState.playerRow().firstIndex(of: .Player) else {
            AppLog.error(AppLog.game, "GridStateCalculator.movePlayer – Player position not found, returning previous grid unchanged")
            return previousGridState
        }
        var newGridState = previousGridState
        var newPlayerPosition: Int

        switch direction {
        case .left: newPlayerPosition = ((playerPosition - 1) >= 0) ? playerPosition - 1 : playerPosition
        case .right: newPlayerPosition = ((playerPosition + 1) < previousGridState.numberOfColumns) ? playerPosition + 1 : playerPosition
        }

        newGridState.grid[previousGridState.playerRowIndex][playerPosition] = .Empty
        newGridState.grid[previousGridState.playerRowIndex][newPlayerPosition] = .Player

        return newGridState
    }

    /// Returns a new grid state by inserting the provided row at the specified index and removing the penultimate row. Also computes effects for crashes or scoring.
    private func insert(row newRow: [GridState.CellState], at rowIndex: Int, forPreviousGridState previousGridState: GridState) -> (GridState, [Effect]) {
        guard rowIndex >= 0 && rowIndex < previousGridState.numberOfRows else { fatalError("Grid row index out of bounds") }
        guard let playerPosition = previousGridState.playerRow().firstIndex(of: .Player) else {
            AppLog.error(AppLog.game, "GridStateCalculator.insert – Player position not found, returning previous grid and no effects")
            return (previousGridState, [])
        }
        let penultimateRowIndex = previousGridState.numberOfRows - 2
        let crash = previousGridState.grid[penultimateRowIndex][playerPosition] == GridState.CellState.Car
        let points = previousGridState.grid[penultimateRowIndex].reduce(0) { ($1 == .Car) ? ($0 + 1) : $0 }
        var effects = [Effect]()
        var newGridState = previousGridState

        newGridState.grid.remove(at: penultimateRowIndex)
        newGridState.grid.insert(newRow, at: rowIndex)

        if crash {
            effects.append(.crashed)
            newGridState.grid[previousGridState.playerRowIndex][playerPosition] = .Crash
        } else {
            effects.append(.scored(points: points))
        }

        return (newGridState, effects)
    }

    /// Ensures the specified row contains at least the required number of empty cells by emptying random non-empty cells.
    private func ensure(requiredNumberOfEmptyCells: Int, atRowIndex rowIndex: Int, forPreviousGridState previousGridState: GridState) -> GridState {
        guard rowIndex >= 0 && rowIndex < previousGridState.numberOfRows else { fatalError("Grid row index out of bounds") }
        let numberOfEmptyCells = previousGridState.grid[rowIndex].reduce(0) { $1 == .Empty ? $0 + 1 : $0 }
        let cellsToEmpty = requiredNumberOfEmptyCells - numberOfEmptyCells
        var newGridState = previousGridState
        var newRow = newGridState.grid[rowIndex]

        if cellsToEmpty > 0 {
            for _ in 0..<cellsToEmpty {
                newRow = rowEmptyingRandomCell(row: newRow)
            }
        }

        newGridState.grid[rowIndex] = newRow

        return newGridState
    }

    /// Generates a row of the specified size with random car or empty cell states.
    private func rowWithRandomValues(size: Int) -> [GridState.CellState] {
        var newArray = Array(repeating: GridState.CellState.Empty, count: size)

        for (index, _) in newArray.enumerated() {
            newArray[index] = (randomSource.nextInt(upperBound: 2) == 0) ? .Empty : .Car
        }

        return newArray
    }

    /// Generates an empty row of the specified size.
    private func rowWithEmptyValues(size: Int) -> [GridState.CellState] {
        Array(repeating: .Empty, count: size)
    }

    /// Returns a copy of the row with one random non-empty cell set to empty.
    private func rowEmptyingRandomCell(row: [GridState.CellState]) -> [GridState.CellState] {
        let indexesOfNonEmptyCells = row.enumerated().filter({ $1 != .Empty }).map({ $0.offset })
        guard !indexesOfNonEmptyCells.isEmpty else { return row }
        let randomPositionIndex = randomSource.nextInt(upperBound: indexesOfNonEmptyCells.count)
        let randomPosition = indexesOfNonEmptyCells[randomPositionIndex]
        var newRow = row

        newRow[randomPosition] = .Empty

        return newRow
    }
}

public struct GridUpdateTimingConfiguration {
    public let initialInterval: TimeInterval
    public let logDivider: Double
    public let minimumInterval: TimeInterval

    public init(
        initialInterval: TimeInterval,
        logDivider: Double,
        minimumInterval: TimeInterval = 0.05
    ) {
        self.initialInterval = initialInterval
        self.logDivider = logDivider
        self.minimumInterval = minimumInterval
    }

    public func updateInterval(forLevel level: Int) -> TimeInterval {
        max(minimumInterval, initialInterval - (log(Double(max(level, 1))) / logDivider))
    }

    public static let rapid = GridUpdateTimingConfiguration(initialInterval: 0.72, logDivider: 5.0, minimumInterval: 0.14)
    public static let fast = GridUpdateTimingConfiguration(initialInterval: 1.0, logDivider: 5.0, minimumInterval: 0.26)
    public static let cruise = GridUpdateTimingConfiguration(initialInterval: 1.32, logDivider: 5.0, minimumInterval: 0.42)
    public static let defaultTiming = rapid
}

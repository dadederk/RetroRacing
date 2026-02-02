import Foundation

/// `GridStateCalculator` is responsible for computing the next state of a grid-based car game.
///
/// This class manages all logic related to updating the grid, moving the player's car, handling
/// scoring, and detecting crashes. It operates on a `GridState` structure and provides effects
/// that describe significant game events (such as scoring or crashing).
///
/// This class is stateless and does not hold any state.
/// The primary method, `nextGrid(previousGrid:actions:)`, is a pure function: it has no side effects and does not mutate its input.
///
/// - The primary method, `nextGrid(previousGrid:actions:)`, takes the previous state of the grid
///   and a sequence of actions (such as updating the grid or moving the car), and returns a tuple
///   with the updated grid and a list of effects.
/// - The class defines action types (such as updating and moving the car) and corresponding
///   effects (like scoring points or crashing).
/// - Various private helper methods encapsulate logic for moving the car, inserting new rows,
///   ensuring a minimum number of empty cells, and generating random row values.
///
/// Usage of this type is generally internal to the game engine and not intended for direct
/// manipulation by UI components.
public final class GridStateCalculator {
    private let randomSource: RandomSource

    public init(randomSource: RandomSource = SystemRandomSource()) {
        self.randomSource = randomSource
    }

    public enum Effect: Equatable {
        case scored(points: Int)
        case crashed
    }

    public enum Action {
        case update
        case moveCar(direction: Direction)
    }

    public enum Direction {
        case left
        case right
    }

    public func nextGrid(previousGrid: GridState,
                  actions: [Action] = []) -> (GridState, [Effect]) {
        var nextGridState = previousGrid
        var effects = [Effect]()

        for action in actions {
            var nextEffects = [Effect]()
            switch action {
            case .update:
                (nextGridState, nextEffects) = insert(newRandomRowAtIndex: 0, forPreviousGridState: nextGridState)
                nextGridState = ensure(requiredNumberOfEmptyCells: 1, atRowIndex: 0, forPreviousGridState: nextGridState)
            case .moveCar(direction: let direction):
                nextGridState = movePlayer(toDirection: direction, forPreviousGridState: nextGridState)
            }
            effects.append(contentsOf: nextEffects)
        }

        return (nextGridState, effects)
    }

    /// Returns a new grid state by moving the player in the specified direction within the last row, if possible.
    private func movePlayer(toDirection direction: Direction, forPreviousGridState previousGridState: GridState) -> GridState {
        guard let playerPosition = previousGridState.playerRow().firstIndex(of: .Player) else { fatalError("Player position not found") }
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

    /// Returns a new grid state by inserting a random row at the specified index and removing the penultimate row. Also computes effects for crashes or scoring.
    private func insert(newRandomRowAtIndex rowIndex: Int, forPreviousGridState previousGridState: GridState) -> (GridState, [Effect]) {
        guard rowIndex >= 0 && rowIndex < previousGridState.numberOfRows else { fatalError("Grid row index out of bounds") }
        guard let playerPosition = previousGridState.playerRow().firstIndex(of: .Player) else { fatalError("Player position not found") }
        let newRandomRow = rowWithRandomValues(size: previousGridState.numberOfColumns)
        let penultimateRowIndex = previousGridState.numberOfRows - 2
        let crash = previousGridState.grid[penultimateRowIndex][playerPosition] == GridState.CellState.Car
        let points = previousGridState.grid[penultimateRowIndex].reduce(0) { ($1 == .Car) ? ($0 + 1) : $0 }
        var effects = [Effect]()
        var newGridState = previousGridState

        newGridState.grid.remove(at: penultimateRowIndex)
        newGridState.grid.insert(newRandomRow, at: rowIndex)

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

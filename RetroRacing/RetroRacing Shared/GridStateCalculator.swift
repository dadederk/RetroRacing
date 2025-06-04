import Foundation

final class GridStateCalculator {
    enum Effect {
        case scored(points: Int)
        case crashed
    }
    
    enum Action {
        case update
        case moveCar(direction: Direction)
    }
    
    enum Direction {
        case left
        case right
    }
    
    func nextGrid(previousGrid: GridState,
                  actions:[Action] = []) -> (GridState, [Effect]) {
        var nextGridState = previousGrid
        var effects = [Effect]()
        
        for action in actions {
            switch action {
            case .update:
                (nextGridState, effects) = gridStateInserting(newRandomRowAtIndex: 0, forPreviousGridState: nextGridState)
                nextGridState = gridStateEnsuring(requiredNumberOfEmptyCells: 1, atRowIndex: 0, forPreviousGridState: nextGridState)
            case .moveCar(direction: let direction):
                nextGridState = gridStateMovingPlayer(toDirection: direction, forPreviousGridState: nextGridState)
            }
        }
        
        return (nextGridState, effects)
    }
    
    private func gridStateMovingPlayer(toDirection direction: Direction, forPreviousGridState previousGridState: GridState) -> GridState {
        guard let playerPosition = previousGridState.grid[previousGridState.numberOfRows - 1].firstIndex(of: .Player) else { fatalError("Player position not found") }
        var newGridState = previousGridState
        var newPlayerPosition: Int
        
        switch direction {
        case .left: newPlayerPosition = ((playerPosition - 1) >= 0) ? playerPosition - 1 : playerPosition
        case .right: newPlayerPosition = ((playerPosition + 1) < previousGridState.numberOfColumns) ? playerPosition + 1 : playerPosition
        }
        
        newGridState.grid[previousGridState.numberOfRows - 1][playerPosition] = .Empty
        newGridState.grid[previousGridState.numberOfRows - 1][newPlayerPosition] = .Player
        
        return newGridState
    }
    
    private func gridStateInserting(newRandomRowAtIndex rowIndex: Int, forPreviousGridState previousGridState: GridState) -> (GridState, [Effect]) {
        guard rowIndex >= 0 && rowIndex < previousGridState.numberOfRows else { fatalError("Grid row index out of bounds") }
        guard let playerPosition = previousGridState.grid[previousGridState.numberOfRows - 1].firstIndex(of: .Player) else { fatalError("Player position not found") }
        let newRandomRow = rowWithRandomValues(size: previousGridState.numberOfColumns)
        let penultimateRowIndex = previousGridState.numberOfRows - 2
        let crash = previousGridState.grid[penultimateRowIndex][playerPosition] == GridState.CellState.Car
        let points = previousGridState.grid[penultimateRowIndex].reduce(0) { ($1 == .Car) ? ($0 + 1) : $0  }
        var effects = [Effect]()
        var newGridState = previousGridState
        
        newGridState.grid.remove(at: penultimateRowIndex)
        newGridState.grid.insert(newRandomRow, at: rowIndex)
        
        if crash {
            effects.append(.crashed)
            newGridState.grid[previousGridState.numberOfRows - 1][playerPosition] = .Crash
        } else {
            effects.append(.scored(points: points))
        }
        
        return (newGridState, effects)
    }
    
    private func gridStateEnsuring(requiredNumberOfEmptyCells: Int, atRowIndex rowIndex: Int, forPreviousGridState previousGridState: GridState) -> GridState {
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
    
    private func rowWithRandomValues(size: Int) -> [GridState.CellState] {
        var newArray = Array(repeating: GridState.CellState.Empty, count: size)
        
        for (index, _) in newArray.enumerated() {
            newArray[index] = (Int.random(in: 0...1) == 0) ? .Empty : .Car
        }
        
        return newArray
    }
    
    private func rowEmptyingRandomCell(row: [GridState.CellState]) -> [GridState.CellState] {
        let indexesOfNonEmptyCells = row.enumerated().filter({ $1 != .Empty }).map({ $0.offset })
        let randomPosition = Int.random(in: 0..<indexesOfNonEmptyCells.count)
        var newRow = row
        
        newRow[randomPosition] = .Empty
        
        return newRow
    }
}

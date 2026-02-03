//
//  GridState.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// In-memory representation of the visible race grid and occupant states.
public struct GridState {
    enum CellState: Equatable {
        case Empty
        case Car
        case Player
        case Crash
    }

    let numberOfRows: Int
    let numberOfColumns: Int

    var grid: [[CellState]]
    var hasCrashed: Bool {
        grid.contains(where: { $0.contains(where: { $0 == .Crash }) })
    }
    var playerRowIndex: Int {
        numberOfRows - 1
    }

    init(numberOfRows: Int, numberOfColumns: Int) {
        self.numberOfRows = numberOfRows
        self.numberOfColumns = numberOfColumns

        grid = Array(repeating: Array(repeating: CellState.Empty, count: numberOfColumns), count: numberOfRows)

        grid[numberOfRows - 1][numberOfColumns / 2] = .Player
    }

    func playerRow() -> [CellState] {
        grid[playerRowIndex]
    }
}

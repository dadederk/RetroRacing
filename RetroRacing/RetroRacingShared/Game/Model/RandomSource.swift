//
//  RandomSource.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Cross-platform random source abstraction for deterministic game logic.
public protocol RandomSource: AnyObject {
    func nextInt(upperBound: Int) -> Int
}

/// Uses Swift's system random number generator. Available on all platforms including watchOS.
public final class SystemRandomSource: RandomSource {
    public init() {}

    public func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int.random(in: 0..<upperBound)
    }
}

/// Produces traffic rows for the grid engine.
protocol TrafficRowSource: AnyObject {
    func nextTrafficRow(numberOfColumns: Int) -> [GridState.CellState]
    func reset()
}

/// Preserves the existing solo-play traffic generation behavior.
final class RandomTrafficRowSource: TrafficRowSource {
    private let randomSource: RandomSource

    init(randomSource: RandomSource) {
        self.randomSource = randomSource
    }

    func nextTrafficRow(numberOfColumns: Int) -> [GridState.CellState] {
        guard numberOfColumns > 0 else { return [] }
        var row = Array(repeating: GridState.CellState.Empty, count: numberOfColumns)

        for index in row.indices {
            row[index] = (randomSource.nextInt(upperBound: 2) == 0) ? .Empty : .Car
        }

        return rowWithAtLeastOneEmptyCell(row)
    }

    func reset() {}

    private func rowWithAtLeastOneEmptyCell(_ row: [GridState.CellState]) -> [GridState.CellState] {
        let indexesOfNonEmptyCells = row.enumerated().filter { $0.element != .Empty }.map(\.offset)
        guard indexesOfNonEmptyCells.count == row.count else { return row }
        guard indexesOfNonEmptyCells.isEmpty == false else { return row }

        let randomPositionIndex = randomSource.nextInt(upperBound: indexesOfNonEmptyCells.count)
        let randomPosition = indexesOfNonEmptyCells[randomPositionIndex]
        var newRow = row
        newRow[randomPosition] = .Empty
        return newRow
    }
}

/// Generates SharePlay traffic rows from an indexed seed so local timing differences cannot
/// desynchronize the hazard sequence.
final class IndexedTrafficRowSource: TrafficRowSource {
    let seed: UInt64
    private(set) var generatedRowCount = 0

    init(seed: UInt64) {
        self.seed = seed
    }

    func nextTrafficRow(numberOfColumns: Int) -> [GridState.CellState] {
        guard numberOfColumns > 0 else { return [] }
        let rowSeed = Self.mixed(seed: seed, index: UInt64(generatedRowCount))
        generatedRowCount += 1

        var row = (0..<numberOfColumns).map { column -> GridState.CellState in
            ((rowSeed >> UInt64(column % 64)) & 1) == 0 ? .Empty : .Car
        }

        if row.allSatisfy({ $0 == .Car }) {
            let emptyColumnSeed = Self.mix(rowSeed ^ 0xD1B5_4A32_D192_ED03)
            let emptyColumn = Int(emptyColumnSeed % UInt64(numberOfColumns))
            row[emptyColumn] = .Empty
        }

        return row
    }

    func reset() {
        generatedRowCount = 0
    }

    private static func mixed(seed: UInt64, index: UInt64) -> UInt64 {
        mix(seed &+ (index &* 0x9E37_79B9_7F4A_7C15))
    }

    private static func mix(_ value: UInt64) -> UInt64 {
        var result = value
        result = (result ^ (result >> 30)) &* 0xBF58_476D_1CE4_E5B9
        result = (result ^ (result >> 27)) &* 0x94D0_49BB_1331_11EB
        return result ^ (result >> 31)
    }
}

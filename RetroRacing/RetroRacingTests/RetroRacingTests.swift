//
//  RetroRacingTests.swift
//  RetroRacingTests
//
//  Created by Dani on 06/04/2025.
//

import XCTest
@testable import RetroRacing

final class GridStateCalculatorTests: XCTestCase {
    func testMoveLeftMovesPlayersCarFromCenterToTheLeft() throws {
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid = [
            [.Empty, .Car, .Car],
            [.Empty, .Car, .Empty],
            [.Car, .Car, .Empty],
            [.Empty, .Car, .Empty],
            [.Empty, .Player, .Car],
        ]
        let sut = GridStateCalculator()
        let (newGridState, _) = sut.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .left)])
        
        XCTAssertEqual(newGridState.grid[4][0], .Player)
    }
    
    func testMoveRightMovesPlayersCarFromCenterToTheRigth() throws {
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid = [
            [.Empty, .Car, .Car],
            [.Empty, .Car, .Empty],
            [.Car, .Car, .Empty],
            [.Empty, .Car, .Empty],
            [.Empty, .Player, .Empty],
        ]
        let sut = GridStateCalculator()
        let (newGridState, _) = sut.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .right)])
        XCTAssertEqual(newGridState.grid[4][2], .Player)
    }
    
    func testMoveLeftAtLeftmostColumnDoesNotMove() {
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid = [
            [.Car, .Empty, .Empty],
            [.Empty, .Car, .Empty],
            [.Car, .Car, .Empty],
            [.Empty, .Car, .Empty],
            [.Player, .Empty, .Car],
        ]
        let sut = GridStateCalculator()
        let (newGridState, _) = sut.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .left)])
        XCTAssertEqual(newGridState.grid[4][0], .Player)
    }

    func testMoveRightAtRightmostColumnDoesNotMove() {
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid = [
            [.Car, .Empty, .Car],
            [.Empty, .Car, .Empty],
            [.Car, .Car, .Empty],
            [.Empty, .Car, .Empty],
            [.Empty, .Empty, .Player],
        ]
        let sut = GridStateCalculator()
        let (newGridState, _) = sut.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .right)])
        XCTAssertEqual(newGridState.grid[4][2], .Player)
    }

    func testPlayersCarMovesToSameColumnAsCarCrashesOnUpdate() {
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid = [
            [.Empty, .Empty, .Empty],
            [.Empty, .Car, .Empty],
            [.Empty, .Empty, .Empty],
            [.Car, .Empty, .Empty],
            [.Empty, .Player, .Empty],
        ]
        let sut = GridStateCalculator()
        let (newGridState, _) = sut.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .left), .update])
        XCTAssertEqual(newGridState.grid[4][0], .Crash)
    }
    
    func testPlayersCarMovesToColumnWithNoCarOnPreviousRowScoresPointsOnUpdate() {
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid = [
            [.Empty, .Empty, .Empty],
            [.Empty, .Car, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Car, .Empty],
            [.Empty, .Player, .Empty],
        ]
        let sut = GridStateCalculator()
        let (_, effects) = sut.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .left), .update])
        let scoredPoints = effects.reduce(0) { partialResult, effect in
            if case GridStateCalculator.Effect.scored(points: let points) = effect {
                return partialResult + points
            }
            return partialResult
        }
        XCTAssertGreaterThan(scoredPoints, 0)
    }

//    func testEnsureAddsEmptyCellsWhenNeeded() {
//        var gridState = GridState(numberOfRows: 3, numberOfColumns: 3)
//        gridState.grid = [
//            [.Car, .Car, .Car],
//            [.Car, .Car, .Car],
//            [.Empty, .Player, .Empty],
//        ]
//        let sut = GridStateCalculator()
//        let ensured = sut.nextGrid(previousGrid: gridState, actions: [.update])
//        // At least one empty cell in row 0
//        let emptyCells = ensured.0.grid[0].filter { $0 == .Empty }.count
//        XCTAssertGreaterThanOrEqual(emptyCells, 1)
//    }
//
//    func testSequenceMoveAndUpdate() {
//        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
//        gridState.grid = [
//            [.Empty, .Car, .Empty],
//            [.Empty, .Empty, .Empty],
//            [.Empty, .Empty, .Empty],
//            [.Empty, .Empty, .Empty],
//            [.Empty, .Player, .Empty],
//        ]
//        let sut = GridStateCalculator()
//        let (afterMove, _) = sut.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .right)])
//        let (afterUpdate, effects) = sut.nextGrid(previousGrid: afterMove, actions: [.update])
//        XCTAssertTrue(effects.count > 0)
//    }
//
//    func testNoCrashIfPlayerNotInPathOfCar() {
//        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
//        gridState.grid = [
//            [.Car, .Empty, .Empty],
//            [.Empty, .Car, .Empty],
//            [.Car, .Car, .Empty],
//            [.Empty, .Car, .Empty],
//            [.Empty, .Player, .Empty],
//        ]
//        let sut = GridStateCalculator()
//        let (newGridState, effects) = sut.nextGrid(previousGrid: gridState, actions: [.update])
//        let crashed = effects.contains { if case .crashed = $0 { return true } else { return false } }
//        XCTAssertFalse(crashed)
//    }
}

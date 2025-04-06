//
//  RetroRacingTests.swift
//  RetroRacingTests
//
//  Created by Dani on 06/04/2025.
//

import XCTest
@testable import RetroRacing

final class GridStateCalculatorTests: XCTestCase {

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {

    }

    func testMoveLeftMovesPlayersCarFromCenterToTheLeft() throws {
        let gameState = GameState()
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid = [
            [.Empty, .Car, .Car],
            [.Empty, .Car, .Empty],
            [.Car, .Car, .Empty],
            [.Empty, .Car, .Empty],
            [.Empty, .Player, .Car],
        ]
        let sut = GridStateCalculator()
        
        let (newGridState, _) = sut.nextGrid(previousGrid: gridState, gameState: gameState, actions: [.moveCar(direction: .left)])
        
        XCTAssertEqual(newGridState.grid[4][0], .Player)
    }
    
    func testMoveRightMovesPlayersCarFromCenterToTheRigth() throws {
        let gameState = GameState()
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid = [
            [.Empty, .Car, .Car],
            [.Empty, .Car, .Empty],
            [.Car, .Car, .Empty],
            [.Empty, .Car, .Empty],
            [.Empty, .Player, .Empty],
        ]
        let sut = GridStateCalculator()
        
        let (newGridState, _) = sut.nextGrid(previousGrid: gridState, gameState: gameState, actions: [.moveCar(direction: .right)])
        
        XCTAssertEqual(newGridState.grid[4][2], .Player)
    }
}

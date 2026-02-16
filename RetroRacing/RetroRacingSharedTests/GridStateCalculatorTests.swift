import XCTest
@testable import RetroRacingShared

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
        let sut = GridStateCalculator(randomSource: MockRandomSource())
        let (newGridState, _) = sut.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .left)])

        XCTAssertEqual(newGridState.grid[4][0], .Player)
    }

    func testMoveRightMovesPlayersCarFromCenterToTheRight() throws {
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid = [
            [.Empty, .Car, .Car],
            [.Empty, .Car, .Empty],
            [.Car, .Car, .Empty],
            [.Empty, .Car, .Empty],
            [.Empty, .Player, .Empty],
        ]
        let sut = GridStateCalculator(randomSource: MockRandomSource())
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
        let sut = GridStateCalculator(randomSource: MockRandomSource())
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
        let sut = GridStateCalculator(randomSource: MockRandomSource())
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
        let sut = GridStateCalculator(randomSource: MockRandomSource())
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
        let sut = GridStateCalculator(randomSource: MockRandomSource())
        let (_, effects) = sut.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .left), .update])
        let scoredPoints = effects.reduce(0) { partialResult, effect in
            if case GridStateCalculator.Effect.scored(points: let points) = effect {
                return partialResult + points
            }
            return partialResult
        }
        XCTAssertGreaterThan(scoredPoints, 0)
    }

    func testUpdateIntervalDecreasesAsLevelIncreases() {
        let config = GridUpdateTimingConfiguration(initialInterval: 0.6, logDivider: 4)
        let calculator = GridStateCalculator(randomSource: MockRandomSource(), timingConfiguration: config)

        let level1 = calculator.intervalForLevel(1)
        let level5 = calculator.intervalForLevel(5)

        XCTAssertGreaterThan(level1, level5)
        XCTAssertGreaterThan(level1, 0)
        XCTAssertGreaterThan(level5, 0)
    }

    func testGivenUpdateWithEmptyRowWhenAdvancingGridThenTopRowIsEmpty() {
        // Given
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid = [
            [.Car, .Car, .Car],
            [.Car, .Car, .Car],
            [.Car, .Car, .Car],
            [.Car, .Empty, .Empty],
            [.Empty, .Player, .Empty],
        ]
        let sut = GridStateCalculator(randomSource: MockRandomSource())

        // When
        let (newGridState, effects) = sut.nextGrid(previousGrid: gridState, actions: [.updateWithEmptyRow])

        // Then
        XCTAssertEqual(effects, [.scored(points: 1)])
        XCTAssertEqual(newGridState.grid[0], [.Empty, .Empty, .Empty])
        XCTAssertEqual(newGridState.grid[1], [.Car, .Car, .Car])
    }

    func testGivenUpdateWithEmptyRowWhenAdvancingGridThenExistingRowsAreNotCleared() {
        // Given
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid = [
            [.Car, .Empty, .Car],
            [.Empty, .Car, .Empty],
            [.Car, .Car, .Empty],
            [.Empty, .Empty, .Car],
            [.Empty, .Player, .Empty],
        ]
        let expectedShiftedRow = gridState.grid[0]
        let sut = GridStateCalculator(randomSource: MockRandomSource())

        // When
        let (newGridState, _) = sut.nextGrid(previousGrid: gridState, actions: [.updateWithEmptyRow])

        // Then
        XCTAssertEqual(newGridState.grid[0], [.Empty, .Empty, .Empty])
        XCTAssertEqual(newGridState.grid[1], expectedShiftedRow)
    }

    func testGivenDifficultyTimingWhenComparingLevelOneIntervalsThenCruiseIsSlowestAndRapidIsFastest() {
        // Given
        let cruiseCalculator = GridStateCalculator(
            randomSource: MockRandomSource(),
            timingConfiguration: GameDifficulty.cruise.timingConfiguration
        )
        let fastCalculator = GridStateCalculator(
            randomSource: MockRandomSource(),
            timingConfiguration: GameDifficulty.fast.timingConfiguration
        )
        let rapidCalculator = GridStateCalculator(
            randomSource: MockRandomSource(),
            timingConfiguration: GameDifficulty.rapid.timingConfiguration
        )

        // When
        let cruiseInterval = cruiseCalculator.intervalForLevel(1)
        let fastInterval = fastCalculator.intervalForLevel(1)
        let rapidInterval = rapidCalculator.intervalForLevel(1)

        // Then
        XCTAssertGreaterThan(cruiseInterval, fastInterval)
        XCTAssertGreaterThan(fastInterval, rapidInterval)
    }
}

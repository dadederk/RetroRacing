//
//  GameEngineTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 05/08/2026.
//

import XCTest
@testable import RetroRacingShared

@MainActor
final class GameEngineTests: XCTestCase {
    func testGivenRunningEngineWhenSafeRivalPassesThenScoreIncreases() {
        // Given
        let engine = makeEngine(values: [1, 0, 0])
        engine.handle(.start)

        // When
        let events = advanceRows(5, engine: engine)

        // Then
        XCTAssertEqual(engine.snapshot.score, 1)
        XCTAssertTrue(events.contains(.scoreChanged(score: 1)))
        XCTAssertEqual(engine.snapshot.phase, .running)
    }

    func testGivenRunningEngineWhenRivalReachesPlayerThenCollisionConsumesLife() {
        // Given
        let engine = makeEngine(values: [0, 1, 0])
        engine.handle(.start)

        // When
        let events = advanceRows(5, engine: engine)

        // Then
        XCTAssertEqual(engine.snapshot.lives, 2)
        XCTAssertEqual(engine.snapshot.phase, .collision)
        XCTAssertTrue(events.contains(.collision(livesRemaining: 2)))
    }

    func testGivenRecoverableCollisionWhenActiveRecoveryTimeCompletesThenRunContinues() {
        // Given
        let engine = makeEngine(values: [0, 1, 0])
        engine.handle(.start)
        _ = advanceRows(5, engine: engine)

        // When
        let earlyEvents = engine.handle(.tick(elapsedTime: 0.74))
        let completionEvents = engine.handle(.tick(elapsedTime: 0.01))

        // Then
        XCTAssertTrue(earlyEvents.isEmpty)
        XCTAssertEqual(completionEvents, [.collisionResolved(livesRemaining: 2)])
        XCTAssertEqual(engine.snapshot.phase, .running)
        XCTAssertEqual(engine.snapshot.playerColumn, 1)
        XCTAssertFalse(engine.snapshot.grid.joined().contains(.rival))
    }

    func testGivenRecoverableCollisionWhenExplicitlyResolvingThenRunContinuesImmediately() {
        // Given
        let engine = makeEngine(values: [0, 1, 0])
        engine.handle(.start)
        _ = advanceRows(5, engine: engine)

        // When
        let events = engine.handle(.resolveCollision)

        // Then
        XCTAssertEqual(events, [.collisionResolved(livesRemaining: 2)])
        XCTAssertEqual(engine.snapshot.phase, .running)
        XCTAssertEqual(engine.snapshot.playerColumn, 1)
        XCTAssertFalse(engine.snapshot.grid.joined().contains(.rival))
    }

    func testGivenCollisionWhenAppIsInactiveThenBackgroundTimeDoesNotResolveIt() {
        // Given
        let engine = makeEngine(values: [0, 1, 0])
        engine.handle(.start)
        _ = advanceRows(5, engine: engine)
        engine.handle(.tick(elapsedTime: 0.25))
        engine.handle(.setPause(reason: .appInactive, isActive: true))

        // When
        engine.handle(.tick(elapsedTime: 60))
        engine.handle(.setPause(reason: .appInactive, isActive: false))
        let beforeBoundary = engine.handle(.tick(elapsedTime: 0.49))
        let boundary = engine.handle(.tick(elapsedTime: 0.01))

        // Then
        XCTAssertTrue(beforeBoundary.isEmpty)
        XCTAssertEqual(boundary, [.collisionResolved(livesRemaining: 2)])
    }

    func testGivenOneLifeRemainingWhenCollisionResolvesThenGameOverIsEmitted() {
        // Given
        let engine = makeEngine(values: [0, 1, 0])
        engine.handle(.start)
        for collisionIndex in 0..<3 {
            _ = advanceRows(5, engine: engine)
            if collisionIndex < 2 {
                engine.handle(.tick(elapsedTime: 0.75))
            }
        }

        // When
        let events = engine.handle(.tick(elapsedTime: 0.75))

        // Then
        XCTAssertEqual(engine.snapshot.lives, 0)
        XCTAssertEqual(engine.snapshot.phase, .gameOver)
        XCTAssertEqual(events, [.gameOver(score: 0)])
    }

    func testGivenRepeatedMovementWhenReachingLeftEdgeThenPlayerStaysInBounds() {
        assertMovementBoundary(direction: .left, expectedColumn: 0)
    }

    func testGivenRepeatedMovementWhenReachingRightEdgeThenPlayerStaysInBounds() {
        assertMovementBoundary(direction: .right, expectedColumn: 2)
    }

    func testGivenEveryPauseReasonWhenClearedIndividuallyThenFinalLockControlsResume() {
        // Given
        let engine = makeEngine(values: [0])
        engine.handle(.start)
        let reasons: [GamePauseReason] = [.user, .overlay, .presentationTransition, .appInactive]
        reasons.forEach { engine.handle(.setPause(reason: $0, isActive: true)) }

        // When / Then
        for reason in reasons.dropLast() {
            engine.handle(.setPause(reason: reason, isActive: false))
            XCTAssertEqual(engine.snapshot.phase, .paused)
        }
        engine.handle(.setPause(reason: .appInactive, isActive: false))
        XCTAssertEqual(engine.snapshot.phase, .running)
    }

    func testGivenUserPausedRunWhenPresentationLockClearsThenUserPauseIsPreserved() {
        // Given
        let engine = makeEngine(values: [0])
        engine.handle(.start)
        engine.handle(.setPause(reason: .user, isActive: true))
        engine.handle(.setPause(reason: .presentationTransition, isActive: true))

        // When
        engine.handle(.setPause(reason: .presentationTransition, isActive: false))

        // Then
        XCTAssertEqual(engine.snapshot.phase, .paused)
        XCTAssertEqual(engine.snapshot.activePauseReasons, [.user])
    }

    func testGivenSameSeedWhenApplyingSameCommandsThenSnapshotsMatch() {
        // Given
        let first = GameEngine(
            randomSource: SequenceRandomSource(values: [0]),
            difficulty: .fast,
            trafficMode: .seeded(64)
        )
        let second = GameEngine(
            randomSource: SequenceRandomSource(values: [1]),
            difficulty: .fast,
            trafficMode: .seeded(64)
        )
        let commands: [GameCommand] = [
            .start,
            .tick(elapsedTime: 1),
            .move(.left),
            .tick(elapsedTime: 1),
            .move(.right),
            .tick(elapsedTime: 1)
        ]

        // When
        commands.forEach {
            first.handle($0)
            second.handle($0)
        }

        // Then
        XCTAssertEqual(first.snapshot, second.snapshot)
    }

    func testGivenAbsoluteLaneSelectionsWhenResolvingThenOnlyOneBoundedMoveIsReturned() {
        // Given / When / Then
        XCTAssertEqual(
            GameLaneSelectionResolver.direction(selectedLane: 0, currentLane: 1, laneCount: 3),
            .left
        )
        XCTAssertEqual(
            GameLaneSelectionResolver.direction(selectedLane: 2, currentLane: 1, laneCount: 3),
            .right
        )
        XCTAssertNil(
            GameLaneSelectionResolver.direction(selectedLane: 1, currentLane: 1, laneCount: 3)
        )
        XCTAssertNil(
            GameLaneSelectionResolver.direction(selectedLane: 3, currentLane: 1, laneCount: 3)
        )
    }

    func testGivenInvalidFixtureWhenApplyingThenEngineSnapshotIsUnchanged() {
        // Given
        let engine = makeEngine(values: [0])
        let initialSnapshot = engine.snapshot
        let invalidFixture = GameSnapshot(
            phase: .running,
            grid: [[.player]],
            playerColumn: 0,
            score: 0,
            lives: GameState.initialLives,
            level: 1,
            roadPhase: 0,
            safetyMarkerRows: [],
            difficulty: .rapid,
            activePauseReasons: []
        )

        // When
        let didApply = engine.applyFixture(invalidFixture)

        // Then
        XCTAssertFalse(didApply)
        XCTAssertEqual(engine.snapshot, initialSnapshot)
    }

    func testGivenValidAndInvalidSnapshotDataWhenBuildingFixturesThenOnlyValidSnapshotIsReturned() {
        // Given
        let validGrid: [[GameGridOccupant]] = [
            [.empty, .empty, .empty],
            [.empty, .empty, .empty],
            [.empty, .rival, .empty],
            [.empty, .empty, .empty],
            [.empty, .player, .empty],
        ]

        // When
        let valid = GameSnapshot.fixture(
            phase: .paused,
            grid: validGrid,
            playerColumn: 1,
            score: 12,
            lives: 2,
            level: 2,
            roadPhase: 1,
            safetyMarkerRows: [2],
            difficulty: .rapid,
            activePauseReasons: [.overlay]
        )
        let invalid = GameSnapshot.fixture(
            phase: .paused,
            grid: validGrid,
            playerColumn: 4,
            score: 12,
            lives: 2,
            level: 2,
            roadPhase: 1,
            safetyMarkerRows: [2],
            difficulty: .rapid,
            activePauseReasons: [.overlay]
        )

        // Then
        XCTAssertNotNil(valid)
        XCTAssertNil(invalid)
    }

    private func makeEngine(values: [Int]) -> GameEngine {
        GameEngine(randomSource: SequenceRandomSource(values: values), difficulty: .rapid)
    }

    private func advanceRows(_ count: Int, engine: GameEngine) -> [GameEvent] {
        (0..<count).flatMap { _ in
            engine.handle(.tick(elapsedTime: 0.61))
        }
    }

    private func assertMovementBoundary(direction: GameMoveDirection, expectedColumn: Int) {
        // Given
        let engine = makeEngine(values: [0])
        engine.handle(.start)

        // When
        for _ in 0..<4 {
            engine.handle(.move(direction))
        }

        // Then
        XCTAssertEqual(engine.snapshot.playerColumn, expectedColumn)
    }
}

private final class SequenceRandomSource: RandomSource {
    private let values: [Int]
    private var index = 0

    init(values: [Int]) {
        self.values = values
    }

    func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0, values.isEmpty == false else { return 0 }
        let value = values[index % values.count]
        index += 1
        return min(max(value, 0), upperBound - 1)
    }
}

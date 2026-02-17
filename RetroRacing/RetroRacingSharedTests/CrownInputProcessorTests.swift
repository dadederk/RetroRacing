import XCTest
@testable import RetroRacingShared

final class CrownInputProcessorTests: XCTestCase {
    func testGivenAccumulatedRotationBelowThresholdWhenHandlingDeltaThenNoMoveIsTriggered() {
        // Given
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        // When
        let first = processor.handleRotationDelta(0.10)
        let second = processor.handleRotationDelta(0.10)
        let third = processor.handleRotationDelta(0.09)

        // Then
        XCTAssertEqual(first, .none)
        XCTAssertEqual(second, .none)
        XCTAssertEqual(third, .none)
    }

    func testGivenAccumulatedRotationCrossesThresholdWhenHandlingDeltaThenMoveMatchesRotationDirection() {
        // Given
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        // When
        let first = processor.handleRotationDelta(0.10)
        let second = processor.handleRotationDelta(0.10)
        let third = processor.handleRotationDelta(0.11)
        processor.markIdle()
        let fourth = processor.handleRotationDelta(-0.10)
        let fifth = processor.handleRotationDelta(-0.10)
        let sixth = processor.handleRotationDelta(-0.11)

        // Then
        XCTAssertEqual(first, .none)
        XCTAssertEqual(second, .none)
        XCTAssertEqual(third, .moveRight)
        XCTAssertEqual(fourth, .none)
        XCTAssertEqual(fifth, .none)
        XCTAssertEqual(sixth, .moveLeft)
    }

    func testGivenRotationAlreadyTriggeredWhenHandlingAdditionalDeltaThenMoveIsIgnoredUntilIdle() {
        // Given
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        // When
        let first = processor.handleRotationDelta(0.31)
        let second = processor.handleRotationDelta(0.31)
        processor.markIdle()
        let third = processor.handleRotationDelta(-0.31)

        // Then
        XCTAssertEqual(first, .moveRight)
        XCTAssertEqual(second, .none)
        XCTAssertEqual(third, .moveLeft)
    }

    func testGivenPartialAccumulationWhenProcessorBecomesIdleThenAccumulationResets() {
        // Given
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        // When
        let first = processor.handleRotationDelta(0.20)
        processor.markIdle()
        let second = processor.handleRotationDelta(0.11)

        // Then
        XCTAssertEqual(first, .none)
        XCTAssertEqual(second, .none)
    }
}

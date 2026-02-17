import XCTest
@testable import RetroRacingShared

final class CrownInputProcessorTests: XCTestCase {
    func testRotationBelowThresholdDoesNotTriggerMove() {
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        XCTAssertEqual(processor.handleRotationDelta(0.29), .none)
        XCTAssertEqual(processor.handleRotationDelta(-0.29), .none)
        XCTAssertEqual(processor.handleRotationDelta(0.31), .moveRight)
    }

    func testRotationTriggersOnceUntilIdle() {
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        XCTAssertEqual(processor.handleRotationDelta(0.31), .moveRight)
        XCTAssertEqual(processor.handleRotationDelta(0.31), .none)

        processor.markIdle()

        XCTAssertEqual(processor.handleRotationDelta(-0.31), .moveLeft)
    }

    func testIdleRestoresRotationAfterIgnoredMovement() {
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        XCTAssertEqual(processor.handleRotationDelta(0.31), .moveRight)
        XCTAssertEqual(processor.handleRotationDelta(0.31), .none)

        processor.markIdle()

        XCTAssertEqual(processor.handleRotationDelta(0.31), .moveRight)
    }
}

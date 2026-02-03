import XCTest
@testable import RetroRacingShared

final class CrownInputProcessorTests: XCTestCase {
    func testRotationBelowThresholdDoesNotTriggerMove() {
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        XCTAssertEqual(processor.handleRotationDelta(0.04), .none)
        XCTAssertEqual(processor.handleRotationDelta(-0.04), .none)
        XCTAssertEqual(processor.handleRotationDelta(0.06), .moveRight)
    }

    func testRotationTriggersOnceUntilIdle() {
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        XCTAssertEqual(processor.handleRotationDelta(0.06), .moveRight)
        XCTAssertEqual(processor.handleRotationDelta(0.06), .none)

        processor.markIdle()

        XCTAssertEqual(processor.handleRotationDelta(-0.06), .moveLeft)
    }

    func testIdleRestoresRotationAfterIgnoredMovement() {
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        XCTAssertEqual(processor.handleRotationDelta(0.06), .moveRight)
        XCTAssertEqual(processor.handleRotationDelta(0.06), .none)

        processor.markIdle()

        XCTAssertEqual(processor.handleRotationDelta(0.06), .moveRight)
    }
}

import XCTest
@testable import RetroRacingShared

final class CrownInputProcessorTests: XCTestCase {
    func testRotationBelowThresholdDoesNotTriggerMove() {
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        XCTAssertEqual(processor.handleRotationDelta(0.14), .none)
        XCTAssertEqual(processor.handleRotationDelta(-0.14), .none)
        XCTAssertEqual(processor.handleRotationDelta(0.16), .moveRight)
    }

    func testRotationTriggersOnceUntilIdle() {
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        XCTAssertEqual(processor.handleRotationDelta(0.16), .moveRight)
        XCTAssertEqual(processor.handleRotationDelta(0.16), .none)

        processor.markIdle()

        XCTAssertEqual(processor.handleRotationDelta(-0.16), .moveLeft)
    }

    func testIdleRestoresRotationAfterIgnoredMovement() {
        var processor = LegacyCrownInputProcessor(configuration: .watchLegacy)

        XCTAssertEqual(processor.handleRotationDelta(0.16), .moveRight)
        XCTAssertEqual(processor.handleRotationDelta(0.16), .none)

        processor.markIdle()

        XCTAssertEqual(processor.handleRotationDelta(0.16), .moveRight)
    }
}

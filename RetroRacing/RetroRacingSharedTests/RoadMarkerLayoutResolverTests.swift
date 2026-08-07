//
//  RoadMarkerLayoutResolverTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 07/08/2026.
//

import XCTest
@testable import RetroRacingShared

final class RoadMarkerLayoutResolverTests: XCTestCase {
    func testGivenEveryRoadPhaseWhenResolvingThenFourRowsAndOneGapAdvanceInOrder() {
        let layouts = (0..<5).map {
            RoadMarkerLayoutResolver.resolve(
                roadPhase: $0,
                rowCount: 5,
                safetyMarkerRows: []
            )
        }

        XCTAssertEqual(layouts.compactMap(\.emptyDashRow), [4, 0, 1, 2, 3])
        XCTAssertTrue(layouts.allSatisfy { $0.visibleDashRows.count == 4 })
        for layout in layouts {
            guard let emptyDashRow = layout.emptyDashRow else {
                XCTFail("Expected one empty dash row")
                continue
            }
            XCTAssertEqual(
                Set(layout.visibleDashRows + [emptyDashRow]),
                Set(0..<5)
            )
        }
    }

    func testGivenFirstSafetyRowWhenResolvingThenVirtualTopPairIsPreserved() {
        let layout = RoadMarkerLayoutResolver.resolve(
            roadPhase: 2,
            rowCount: 5,
            safetyMarkerRows: [0]
        )

        XCTAssertEqual(layout.finishStripRows, [-1, 0])
        XCTAssertEqual(layout.finishStripCenterRow, -0.5)
        XCTAssertFalse(layout.visibleDashRows.contains(0))
    }

    func testGivenBottomSafetyPairWhenResolvingThenEdgeSentinelIsPreserved() {
        let layout = RoadMarkerLayoutResolver.resolve(
            roadPhase: 2,
            rowCount: 5,
            safetyMarkerRows: [4, 5]
        )

        XCTAssertEqual(layout.finishStripRows, [4, 5])
        XCTAssertEqual(layout.finishStripCenterRow, 4.5)
        XCTAssertFalse(layout.visibleDashRows.contains(4))
    }

    func testGivenSeparatedSafetyRowsWhenResolvingThenRowsAroundStripAreSuppressed() {
        let layout = RoadMarkerLayoutResolver.resolve(
            roadPhase: 1,
            rowCount: 5,
            safetyMarkerRows: [1, 3]
        )

        XCTAssertEqual(layout.finishStripRows, [1, 3])
        XCTAssertEqual(layout.finishStripCenterRow, 2)
        XCTAssertTrue(Set(layout.visibleDashRows).isDisjoint(with: [1, 2, 3]))
    }

    func testGivenInvalidRowCountWhenResolvingThenLayoutIsEmpty() {
        let layout = RoadMarkerLayoutResolver.resolve(
            roadPhase: 0,
            rowCount: 0,
            safetyMarkerRows: [0]
        )

        XCTAssertNil(layout.emptyDashRow)
        XCTAssertTrue(layout.visibleDashRows.isEmpty)
        XCTAssertTrue(layout.finishStripRows.isEmpty)
        XCTAssertNil(layout.finishStripCenterRow)
    }
}

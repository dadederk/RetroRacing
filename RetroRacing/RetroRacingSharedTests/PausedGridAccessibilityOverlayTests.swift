import XCTest
@testable import RetroRacingShared

final class PausedGridAccessibilityOverlayTests: XCTestCase {
    func testGivenGridStateWhenBuildingDescriptorsThenCellsAreRowMajorFromTopLeftToBottomRight() {
        // Given
        var gridState = GridState(numberOfRows: 3, numberOfColumns: 3)
        gridState.grid = [
            [.Empty, .Car, .Empty],
            [.Crash, .Player, .Car],
            [.Empty, .Empty, .Empty]
        ]

        // When
        let descriptors = PausedGridAccessibilityOverlay.descriptors(from: gridState)

        // Then
        XCTAssertEqual(
            descriptors.map { "\($0.row),\($0.column)" },
            [
                "0,0", "0,1", "0,2",
                "1,0", "1,1", "1,2",
                "2,0", "2,1", "2,2"
            ]
        )
    }

    func testGivenMixedCellsWhenBuildingDescriptorsThenLabelsIncludeOccupantAndCoordinates() {
        // Given
        var gridState = GridState(numberOfRows: 2, numberOfColumns: 2)
        gridState.grid = [
            [.Empty, .Car],
            [.Player, .Crash]
        ]

        // When
        let descriptors = PausedGridAccessibilityOverlay.descriptors(from: gridState)

        // Then
        XCTAssertEqual(
            descriptors.map(\.label),
            [
                GameLocalizedStrings.format(
                    "grid_cell_label %@ (%lld, %lld)",
                    GameLocalizedStrings.string("no_car"),
                    Int64(0),
                    Int64(0)
                ),
                GameLocalizedStrings.format(
                    "grid_cell_label %@ (%lld, %lld)",
                    GameLocalizedStrings.string("rival_car"),
                    Int64(0),
                    Int64(1)
                ),
                GameLocalizedStrings.format(
                    "grid_cell_label %@ (%lld, %lld)",
                    GameLocalizedStrings.string("player_car"),
                    Int64(1),
                    Int64(0)
                ),
                GameLocalizedStrings.format(
                    "grid_cell_label %@ (%lld, %lld)",
                    GameLocalizedStrings.string("crash_sprite"),
                    Int64(1),
                    Int64(1)
                )
            ]
        )
    }
}

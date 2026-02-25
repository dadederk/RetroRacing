import SwiftUI

/// Accessibility-only overlay exposing the paused grid in deterministic row-major order.
struct PausedGridAccessibilityOverlay: View {
    struct CellDescriptor: Identifiable, Equatable {
        let row: Int
        let column: Int
        let label: String

        var id: String {
            "\(row)-\(column)"
        }
    }

    let gridState: GridState

    var body: some View {
        let descriptors = Self.descriptors(from: gridState)
        VStack(spacing: 0) {
            ForEach(0..<gridState.numberOfRows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<gridState.numberOfColumns, id: \.self) { column in
                        let index = row * gridState.numberOfColumns + column
                        GridAccessibilityCellView(
                            label: descriptors[index].label
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    static func descriptors(from gridState: GridState) -> [CellDescriptor] {
        var results: [CellDescriptor] = []
        for row in 0..<gridState.numberOfRows {
            for column in 0..<gridState.numberOfColumns {
                let cellState = gridState.grid[row][column]
                let occupant = occupantLabel(for: cellState)
                let label = GameLocalizedStrings.format(
                    "grid_cell_label %@ (%lld, %lld)",
                    occupant,
                    Int64(row),
                    Int64(column)
                )
                results.append(CellDescriptor(row: row, column: column, label: label))
            }
        }
        return results
    }

    private static func occupantLabel(for cellState: GridState.CellState) -> String {
        switch cellState {
        case .Empty:
            return GameLocalizedStrings.string("no_car")
        case .Car:
            return GameLocalizedStrings.string("rival_car")
        case .Player:
            return GameLocalizedStrings.string("player_car")
        case .Crash:
            return GameLocalizedStrings.string("crash_sprite")
        }
    }
}

private struct GridAccessibilityCellView: View {
    let label: String

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityRespondsToUserInteraction(false)
    }
}

//
//  RoadMarkerLayoutResolver.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 07/08/2026.
//

import Foundation

/// Renderer-neutral road-marker positions derived from one engine snapshot.
public struct RoadMarkerLayout: Equatable, Sendable {
    public let emptyDashRow: Int?
    public let visibleDashRows: [Int]
    public let finishStripRows: [Int]
    public let finishStripCenterRow: Double?
}

/// Keeps SpriteKit and RealityKit road movement on the same five-row cadence.
public enum RoadMarkerLayoutResolver {
    public static func resolve(
        roadPhase: Int,
        rowCount: Int,
        safetyMarkerRows: [Int]
    ) -> RoadMarkerLayout {
        guard rowCount > 0 else {
            return RoadMarkerLayout(
                emptyDashRow: nil,
                visibleDashRows: [],
                finishStripRows: [],
                finishStripCenterRow: nil
            )
        }

        let normalizedPhase = positiveModulo(roadPhase, divisor: rowCount)
        let emptyDashRow = positiveModulo(normalizedPhase - 1, divisor: rowCount)
        let finishStripRows = resolvedFinishStripRows(
            safetyMarkerRows,
            rowCount: rowCount
        )
        let finishStripCenterRow = finishStripRows.count == 2
            ? Double(finishStripRows[0] + finishStripRows[1]) / 2
            : nil
        let suppressedRows = suppressedDashRows(
            finishStripRows: finishStripRows,
            finishStripCenterRow: finishStripCenterRow,
            rowCount: rowCount
        )
        let visibleDashRows = (0..<rowCount).filter {
            $0 != emptyDashRow && suppressedRows.contains($0) == false
        }

        return RoadMarkerLayout(
            emptyDashRow: emptyDashRow,
            visibleDashRows: visibleDashRows,
            finishStripRows: finishStripRows,
            finishStripCenterRow: finishStripCenterRow
        )
    }

    private static func resolvedFinishStripRows(
        _ safetyMarkerRows: [Int],
        rowCount: Int
    ) -> [Int] {
        if safetyMarkerRows == [0] {
            return [-1, 0]
        }
        guard safetyMarkerRows.count == 2 else { return [] }
        let extendedRange = -1...rowCount
        let validRows = safetyMarkerRows
            .filter(extendedRange.contains)
            .sorted()
        return validRows.count == 2 ? validRows : []
    }

    private static func suppressedDashRows(
        finishStripRows: [Int],
        finishStripCenterRow: Double?,
        rowCount: Int
    ) -> Set<Int> {
        var rows = Set(finishStripRows.filter { (0..<rowCount).contains($0) })
        guard let finishStripCenterRow else { return rows }
        let nearestVisibleRow = min(
            max(Int(floor(finishStripCenterRow)), 0),
            rowCount - 1
        )
        rows.insert(nearestVisibleRow)
        return rows
    }

    private static func positiveModulo(_ value: Int, divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}

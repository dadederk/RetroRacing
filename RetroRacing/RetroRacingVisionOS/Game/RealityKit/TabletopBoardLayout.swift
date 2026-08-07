//
//  TabletopBoardLayout.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import Foundation

struct TabletopModelPlacement: Equatable, Sendable {
    let scale: Float
    let modelOffset: SIMD3<Float>
}

enum TabletopVolumeLayout {
    nonisolated static func boardRootPosition(
        volumeMinimum: SIMD3<Float>,
        volumeMaximum: SIMD3<Float>
    ) -> SIMD3<Float> {
        SIMD3(
            (volumeMinimum.x + volumeMaximum.x) / 2,
            volumeMinimum.y,
            (volumeMinimum.z + volumeMaximum.z) / 2
        )
    }
}

/// The single source of truth for every board dimension and grid transform.
struct TabletopBoardLayout: Equatable, Sendable {
    nonisolated static let standard = TabletopBoardLayout()

    let boardWidth: Float = 0.55
    let boardDepth: Float = 0.75
    let roadWidth: Float = 0.45
    let roadDepth: Float = 0.70
    let laneWidth: Float = 0.15
    let rowDepth: Float = 0.14
    let boardHeight: Float = 0.022
    let rowCount = 5
    let laneCount = 3
    let roadHeight: Float = 0.012
    let vergeHeight: Float = 0.007

    var sideVergeWidth: Float { (boardWidth - roadWidth) / 2 }
    var endVergeDepth: Float { (boardDepth - roadDepth) / 2 }
    var boardCenterY: Float { boardHeight / 2 }
    var roadCenterY: Float { boardHeight + roadHeight / 2 }
    var roadTopY: Float { boardHeight + roadHeight }
    var vergeCenterY: Float { boardHeight + vergeHeight / 2 }
    var roadOverlayY: Float { roadTopY + 0.0008 }
    var finishMarkerY: Float { roadTopY + 0.0012 }
    var roadDashDepth: Float { rowDepth * 0.64 }
    var finishMarkerDepth: Float { rowDepth * 0.42 }
    var carMaximumWidth: Float { laneWidth * 0.70 }
    var carMaximumDepth: Float { rowDepth * 0.80 }
    var laneTargetSize: SIMD3<Float> { SIMD3(laneWidth, 0.05, roadDepth) }

    var roadBoundaryPositions: [Float] {
        (0...laneCount).map { -roadWidth / 2 + Float($0) * laneWidth }
    }

    func laneCenterX(_ column: Int) -> Float {
        centeredCoordinate(index: column, count: laneCount, spacing: laneWidth)
    }

    func rowCenterZ(_ row: Int) -> Float {
        centeredCoordinate(index: row, count: rowCount, spacing: rowDepth)
    }

    func cellCenter(row: Int, column: Int, y: Float = 0) -> SIMD3<Float> {
        SIMD3(laneCenterX(column), y, rowCenterZ(row))
    }

    func laneTargetCenter(_ lane: Int) -> SIMD3<Float> {
        SIMD3(laneCenterX(lane), roadOverlayY, 0)
    }

    func finishMarkerCenter(logicalRow: Double) -> SIMD3<Float> {
        let centeredRow = Float(logicalRow) - Float(rowCount - 1) / 2
        return SIMD3(0, finishMarkerY, centeredRow * rowDepth)
    }

    func modelPlacement(
        boundsMinimum: SIMD3<Float>,
        boundsMaximum: SIMD3<Float>
    ) -> TabletopModelPlacement? {
        let extents = boundsMaximum - boundsMinimum
        guard allFinite(boundsMinimum),
              allFinite(boundsMaximum),
              extents.x > 0,
              extents.y > 0,
              extents.z > 0 else {
            return nil
        }

        let scale = min(carMaximumWidth / extents.x, carMaximumDepth / extents.z)
        guard scale.isFinite, scale > 0 else { return nil }
        let boundsCenter = (boundsMinimum + boundsMaximum) / 2
        return TabletopModelPlacement(
            scale: scale,
            modelOffset: SIMD3(
                -boundsCenter.x * scale,
                -boundsMinimum.y * scale,
                -boundsCenter.z * scale
            )
        )
    }

    func carPosition(row: Int, column: Int) -> SIMD3<Float> {
        cellCenter(row: row, column: column, y: roadTopY)
    }

    private func centeredCoordinate(index: Int, count: Int, spacing: Float) -> Float {
        (Float(index) - Float(count - 1) / 2) * spacing
    }

    private func allFinite(_ value: SIMD3<Float>) -> Bool {
        value.x.isFinite && value.y.isFinite && value.z.isFinite
    }
}

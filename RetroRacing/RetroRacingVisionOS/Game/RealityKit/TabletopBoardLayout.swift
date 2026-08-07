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

/// The single source of truth for every tabletop dimension and grid transform.
struct TabletopBoardLayout: Equatable, Sendable {
    nonisolated static let standard = TabletopBoardLayout()

    let boardSide: Float = 0.90
    let volumeSize = SIMD3<Float>(1.04, 0.65, 1.04)
    let boardHeight: Float = 0.035
    let cellSide: Float = 0.17
    let rowCount = 5
    let laneCount = 3
    let roadHeight: Float = 0.018
    let vergeHeight: Float = 0.008
    let boardVerticalOffset: Float = -0.12

    var roadWidth: Float { Float(laneCount) * cellSide }
    var roadDepth: Float { Float(rowCount) * cellSide }
    var sideVergeWidth: Float { (boardSide - roadWidth) / 2 }
    var endVergeDepth: Float { (boardSide - roadDepth) / 2 }
    var boardCenterY: Float { -boardHeight / 2 }
    var roadCenterY: Float { roadHeight / 2 }
    var roadTopY: Float { roadHeight }
    var vergeCenterY: Float { vergeHeight / 2 }
    var roadOverlayY: Float { roadTopY + 0.0008 }
    var safetyMarkerY: Float { roadTopY + 0.0012 }
    var carMaximumWidth: Float { cellSide * 0.58 }
    var carMaximumDepth: Float { cellSide * 0.64 }
    var laneTargetSize: SIMD3<Float> { SIMD3(cellSide, 0.045, roadDepth) }

    var laneDividerPositions: [Float] {
        (1..<laneCount).map { -roadWidth / 2 + Float($0) * cellSide }
    }

    func laneCenterX(_ column: Int) -> Float {
        centeredCoordinate(index: column, count: laneCount)
    }

    func rowCenterZ(_ row: Int) -> Float {
        centeredCoordinate(index: row, count: rowCount)
    }

    func cellCenter(row: Int, column: Int, y: Float = 0) -> SIMD3<Float> {
        SIMD3(laneCenterX(column), y, rowCenterZ(row))
    }

    func laneTargetCenter(_ lane: Int) -> SIMD3<Float> {
        SIMD3(laneCenterX(lane), roadOverlayY, 0)
    }

    func safetyMarkerCenter(row: Int) -> SIMD3<Float> {
        SIMD3(0, safetyMarkerY, rowCenterZ(row))
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

    private func centeredCoordinate(index: Int, count: Int) -> Float {
        (Float(index) - Float(count - 1) / 2) * cellSide
    }

    private func allFinite(_ value: SIMD3<Float>) -> Bool {
        value.x.isFinite && value.y.isFinite && value.z.isFinite
    }
}

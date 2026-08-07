//
//  TabletopSceneTests.swift
//  RetroRacingVisionOSTests
//
//  Created by Dani Devesa on 07/08/2026.
//

import RealityKit
import SwiftUI
import XCTest
@testable import RetroRacingShared
@testable import RetroRacingVisionOS

@MainActor
final class TabletopSceneTests: XCTestCase {
    func testStandardLayoutFormsCompactRectangleWithExactRoadAndCenteredGrid() {
        let layout = TabletopBoardLayout.standard

        XCTAssertEqual(layout.boardWidth, 0.55, accuracy: 0.0001)
        XCTAssertEqual(layout.boardDepth, 0.75, accuracy: 0.0001)
        XCTAssertEqual(layout.roadWidth, 0.45, accuracy: 0.0001)
        XCTAssertEqual(layout.roadDepth, 0.70, accuracy: 0.0001)
        XCTAssertEqual(layout.sideVergeWidth, 0.05, accuracy: 0.0001)
        XCTAssertEqual(layout.endVergeDepth, 0.025, accuracy: 0.0001)
        assertEqual(layout.laneDividerPositions, [-0.075, 0.075])
        assertEqual((0..<layout.laneCount).map(layout.laneCenterX), [-0.15, 0, 0.15])
        assertEqual(
            (0..<layout.rowCount).map(layout.rowCenterZ),
            [-0.28, -0.14, 0, 0.14, 0.28]
        )
        XCTAssertEqual(layout.carMaximumWidth, layout.laneWidth * 0.70, accuracy: 0.0001)
        XCTAssertEqual(layout.carMaximumDepth, layout.rowDepth * 0.80, accuracy: 0.0001)
        XCTAssertEqual(layout.minimumSurfaceBounds, SIMD2<Float>(0.55, 0.75))
    }

    func testModelBoundsPlacementFitsAndCentersVisibleGeometryInCell() throws {
        let layout = TabletopBoardLayout.standard
        let minimum = SIMD3<Float>(1, -0.2, 2)
        let maximum = SIMD3<Float>(3, 1.8, 6)
        let placement = try XCTUnwrap(layout.modelPlacement(
            boundsMinimum: minimum,
            boundsMaximum: maximum
        ))
        let position = layout.carPosition(row: 2, column: 0)
        let visibleCenter = position
            + placement.modelOffset
            + ((minimum + maximum) / 2) * placement.scale

        XCTAssertLessThanOrEqual((maximum.x - minimum.x) * placement.scale, layout.carMaximumWidth)
        XCTAssertEqual((maximum.z - minimum.z) * placement.scale, layout.carMaximumDepth, accuracy: 0.0001)
        XCTAssertEqual(visibleCenter.x, layout.laneCenterX(0), accuracy: 0.0001)
        XCTAssertEqual(visibleCenter.z, layout.rowCenterZ(2), accuracy: 0.0001)
        XCTAssertEqual(
            position.y + placement.modelOffset.y + minimum.y * placement.scale,
            layout.roadTopY,
            accuracy: 0.0001
        )
    }

    func testLaneTargetsCoverEachFullRoadLaneWithFlushVisualPlanes() {
        let layout = TabletopBoardLayout.standard
        let board = TabletopSceneEntityFactory.makeBoard(
            layout: layout,
            visualStyle: .standard
        )

        XCTAssertEqual(layout.laneTargetSize.x, layout.laneWidth, accuracy: 0.0001)
        XCTAssertEqual(layout.laneTargetSize.z, layout.roadDepth, accuracy: 0.0001)
        for (lane, target) in board.laneTargets.enumerated() {
            let center = layout.laneTargetCenter(lane)
            let bounds = target.visualBounds(relativeTo: target)
            XCTAssertGreaterThanOrEqual(
                center.x - layout.laneTargetSize.x / 2,
                -layout.roadWidth / 2 - 0.0001
            )
            XCTAssertLessThanOrEqual(
                center.x + layout.laneTargetSize.x / 2,
                layout.roadWidth / 2 + 0.0001
            )
            XCTAssertEqual(target.position.y, layout.roadOverlayY, accuracy: 0.0001)
            XCTAssertEqual(bounds.extents.x, layout.laneWidth, accuracy: 0.0001)
            XCTAssertEqual(bounds.extents.y, 0, accuracy: 0.0001)
            XCTAssertEqual(bounds.extents.z, layout.roadDepth, accuracy: 0.0001)
            XCTAssertNotNil(target.components[CollisionComponent.self])
        }
    }

    func testLaneDividersAreFlushPlanesOverRoad() throws {
        let layout = TabletopBoardLayout.standard
        let board = TabletopSceneEntityFactory.makeBoard(
            layout: layout,
            visualStyle: .standard
        )
        let divider = try XCTUnwrap(
            board.root.findEntity(named: "tabletop-lane-divider")
        )
        let bounds = divider.visualBounds(relativeTo: divider)

        XCTAssertEqual(divider.position.y, layout.roadOverlayY, accuracy: 0.0001)
        XCTAssertEqual(bounds.extents.y, 0, accuracy: 0.0001)
        XCTAssertEqual(bounds.extents.z, layout.roadDepth, accuracy: 0.0001)
    }

    func testPackagedModelsRemainCenteredOverTheirExactGridCells() async throws {
        let snapshot = makeSnapshot(denseTraffic: true)
        let repository = TabletopModelRepository(
            playerResourceName: "player-car-64bit",
            rivalResourceName: "rival-car-64bit",
            bundle: .main
        )
        let scene = try await TabletopSceneFactory(modelRepository: repository)
            .makeScene(snapshot: snapshot)

        assertVisibleBounds(
            of: scene.player,
            equalCell: scene.layout.carPosition(row: 4, column: 1),
            layout: scene.layout,
            relativeTo: scene.root
        )
        for (index, rival) in scene.rivals.enumerated() where rival.isEnabled {
            assertVisibleBounds(
                of: rival,
                equalCell: scene.layout.carPosition(
                    row: index / scene.layout.laneCount,
                    column: index % scene.layout.laneCount
                ),
                layout: scene.layout,
                relativeTo: scene.root
            )
        }
    }

    func testSceneUpdatesReusePoolsAndMapDenseTrafficToSeparateCells() throws {
        let scene = try makeScene(snapshot: makeSnapshot())
        let rivalIdentities = scene.rivals.map(ObjectIdentifier.init)
        let laneTargetIdentities = scene.laneTargets.map(ObjectIdentifier.init)
        let impactIdentity = ObjectIdentifier(scene.impactBurst)
        let denseSnapshot = makeSnapshot(denseTraffic: true, safetyMarkerRows: [1, 3])

        scene.update(snapshot: denseSnapshot)

        XCTAssertEqual(scene.rivals.map(ObjectIdentifier.init), rivalIdentities)
        XCTAssertEqual(scene.laneTargets.map(ObjectIdentifier.init), laneTargetIdentities)
        XCTAssertEqual(ObjectIdentifier(scene.impactBurst), impactIdentity)
        XCTAssertEqual(scene.rivals.filter(\.isEnabled).count, 14)
        XCTAssertEqual(
            scene.rivals[1].position.x - scene.rivals[0].position.x,
            scene.layout.laneWidth,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            Set(scene.rivals.filter(\.isEnabled).map(\.position.x)),
            Set((0..<scene.layout.laneCount).map(scene.layout.laneCenterX))
        )
        XCTAssertEqual(scene.rivals[0].scale, SIMD3<Float>(repeating: 1))
    }

    func testSafetyMarkersReuseEntitiesAndFollowSnapshotRows() throws {
        let scene = try makeScene(snapshot: makeSnapshot(safetyMarkerRows: [0, 2]))
        let identities = scene.safetyMarkers.map(ObjectIdentifier.init)

        scene.update(snapshot: makeSnapshot(safetyMarkerRows: [4]))

        XCTAssertEqual(scene.safetyMarkers.map(ObjectIdentifier.init), identities)
        XCTAssertTrue(scene.safetyMarkers[0].isEnabled)
        XCTAssertEqual(
            scene.safetyMarkers[0].position,
            scene.layout.safetyMarkerCenter(row: 4)
        )
        XCTAssertEqual(
            scene.safetyMarkers[0].visualBounds(relativeTo: scene.safetyMarkers[0]).extents.y,
            0,
            accuracy: 0.0001
        )
        XCTAssertFalse(scene.safetyMarkers[1].isEnabled)
    }

    func testCollisionEffectHidesNormalCarsAndPulsesBothCollisionClones() throws {
        let scene = try makeScene(snapshot: makeSnapshot())

        scene.update(snapshot: makeSnapshot(phase: .collision))
        XCTAssertFalse(scene.player.isEnabled)
        XCTAssertTrue(scene.collisionPose.isEnabled)
        XCTAssertTrue(scene.collisionPlayer.isEnabled)
        XCTAssertTrue(scene.collisionRival.isEnabled)
        XCTAssertTrue(scene.isImpactPulsing)

        scene.update(snapshot: makeSnapshot(phase: .gameOver, lives: 0))
        XCTAssertFalse(scene.player.isEnabled)
        XCTAssertTrue(scene.collisionPose.isEnabled)
        XCTAssertFalse(scene.isImpactPulsing)

        scene.update(snapshot: makeSnapshot())
        XCTAssertTrue(scene.player.isEnabled)
        XCTAssertFalse(scene.collisionPose.isEnabled)
        XCTAssertFalse(scene.isImpactPulsing)
    }

    func testReduceMotionKeepsCollisionPoseSteadyWithDistinctGeometry() throws {
        let style = TabletopSceneVisualStyle(
            increasedContrast: true,
            differentiateWithoutColor: true,
            reduceMotion: true
        )
        let scene = try makeScene(snapshot: makeSnapshot(), visualStyle: style)

        scene.update(snapshot: makeSnapshot(phase: .collision))

        XCTAssertFalse(scene.player.isEnabled)
        XCTAssertTrue(scene.collisionPose.isEnabled)
        XCTAssertFalse(scene.isImpactPulsing)
        XCTAssertGreaterThan(scene.impactBurst.children.count, 1)
        XCTAssertEqual(scene.visualStyle, style)
    }

    func testBoardUndersideSitsOnSurfaceAndProvidesNeutralKeyLight() throws {
        let scene = try makeScene(snapshot: makeSnapshot())
        let base = try XCTUnwrap(scene.root.findEntity(named: "tabletop-base"))
        let keyLight = try XCTUnwrap(scene.root.findEntity(named: "tabletop-key-light"))
        let baseBounds = base.visualBounds(relativeTo: scene.root)

        XCTAssertEqual(scene.root.position.y, 0, accuracy: 0.0001)
        XCTAssertEqual(baseBounds.min.y, 0, accuracy: 0.0001)
        XCTAssertNotNil(keyLight.components[DirectionalLightComponent.self])
        XCTAssertNil(keyLight.components[DynamicLightShadowComponent.self])
    }

    func testHUDAttachmentReadinessIsExplicit() throws {
        let scene = try makeScene(snapshot: makeSnapshot())
        XCTAssertFalse(scene.isHUDReady)

        scene.installHUD(Text("HUD"))

        XCTAssertTrue(scene.isHUDReady)
        XCTAssertNotNil(scene.hudAttachment?.components[ViewAttachmentComponent.self])
        XCTAssertEqual(scene.hudAttachment?.position, scene.layout.hudPosition)
    }

    func testInvalidBoundsThrowTypedFailureInsteadOfScaleOneFallback() {
        let empty = Entity()

        XCTAssertThrowsError(
            try TabletopScene(
                canonicalPlayerCar: empty,
                canonicalRivalCar: empty,
                snapshot: makeSnapshot()
            )
        ) { error in
            XCTAssertEqual(error as? TabletopSceneError, .invalidModelBounds(.player))
        }
    }

    func testLaneTargetsDisableUntilSpatialConfirmationAllowsInput() throws {
        let scene = try makeScene(snapshot: makeSnapshot())

        scene.update(snapshot: makeSnapshot(), inputEnabled: false)
        XCTAssertTrue(scene.laneTargets.allSatisfy { $0.isEnabled == false })

        scene.update(snapshot: makeSnapshot(), inputEnabled: true)
        XCTAssertTrue(scene.laneTargets.allSatisfy(\.isEnabled))
    }

    func testLaneTargetsReceiveNativeGestureComponents() throws {
        let scene = try makeScene(snapshot: makeSnapshot())
        TabletopLaneGestureInstaller.install(in: scene) { _ in }

        XCTAssertTrue(
            scene.laneTargets.allSatisfy {
                $0.components[GestureComponent.self] != nil
            }
        )
    }

    private func makeScene(
        snapshot: GameSnapshot,
        visualStyle: TabletopSceneVisualStyle = .standard
    ) throws -> TabletopScene {
        let car = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.12, 0.07, 0.20)),
            materials: [SimpleMaterial(color: .red, isMetallic: false)]
        )
        return try TabletopScene(
            canonicalPlayerCar: car,
            canonicalRivalCar: car,
            snapshot: snapshot,
            visualStyle: visualStyle
        )
    }

    private func makeSnapshot(
        phase: GamePhase = .running,
        denseTraffic: Bool = false,
        safetyMarkerRows: [Int] = [],
        lives: Int = 3
    ) -> GameSnapshot {
        var grid = Array(
            repeating: Array(
                repeating: denseTraffic ? GameGridOccupant.rival : .empty,
                count: 3
            ),
            count: 5
        )
        grid[4][1] = phase == .collision || phase == .gameOver ? .crash : .player
        return GameSnapshot(
            phase: phase,
            grid: grid,
            playerColumn: 1,
            score: 24,
            lives: lives,
            level: 2,
            roadPhase: 2,
            safetyMarkerRows: safetyMarkerRows,
            difficulty: .rapid,
            activePauseReasons: phase == .paused ? [.user] : []
        )
    }

    private func assertEqual(
        _ actual: [Float],
        _ expected: [Float],
        accuracy: Float = 0.0001,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual.count, expected.count, file: file, line: line)
        for (actualValue, expectedValue) in zip(actual, expected) {
            XCTAssertEqual(
                actualValue,
                expectedValue,
                accuracy: accuracy,
                file: file,
                line: line
            )
        }
    }

    private func assertVisibleBounds(
        of entity: Entity,
        equalCell cell: SIMD3<Float>,
        layout: TabletopBoardLayout,
        relativeTo root: Entity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let bounds = entity.visualBounds(relativeTo: root)
        let center = (bounds.min + bounds.max) / 2
        XCTAssertEqual(center.x, cell.x, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(center.z, cell.z, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(bounds.min.y, layout.roadTopY, accuracy: 0.0001, file: file, line: line)
        XCTAssertLessThanOrEqual(
            bounds.extents.x,
            layout.carMaximumWidth + 0.0001,
            file: file,
            line: line
        )
        XCTAssertLessThanOrEqual(
            bounds.extents.z,
            layout.carMaximumDepth + 0.0001,
            file: file,
            line: line
        )
    }
}

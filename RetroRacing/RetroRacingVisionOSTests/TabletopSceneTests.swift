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
        assertEqual(layout.roadBoundaryPositions, [-0.225, -0.075, 0.075, 0.225])
        assertEqual((0..<layout.laneCount).map(layout.laneCenterX), [-0.15, 0, 0.15])
        assertEqual(
            (0..<layout.rowCount).map(layout.rowCenterZ),
            [-0.28, -0.14, 0, 0.14, 0.28]
        )
        XCTAssertEqual(layout.carMaximumWidth, layout.laneWidth * 0.70, accuracy: 0.0001)
        XCTAssertEqual(layout.carMaximumDepth, layout.rowDepth * 0.80, accuracy: 0.0001)
        XCTAssertEqual(layout.roadDashDepth, layout.rowDepth * 0.64, accuracy: 0.0001)
        XCTAssertEqual(layout.finishMarkerDepth, layout.rowDepth * 0.42, accuracy: 0.0001)
    }

    func testVolumeLayoutCentersBoardAgainstBottomSnappingBoundary() {
        let position = TabletopVolumeLayout.boardRootPosition(
            volumeMinimum: SIMD3(-0.30, -0.15, -0.40),
            volumeMaximum: SIMD3(0.30, 0.15, 0.40)
        )

        XCTAssertEqual(position, SIMD3(0, -0.15, 0))
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

    func testLaneTargetsCoverEachFullRoadLaneWithFlushVisualPlanes() throws {
        let layout = TabletopBoardLayout.standard
        let board = try TabletopSceneEntityFactory.makeBoard(
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
            XCTAssertNil(target.components[HoverEffectComponent.self])
        }
    }

    func testRoadMarkersUseTwentyPooledDashPlanesAcrossInnerAndOuterBoundaries() throws {
        let layout = TabletopBoardLayout.standard
        let board = try TabletopSceneEntityFactory.makeBoard(
            layout: layout,
            visualStyle: .standard
        )

        XCTAssertEqual(board.roadDashes.count, 20)
        XCTAssertEqual(Set(board.roadDashes.map(\.row)), Set(0..<layout.rowCount))
        XCTAssertEqual(Set(board.roadDashes.map(\.boundary)), Set(0...layout.laneCount))
        for dash in board.roadDashes {
            let bounds = dash.entity.visualBounds(relativeTo: dash.entity)
            XCTAssertEqual(
                dash.entity.position.x,
                layout.roadBoundaryPositions[dash.boundary],
                accuracy: 0.0001
            )
            XCTAssertEqual(dash.entity.position.z, layout.rowCenterZ(dash.row), accuracy: 0.0001)
            XCTAssertEqual(dash.entity.position.y, layout.roadOverlayY, accuracy: 0.0001)
            XCTAssertEqual(bounds.extents.y, 0, accuracy: 0.0001)
            XCTAssertEqual(bounds.extents.z, layout.roadDashDepth, accuracy: 0.0001)
        }
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
        let roadDashIdentities = scene.roadDashes.map { ObjectIdentifier($0.entity) }
        let finishMarkerIdentity = ObjectIdentifier(scene.finishMarker)
        let impactIdentity = ObjectIdentifier(scene.impactBurst)
        let denseSnapshot = makeSnapshot(denseTraffic: true, safetyMarkerRows: [1, 3])

        scene.update(snapshot: denseSnapshot)

        XCTAssertEqual(scene.rivals.map(ObjectIdentifier.init), rivalIdentities)
        XCTAssertEqual(scene.laneTargets.map(ObjectIdentifier.init), laneTargetIdentities)
        XCTAssertEqual(scene.roadDashes.map { ObjectIdentifier($0.entity) }, roadDashIdentities)
        XCTAssertEqual(ObjectIdentifier(scene.finishMarker), finishMarkerIdentity)
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

    func testRoadPhaseAdvancesDashGapWithoutAllocatingEntities() throws {
        let scene = try makeScene(snapshot: makeSnapshot(roadPhase: 1))
        let identities = scene.roadDashes.map { ObjectIdentifier($0.entity) }
        XCTAssertEqual(enabledDashRows(in: scene), Set([1, 2, 3, 4]))

        scene.update(snapshot: makeSnapshot(roadPhase: 2))

        XCTAssertEqual(scene.roadDashes.map { ObjectIdentifier($0.entity) }, identities)
        XCTAssertEqual(enabledDashRows(in: scene), Set([0, 2, 3, 4]))
    }

    func testLaneMovementDoesNotChangeRoadMarkerPhaseOrAllocateEntities() throws {
        let scene = try makeScene(snapshot: makeSnapshot(roadPhase: 3))
        let identities = scene.roadDashes.map { ObjectIdentifier($0.entity) }
        let enabledRows = enabledDashRows(in: scene)

        scene.update(snapshot: makeSnapshot(roadPhase: 3, playerColumn: 0))

        XCTAssertEqual(scene.roadDashes.map { ObjectIdentifier($0.entity) }, identities)
        XCTAssertEqual(enabledDashRows(in: scene), enabledRows)
    }

    func testFinishStripUsesSharedVirtualRowPlacementAndSuppressesDashes() throws {
        let scene = try makeScene(
            snapshot: makeSnapshot(roadPhase: 2, safetyMarkerRows: [0])
        )
        let finishIdentity = ObjectIdentifier(scene.finishMarker)

        XCTAssertTrue(scene.finishMarker.isEnabled)
        XCTAssertEqual(
            scene.finishMarker.position,
            scene.layout.finishMarkerCenter(logicalRow: -0.5)
        )
        XCTAssertEqual(enabledDashRows(in: scene), Set([2, 3, 4]))

        scene.update(snapshot: makeSnapshot(roadPhase: 2, safetyMarkerRows: [4, 5]))

        XCTAssertEqual(ObjectIdentifier(scene.finishMarker), finishIdentity)
        XCTAssertEqual(
            scene.finishMarker.position,
            scene.layout.finishMarkerCenter(logicalRow: 4.5)
        )
        XCTAssertEqual(enabledDashRows(in: scene), Set([0, 2, 3]))
    }

    func testFinishStripUsesMaskTextureAndFullRoadWidth() throws {
        let scene = try makeScene(snapshot: makeSnapshot(safetyMarkerRows: [2, 3]))
        let model = try XCTUnwrap(scene.finishMarker.components[ModelComponent.self])
        let material = try XCTUnwrap(model.materials.first as? UnlitMaterial)
        let bounds = scene.finishMarker.visualBounds(relativeTo: scene.finishMarker)

        XCTAssertNotNil(material.color.texture)
        XCTAssertEqual(bounds.extents.x, scene.layout.roadWidth, accuracy: 0.0001)
        XCTAssertEqual(bounds.extents.z, scene.layout.finishMarkerDepth, accuracy: 0.0001)
        XCTAssertEqual(scene.finishMarker.position.y, scene.layout.finishMarkerY, accuracy: 0.0001)
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

    func testSceneContainsNoEmbeddedSwiftUIHUDAttachment() throws {
        let scene = try makeScene(snapshot: makeSnapshot())

        XCTAssertNil(scene.root.findEntity(named: "tabletop-hud-attachment"))
    }

    func testIncreaseContrastUsesThemeVariantsAndEmphasizesRoadBoundaries() throws {
        let standard = try TabletopSceneEntityFactory.makeBoard(
            layout: .standard,
            visualStyle: .standard
        )
        let increasedContrast = try TabletopSceneEntityFactory.makeBoard(
            layout: .standard,
            visualStyle: TabletopSceneVisualStyle(
                increasedContrast: true,
                differentiateWithoutColor: false,
                reduceMotion: false
            )
        )
        let standardDash = try unlitMaterial(of: standard.roadDashes[0].entity)
        let contrastDash = try unlitMaterial(of: increasedContrast.roadDashes[0].entity)
        let standardFinish = try unlitMaterial(of: standard.finishMarker)
        let contrastFinish = try unlitMaterial(of: increasedContrast.finishMarker)

        let standardDashBounds = standard.roadDashes[0].entity.visualBounds(
            relativeTo: standard.roadDashes[0].entity
        )
        let contrastDashBounds = increasedContrast.roadDashes[0].entity.visualBounds(
            relativeTo: increasedContrast.roadDashes[0].entity
        )

        XCTAssertTrue(standardDash.color.tint.isEqual(contrastDash.color.tint))
        XCTAssertGreaterThan(contrastDashBounds.extents.x, standardDashBounds.extents.x)
        XCTAssertFalse(standardFinish.color.tint.isEqual(contrastFinish.color.tint))
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

    func testLaneTargetsDisableUntilSpatialReadyStateAllowsInput() throws {
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
        roadPhase: Int = 2,
        playerColumn: Int = 1,
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
        grid[4][playerColumn] = phase == .collision || phase == .gameOver ? .crash : .player
        return GameSnapshot(
            phase: phase,
            grid: grid,
            playerColumn: playerColumn,
            score: 24,
            lives: lives,
            level: 2,
            roadPhase: roadPhase,
            safetyMarkerRows: safetyMarkerRows,
            difficulty: .rapid,
            activePauseReasons: phase == .paused ? [.user] : []
        )
    }

    private func enabledDashRows(in scene: TabletopScene) -> Set<Int> {
        Set(scene.roadDashes.filter { $0.entity.isEnabled }.map(\.row))
    }

    private func unlitMaterial(of entity: ModelEntity) throws -> UnlitMaterial {
        let model = try XCTUnwrap(entity.components[ModelComponent.self])
        return try XCTUnwrap(model.materials.first as? UnlitMaterial)
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

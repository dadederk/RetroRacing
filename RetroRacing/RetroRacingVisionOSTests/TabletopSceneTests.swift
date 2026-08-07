//
//  TabletopSceneTests.swift
//  RetroRacingVisionOSTests
//
//  Created by Dani Devesa on 07/08/2026.
//

import RealityKit
import XCTest
@testable import RetroRacingShared
@testable import RetroRacingVisionOS

@MainActor
final class TabletopSceneTests: XCTestCase {
    func testStandardLayoutFormsSquareBoardWithSymmetricVergesAndCenteredGrid() {
        let layout = TabletopBoardLayout.standard

        XCTAssertEqual(layout.boardSide, 0.90, accuracy: 0.0001)
        XCTAssertEqual(layout.volumeSize, SIMD3<Float>(1.04, 0.65, 1.04))
        XCTAssertEqual(layout.roadWidth, 0.51, accuracy: 0.0001)
        XCTAssertEqual(layout.roadDepth, 0.85, accuracy: 0.0001)
        XCTAssertEqual(layout.sideVergeWidth, 0.195, accuracy: 0.0001)
        XCTAssertEqual(layout.endVergeDepth, 0.025, accuracy: 0.0001)
        assertEqual(layout.laneDividerPositions, [-0.085, 0.085])
        assertEqual((0..<layout.laneCount).map(layout.laneCenterX), [-0.17, 0, 0.17])
        assertEqual(
            (0..<layout.rowCount).map(layout.rowCenterZ),
            [-0.34, -0.17, 0, 0.17, 0.34]
        )
        XCTAssertEqual(layout.carMaximumWidth, layout.cellSide * 0.58, accuracy: 0.0001)
        XCTAssertEqual(layout.carMaximumDepth, layout.cellSide * 0.64, accuracy: 0.0001)
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

        XCTAssertEqual(layout.laneTargetSize.x, layout.cellSide, accuracy: 0.0001)
        XCTAssertEqual(layout.laneTargetSize.z, layout.roadDepth, accuracy: 0.0001)
        for (lane, target) in board.laneTargets.enumerated() {
            let center = layout.laneTargetCenter(lane)
            let bounds = target.visualBounds(relativeTo: target)
            XCTAssertGreaterThanOrEqual(center.x - layout.laneTargetSize.x / 2, -layout.roadWidth / 2)
            XCTAssertLessThanOrEqual(center.x + layout.laneTargetSize.x / 2, layout.roadWidth / 2)
            XCTAssertEqual(target.position.y, layout.roadOverlayY, accuracy: 0.0001)
            XCTAssertEqual(bounds.extents.x, layout.cellSide, accuracy: 0.0001)
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

    func testSceneUpdatesReusePoolsAndMapDenseTrafficToSeparateCells() {
        let scene = makeScene(snapshot: makeSnapshot())
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
            scene.layout.cellSide,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            Set(scene.rivals.filter(\.isEnabled).map(\.position.x)),
            Set((0..<scene.layout.laneCount).map(scene.layout.laneCenterX))
        )
        XCTAssertEqual(scene.rivals[0].scale, SIMD3<Float>(repeating: 1))
    }

    func testSafetyMarkersReuseEntitiesAndFollowSnapshotRows() {
        let scene = makeScene(snapshot: makeSnapshot(safetyMarkerRows: [0, 2]))
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

    func testCollisionEffectHidesPlayerPulsesThenClearsAfterRecovery() {
        let scene = makeScene(snapshot: makeSnapshot())

        scene.update(snapshot: makeSnapshot(phase: .collision))
        XCTAssertFalse(scene.player.isEnabled)
        XCTAssertTrue(scene.impactBurst.isEnabled)
        XCTAssertTrue(scene.isImpactPulsing)

        scene.update(snapshot: makeSnapshot(phase: .gameOver, lives: 0))
        XCTAssertFalse(scene.player.isEnabled)
        XCTAssertTrue(scene.impactBurst.isEnabled)
        XCTAssertFalse(scene.isImpactPulsing)

        scene.update(snapshot: makeSnapshot())
        XCTAssertTrue(scene.player.isEnabled)
        XCTAssertFalse(scene.impactBurst.isEnabled)
        XCTAssertFalse(scene.isImpactPulsing)
    }

    func testReduceMotionKeepsCollisionBurstSteadyWithDistinctGeometry() {
        let style = TabletopSceneVisualStyle(
            increasedContrast: true,
            differentiateWithoutColor: true,
            reduceMotion: true
        )
        let scene = makeScene(snapshot: makeSnapshot(), visualStyle: style)

        scene.update(snapshot: makeSnapshot(phase: .collision))

        XCTAssertFalse(scene.player.isEnabled)
        XCTAssertTrue(scene.impactBurst.isEnabled)
        XCTAssertFalse(scene.isImpactPulsing)
        XCTAssertGreaterThan(scene.impactBurst.children.count, 1)
        XCTAssertEqual(scene.visualStyle, style)
    }

    private func makeScene(
        snapshot: GameSnapshot,
        visualStyle: TabletopSceneVisualStyle = .standard
    ) -> TabletopScene {
        let car = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.12, 0.07, 0.20)),
            materials: [SimpleMaterial(color: .red, isMetallic: false)]
        )
        return TabletopScene(
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

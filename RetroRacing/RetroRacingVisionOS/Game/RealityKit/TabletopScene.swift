//
//  TabletopScene.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation
import RealityKit
import RetroRacingShared

struct TabletopSceneVisualStyle: Equatable, Sendable {
    let increasedContrast: Bool
    let differentiateWithoutColor: Bool
    let reduceMotion: Bool

    nonisolated static let standard = TabletopSceneVisualStyle(
        increasedContrast: false,
        differentiateWithoutColor: false,
        reduceMotion: false
    )
}

enum TabletopCarRole: String, Equatable, Sendable {
    case player
    case rival
}

enum TabletopSceneError: Error, Equatable {
    case invalidModelBounds(TabletopCarRole)
    case invalidNormalizedModel(TabletopCarRole)
    case modelOutsideRoad(TabletopCarRole)
    case finishMarkerTextureUnavailable
}

/// Owns the fixed RealityKit entity pool and all snapshot-derived transforms.
@MainActor
final class TabletopScene {
    static let rootName = "tabletop-race-root"
    static let playerName = "tabletop-player"
    static let rivalCount = 15
    static let animationDuration: TimeInterval = 0.11

    let root = Entity()
    let player: Entity
    let rivals: [Entity]
    let collisionPlayer: Entity
    let collisionRival: Entity
    let laneTargets: [ModelEntity]
    let roadDashes: [TabletopRoadDash]
    let finishMarker: ModelEntity
    let layout: TabletopBoardLayout
    let visualStyle: TabletopSceneVisualStyle
    let impactBurst: Entity
    let collisionPose: Entity
    var isImpactPulsing: Bool { collisionEffect.isPulsing }

    private let collisionEffect: TabletopCollisionEffect
    private var accessibilityPlayerColumn: Int?
    private var previousSnapshot: GameSnapshot?
    private var previousRoadMarkerState: RoadMarkerState?

    init(
        canonicalPlayerCar: Entity,
        canonicalRivalCar: Entity,
        snapshot: GameSnapshot,
        layout: TabletopBoardLayout = .standard,
        visualStyle: TabletopSceneVisualStyle = .standard
    ) throws {
        self.layout = layout
        self.visualStyle = visualStyle
        root.name = Self.rootName

        let playerPlacement = try Self.placement(
            for: canonicalPlayerCar,
            role: .player,
            layout: layout
        )
        let rivalPlacement = try Self.placement(
            for: canonicalRivalCar,
            role: .rival,
            layout: layout
        )

        player = Self.makeCarAnchor(
            name: Self.playerName,
            canonicalCar: canonicalPlayerCar,
            placement: playerPlacement
        )
        rivals = (0..<Self.rivalCount).map { index in
            let rival = Self.makeCarAnchor(
                name: Self.rivalName(index: index),
                canonicalCar: canonicalRivalCar,
                placement: rivalPlacement
            )
            rival.isEnabled = false
            return rival
        }
        collisionPlayer = Self.makeCarAnchor(
            name: "tabletop-collision-player",
            canonicalCar: canonicalPlayerCar,
            placement: playerPlacement
        )
        collisionRival = Self.makeCarAnchor(
            name: "tabletop-collision-rival",
            canonicalCar: canonicalRivalCar,
            placement: rivalPlacement
        )

        let board = try TabletopSceneEntityFactory.makeBoard(
            layout: layout,
            visualStyle: visualStyle
        )
        laneTargets = board.laneTargets
        roadDashes = board.roadDashes
        finishMarker = board.finishMarker
        collisionEffect = TabletopCollisionEffect(
            playerCar: collisionPlayer,
            rivalCar: collisionRival,
            visualStyle: visualStyle
        )
        impactBurst = collisionEffect.burst
        collisionPose = collisionEffect.root

        root.addChild(board.root)
        root.addChild(player)
        rivals.forEach { root.addChild($0) }
        root.addChild(collisionEffect.root)
        update(snapshot: snapshot, inputEnabled: false)
        try validateNormalizedCars()
    }

    func update(
        snapshot: GameSnapshot,
        reduceMotion: Bool? = nil,
        inputEnabled: Bool = true
    ) {
        if let reduceMotion {
            collisionEffect.setReduceMotionEnabled(reduceMotion)
        }
        let shouldAnimate = reduceMotion != true
            && visualStyle.reduceMotion == false
            && previousSnapshot != nil
        updatePlayer(snapshot: snapshot, shouldAnimate: shouldAnimate)
        updateRivals(snapshot: snapshot, shouldAnimate: shouldAnimate)
        collisionEffect.update(
            phase: snapshot.phase,
            position: layout.carPosition(
                row: max(snapshot.numberOfRows - 1, 0),
                column: snapshot.playerColumn
            )
        )

        for target in laneTargets {
            target.isEnabled = inputEnabled && snapshot.phase == .running
        }
        if accessibilityPlayerColumn != snapshot.playerColumn {
            accessibilityPlayerColumn = snapshot.playerColumn
            updateLaneAccessibility(playerColumn: snapshot.playerColumn)
        }

        updateRoadMarkers(snapshot: snapshot)
        previousSnapshot = snapshot
    }

    static func lane(for entity: Entity) -> Int? {
        let prefix = "tabletop-lane-target-"
        guard entity.name.hasPrefix(prefix) else { return nil }
        return Int(entity.name.dropFirst(prefix.count))
    }

    private func updatePlayer(snapshot: GameSnapshot, shouldAnimate: Bool) {
        let position = layout.carPosition(
            row: max(snapshot.numberOfRows - 1, 0),
            column: snapshot.playerColumn
        )
        let laneChanged = previousSnapshot?.playerColumn != snapshot.playerColumn
        setPosition(player, to: position, animated: shouldAnimate && laneChanged)
        player.isEnabled = Self.shouldShowPlayer(for: snapshot.phase)
    }

    private func updateRivals(snapshot: GameSnapshot, shouldAnimate: Bool) {
        for index in rivals.indices {
            let row = index / layout.laneCount
            let column = index % layout.laneCount
            let rival = rivals[index]
            let isVisible = occupant(snapshot: snapshot, row: row, column: column) == .rival
            let targetPosition = layout.carPosition(row: row, column: column)
            let advancedFromPreviousRow = row > 0
                && occupant(snapshot: previousSnapshot, row: row - 1, column: column) == .rival
                && isVisible
            if shouldAnimate && advancedFromPreviousRow {
                rival.stopAllAnimations()
                rival.position = layout.carPosition(row: row - 1, column: column)
                rival.isEnabled = true
                setPosition(rival, to: targetPosition, animated: true)
            } else {
                setPosition(rival, to: targetPosition, animated: false)
                rival.isEnabled = isVisible
            }
        }
    }

    private func setPosition(_ entity: Entity, to position: SIMD3<Float>, animated: Bool) {
        entity.stopAllAnimations()
        guard animated else {
            entity.position = position
            return
        }
        var target = entity.transform
        target.translation = position
        entity.move(
            to: target,
            relativeTo: entity.parent,
            duration: Self.animationDuration,
            timingFunction: .easeInOut
        )
    }

    private func updateLaneAccessibility(playerColumn: Int) {
        for (lane, target) in laneTargets.enumerated() {
            target.accessibilityValue = lane == playerColumn
                ? LocalizedStringResource(
                    stringLiteral: GameLocalizedStrings.string("vision_current_lane")
                )
                : LocalizedStringResource(
                    stringLiteral: GameLocalizedStrings.string("vision_select_lane")
                )
        }
    }

    private func updateRoadMarkers(snapshot: GameSnapshot) {
        let markerState = RoadMarkerState(
            roadPhase: snapshot.roadPhase,
            safetyMarkerRows: snapshot.safetyMarkerRows
        )
        guard markerState != previousRoadMarkerState else { return }
        previousRoadMarkerState = markerState

        let markerLayout = RoadMarkerLayoutResolver.resolve(
            roadPhase: markerState.roadPhase,
            rowCount: layout.rowCount,
            safetyMarkerRows: markerState.safetyMarkerRows
        )
        let visibleRows = Set(markerLayout.visibleDashRows)
        for dash in roadDashes {
            dash.entity.isEnabled = visibleRows.contains(dash.row)
        }

        guard let finishCenterRow = markerLayout.finishStripCenterRow else {
            finishMarker.isEnabled = false
            return
        }
        finishMarker.position = layout.finishMarkerCenter(logicalRow: finishCenterRow)
        finishMarker.isEnabled = true
    }

    private func validateNormalizedCars() throws {
        try validateNormalizedCar(player, role: .player)
        guard let rival = rivals.first else {
            throw TabletopSceneError.invalidNormalizedModel(.rival)
        }
        try validateNormalizedCar(rival, role: .rival)
    }

    private func validateNormalizedCar(_ car: Entity, role: TabletopCarRole) throws {
        let bounds = car.visualBounds(relativeTo: root)
        let extents = bounds.extents
        guard bounds.isEmpty == false,
              Self.allFinite(bounds.min),
              Self.allFinite(bounds.max),
              extents.x > 0,
              extents.y > 0,
              extents.z > 0,
              extents.x <= layout.carMaximumWidth + 0.0001,
              extents.z <= layout.carMaximumDepth + 0.0001 else {
            throw TabletopSceneError.invalidNormalizedModel(role)
        }
        let roadHalfWidth = layout.roadWidth / 2
        let roadHalfDepth = layout.roadDepth / 2
        guard bounds.min.x >= -roadHalfWidth - 0.0001,
              bounds.max.x <= roadHalfWidth + 0.0001,
              bounds.min.z >= -roadHalfDepth - 0.0001,
              bounds.max.z <= roadHalfDepth + 0.0001,
              bounds.min.y >= layout.roadTopY - 0.0001 else {
            throw TabletopSceneError.modelOutsideRoad(role)
        }
    }

    private static func placement(
        for entity: Entity,
        role: TabletopCarRole,
        layout: TabletopBoardLayout
    ) throws -> TabletopModelPlacement {
        let bounds = entity.visualBounds(relativeTo: entity)
        guard let placement = layout.modelPlacement(
            boundsMinimum: bounds.min,
            boundsMaximum: bounds.max
        ), placement.scale.isFinite, placement.scale > 0 else {
            throw TabletopSceneError.invalidModelBounds(role)
        }
        return placement
    }

    private static func rivalName(index: Int) -> String {
        "tabletop-rival-\(index / 3)-\(index % 3)"
    }

    private static func shouldShowPlayer(for phase: GamePhase) -> Bool {
        switch phase {
        case .running, .paused:
            true
        case .ready, .collision, .gameOver, .finished:
            false
        @unknown default:
            false
        }
    }

    private static func makeCarAnchor(
        name: String,
        canonicalCar: Entity,
        placement: TabletopModelPlacement
    ) -> Entity {
        let anchor = Entity()
        anchor.name = name
        let model = canonicalCar.clone(recursive: true)
        model.transform = Transform(
            scale: SIMD3(repeating: placement.scale),
            rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0)),
            translation: placement.modelOffset
        )
        anchor.addChild(model)
        return anchor
    }

    private func occupant(
        snapshot: GameSnapshot?,
        row: Int,
        column: Int
    ) -> GameGridOccupant? {
        guard let snapshot,
              snapshot.grid.indices.contains(row),
              snapshot.grid[row].indices.contains(column) else {
            return nil
        }
        return snapshot.grid[row][column]
    }

    private static func allFinite(_ value: SIMD3<Float>) -> Bool {
        value.x.isFinite && value.y.isFinite && value.z.isFinite
    }
}

private struct RoadMarkerState: Equatable {
    let roadPhase: Int
    let safetyMarkerRows: [Int]
}

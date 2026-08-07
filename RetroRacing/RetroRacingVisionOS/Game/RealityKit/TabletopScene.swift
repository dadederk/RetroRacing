//
//  TabletopScene.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation
import RealityKit
import RetroRacingShared
import UIKit

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

/// Owns the fixed RealityKit entity pool and all snapshot-derived transforms.
@MainActor
final class TabletopScene {
    static let rootName = "tabletop-race-root"
    static let playerName = "tabletop-player"
    static let rivalCount = 15

    let root = Entity()
    let player: Entity
    let rivals: [Entity]
    let laneTargets: [ModelEntity]
    let safetyMarkers: [ModelEntity]
    let layout: TabletopBoardLayout
    let visualStyle: TabletopSceneVisualStyle
    let impactBurst: Entity
    var isImpactPulsing: Bool { collisionEffect.isPulsing }

    private let collisionEffect: TabletopCollisionEffect
    private var accessibilityPlayerColumn: Int?

    init(
        canonicalPlayerCar: Entity,
        canonicalRivalCar: Entity,
        snapshot: GameSnapshot,
        layout: TabletopBoardLayout = .standard,
        visualStyle: TabletopSceneVisualStyle = .standard
    ) {
        self.layout = layout
        self.visualStyle = visualStyle
        root.name = Self.rootName
        root.position.y = layout.boardVerticalOffset

        let playerBounds = canonicalPlayerCar.visualBounds(relativeTo: canonicalPlayerCar)
        let rivalBounds = canonicalRivalCar.visualBounds(relativeTo: canonicalRivalCar)
        let playerPlacement = layout.modelPlacement(
            boundsMinimum: playerBounds.min,
            boundsMaximum: playerBounds.max
        ) ?? Self.fallbackPlacement(layout: layout)
        let rivalPlacement = layout.modelPlacement(
            boundsMinimum: rivalBounds.min,
            boundsMaximum: rivalBounds.max
        ) ?? Self.fallbackPlacement(layout: layout)

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
        let board = TabletopSceneEntityFactory.makeBoard(
            layout: layout,
            visualStyle: visualStyle
        )
        laneTargets = board.laneTargets
        safetyMarkers = board.safetyMarkers
        collisionEffect = TabletopCollisionEffect(visualStyle: visualStyle)
        impactBurst = collisionEffect.root

        root.addChild(board.root)
        root.addChild(player)
        rivals.forEach { root.addChild($0) }
        root.addChild(impactBurst)
        update(snapshot: snapshot)
    }

    func update(snapshot: GameSnapshot, reduceMotion: Bool? = nil) {
        if let reduceMotion {
            collisionEffect.setReduceMotionEnabled(reduceMotion)
        }
        let playerPosition = layout.carPosition(
            row: max(snapshot.numberOfRows - 1, 0),
            column: snapshot.playerColumn
        )
        player.position = playerPosition
        player.isEnabled = Self.shouldShowPlayer(for: snapshot.phase)
        collisionEffect.update(
            phase: snapshot.phase,
            position: layout.cellCenter(
                row: max(snapshot.numberOfRows - 1, 0),
                column: snapshot.playerColumn,
                y: layout.roadTopY + 0.055
            )
        )

        for index in rivals.indices {
            let row = index / layout.laneCount
            let column = index % layout.laneCount
            let rival = rivals[index]
            rival.position = layout.carPosition(
                row: row,
                column: column
            )
            rival.isEnabled = occupant(snapshot: snapshot, row: row, column: column) == .rival
        }

        for target in laneTargets {
            target.isEnabled = snapshot.phase == .running
        }
        if accessibilityPlayerColumn != snapshot.playerColumn {
            accessibilityPlayerColumn = snapshot.playerColumn
            updateLaneAccessibility(playerColumn: snapshot.playerColumn)
        }

        for (index, marker) in safetyMarkers.enumerated() {
            guard snapshot.safetyMarkerRows.indices.contains(index) else {
                marker.isEnabled = false
                continue
            }
            marker.position = layout.safetyMarkerCenter(row: snapshot.safetyMarkerRows[index])
            marker.isEnabled = true
        }
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

    static func lane(for entity: Entity) -> Int? {
        let prefix = "tabletop-lane-target-"
        guard entity.name.hasPrefix(prefix) else { return nil }
        return Int(entity.name.dropFirst(prefix.count))
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

    private static func fallbackPlacement(
        layout _: TabletopBoardLayout
    ) -> TabletopModelPlacement {
        TabletopModelPlacement(
            scale: 1,
            modelOffset: .zero
        )
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

    private func occupant(snapshot: GameSnapshot, row: Int, column: Int) -> GameGridOccupant? {
        guard snapshot.grid.indices.contains(row), snapshot.grid[row].indices.contains(column) else {
            return nil
        }
        return snapshot.grid[row][column]
    }
}

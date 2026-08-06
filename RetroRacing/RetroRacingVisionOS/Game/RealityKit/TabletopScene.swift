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

    nonisolated static let standard = TabletopSceneVisualStyle(
        increasedContrast: false,
        differentiateWithoutColor: false
    )
}

/// Owns the fixed RealityKit entity pool and all snapshot-derived transforms.
@MainActor
final class TabletopScene {
    static let rootName = "tabletop-race-root"
    static let playerName = "tabletop-player"
    static let rivalCount = 15

    private static let laneSpacing: Float = 0.19
    private static let rowSpacing: Float = 0.17
    private static let firstRowZ: Float = -0.34
    private static let modelScale: Float = 0.055

    let root = Entity()
    let player: Entity
    let rivals: [Entity]
    let laneTargets: [ModelEntity]
    let visualStyle: TabletopSceneVisualStyle

    init(
        canonicalPlayerCar: Entity,
        canonicalRivalCar: Entity,
        snapshot: GameSnapshot,
        visualStyle: TabletopSceneVisualStyle = .standard
    ) {
        self.visualStyle = visualStyle
        root.name = Self.rootName
        player = canonicalPlayerCar.clone(recursive: true)
        player.name = Self.playerName
        rivals = (0..<Self.rivalCount).map { index in
            let rival = canonicalRivalCar.clone(recursive: true)
            rival.name = Self.rivalName(index: index)
            rival.isEnabled = false
            return rival
        }
        laneTargets = (0..<3).map(Self.makeLaneTarget)

        addBoard(visualStyle: visualStyle)
        root.addChild(player)
        rivals.forEach { root.addChild($0) }
        laneTargets.forEach { root.addChild($0) }
        update(snapshot: snapshot)
    }

    func update(snapshot: GameSnapshot) {
        player.position = Self.carPosition(
            row: max(snapshot.numberOfRows - 1, 0),
            column: snapshot.playerColumn
        )
        player.scale = SIMD3(repeating: Self.modelScale)
        player.orientation = snapshot.phase == .collision
            ? simd_quatf(angle: .pi / 8, axis: SIMD3<Float>(0, 0, 1))
            : simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        player.isEnabled = snapshot.phase != .ready && snapshot.phase != .finished

        for index in rivals.indices {
            let row = index / 3
            let column = index % 3
            let rival = rivals[index]
            rival.position = Self.carPosition(row: row, column: column)
            rival.scale = SIMD3(repeating: Self.modelScale)
            rival.isEnabled = occupant(snapshot: snapshot, row: row, column: column) == .rival
        }

        for (lane, target) in laneTargets.enumerated() {
            target.accessibilityValue = lane == snapshot.playerColumn
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

    private func addBoard(visualStyle: TabletopSceneVisualStyle) {
        let baseMaterial = SimpleMaterial(
            color: visualStyle.increasedContrast
                ? .black
                : UIColor(red: 0.04, green: 0.13, blue: 0.12, alpha: 1),
            roughness: 0.82,
            isMetallic: false
        )
        let roadMaterial = SimpleMaterial(
            color: visualStyle.increasedContrast
                ? UIColor(white: 0.08, alpha: 1)
                : UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1),
            roughness: 0.76,
            isMetallic: false
        )
        let emphasizesShape = visualStyle.increasedContrast || visualStyle.differentiateWithoutColor
        let laneMaterial = SimpleMaterial(
            color: emphasizesShape ? .white : .cyan,
            roughness: 0.55,
            isMetallic: false
        )

        let base = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.76, 0.035, 1.08), cornerRadius: 0.035),
            materials: [baseMaterial]
        )
        base.name = "tabletop-base"
        base.position.y = -0.035
        root.addChild(base)

        let road = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.62, 0.018, 0.96), cornerRadius: 0.012),
            materials: [roadMaterial]
        )
        road.name = "tabletop-road"
        road.position.y = -0.008
        root.addChild(road)

        for laneX in [-Self.laneSpacing / 2, Self.laneSpacing / 2] {
            let divider = ModelEntity(
                mesh: .generateBox(
                    size: SIMD3<Float>(emphasizesShape ? 0.014 : 0.009, 0.006, 0.91),
                    cornerRadius: 0.003
                ),
                materials: [laneMaterial]
            )
            divider.name = "tabletop-lane-divider"
            divider.position = SIMD3(laneX, 0.005, 0)
            root.addChild(divider)
        }

        let finish = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.61, 0.007, 0.018), cornerRadius: 0.003),
            materials: [SimpleMaterial(color: .yellow, roughness: 0.5, isMetallic: false)]
        )
        finish.name = "tabletop-finish-line"
        finish.position = SIMD3(0, 0.006, 0.38)
        root.addChild(finish)
    }

    private static func makeLaneTarget(lane: Int) -> ModelEntity {
        let material = UnlitMaterial(color: UIColor.white.withAlphaComponent(0.001))
        let target = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.19, 0.014, 0.94)),
            materials: [material]
        )
        target.name = "tabletop-lane-target-\(lane)"
        target.position = SIMD3((Float(lane) - 1) * laneSpacing, 0.012, 0)
        target.components.set(CollisionComponent(
            shapes: [.generateBox(size: SIMD3<Float>(0.19, 0.035, 0.94))]
        ))
        target.components.set(InputTargetComponent(allowedInputTypes: .all))
        target.components.set(HoverEffectComponent(.highlight(.default)))

        var accessibility = AccessibilityComponent()
        accessibility.isAccessibilityElement = true
        accessibility.label = LocalizedStringResource(
            stringLiteral: GameLocalizedStrings.format("vision_lane_format", lane + 1)
        )
        accessibility.systemActions = [.activate]
        target.components.set(accessibility)
        return target
    }

    private static func carPosition(row: Int, column: Int) -> SIMD3<Float> {
        let x = (Float(column) - 1) * laneSpacing
        let z = firstRowZ + (Float(row) * rowSpacing)
        return SIMD3(x, 0.02, z)
    }

    private static func rivalName(index: Int) -> String {
        "tabletop-rival-\(index / 3)-\(index % 3)"
    }

    private func occupant(snapshot: GameSnapshot, row: Int, column: Int) -> GameGridOccupant? {
        guard snapshot.grid.indices.contains(row), snapshot.grid[row].indices.contains(column) else {
            return nil
        }
        return snapshot.grid[row][column]
    }
}

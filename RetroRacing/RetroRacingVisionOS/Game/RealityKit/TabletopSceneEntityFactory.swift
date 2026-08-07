//
//  TabletopSceneEntityFactory.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import RealityKit
import RetroRacingShared
import UIKit

@MainActor
struct TabletopBoardEntities {
    let root: Entity
    let laneTargets: [ModelEntity]
    let safetyMarkers: [ModelEntity]
}

@MainActor
enum TabletopSceneEntityFactory {
    static func makeBoard(
        layout: TabletopBoardLayout,
        visualStyle: TabletopSceneVisualStyle
    ) -> TabletopBoardEntities {
        let root = Entity()
        root.name = "tabletop-board"
        root.addChild(makeBase(layout: layout, visualStyle: visualStyle))
        root.addChild(makeRoad(layout: layout, visualStyle: visualStyle))
        makeVerges(layout: layout, visualStyle: visualStyle).forEach {
            root.addChild($0)
        }
        makeLaneDividers(layout: layout, visualStyle: visualStyle).forEach {
            root.addChild($0)
        }

        let laneTargets = (0..<layout.laneCount).map {
            makeLaneTarget(lane: $0, layout: layout)
        }
        laneTargets.forEach {
            root.addChild($0)
        }

        let safetyMarkers = (0..<2).map {
            makeSafetyMarker(index: $0, layout: layout, visualStyle: visualStyle)
        }
        safetyMarkers.forEach {
            root.addChild($0)
        }
        return TabletopBoardEntities(
            root: root,
            laneTargets: laneTargets,
            safetyMarkers: safetyMarkers
        )
    }

    private static func makeBase(
        layout: TabletopBoardLayout,
        visualStyle: TabletopSceneVisualStyle
    ) -> ModelEntity {
        let material = SimpleMaterial(
            color: visualStyle.increasedContrast
                ? .black
                : UIColor(red: 0.035, green: 0.11, blue: 0.10, alpha: 1),
            roughness: 0.84,
            isMetallic: false
        )
        let base = ModelEntity(
            mesh: .generateBox(
                size: SIMD3(layout.boardSide, layout.boardHeight, layout.boardSide),
                cornerRadius: 0.026
            ),
            materials: [material]
        )
        base.name = "tabletop-base"
        base.position.y = layout.boardCenterY
        return base
    }

    private static func makeRoad(
        layout: TabletopBoardLayout,
        visualStyle: TabletopSceneVisualStyle
    ) -> ModelEntity {
        let material = SimpleMaterial(
            color: visualStyle.increasedContrast
                ? UIColor(white: 0.08, alpha: 1)
                : UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1),
            roughness: 0.76,
            isMetallic: false
        )
        let road = ModelEntity(
            mesh: .generateBox(
                size: SIMD3(layout.roadWidth, layout.roadHeight, layout.roadDepth),
                cornerRadius: 0.008
            ),
            materials: [material]
        )
        road.name = "tabletop-road"
        road.position.y = layout.roadCenterY
        return road
    }

    private static func makeVerges(
        layout: TabletopBoardLayout,
        visualStyle: TabletopSceneVisualStyle
    ) -> [ModelEntity] {
        let material = SimpleMaterial(
            color: visualStyle.increasedContrast
                ? .white
                : UIColor(red: 0.07, green: 0.30, blue: 0.24, alpha: 1),
            roughness: 0.92,
            isMetallic: false
        )
        return [-1 as Float, 1].map { direction in
            let verge = ModelEntity(
                mesh: .generateBox(
                    size: SIMD3(layout.sideVergeWidth, layout.vergeHeight, layout.roadDepth),
                    cornerRadius: 0.006
                ),
                materials: [material]
            )
            verge.name = direction < 0 ? "tabletop-left-verge" : "tabletop-right-verge"
            verge.position = SIMD3(
                direction * (layout.roadWidth + layout.sideVergeWidth) / 2,
                layout.vergeCenterY,
                0
            )
            return verge
        }
    }

    private static func makeLaneDividers(
        layout: TabletopBoardLayout,
        visualStyle: TabletopSceneVisualStyle
    ) -> [ModelEntity] {
        let emphasizesShape = visualStyle.increasedContrast
            || visualStyle.differentiateWithoutColor
        let material = UnlitMaterial(color: emphasizesShape ? .white : .cyan)
        return layout.laneDividerPositions.map { x in
            let divider = ModelEntity(
                mesh: .generatePlane(
                    width: emphasizesShape ? 0.012 : 0.008,
                    depth: layout.roadDepth
                ),
                materials: [material]
            )
            divider.name = "tabletop-lane-divider"
            divider.position = SIMD3(x, layout.roadOverlayY, 0)
            return divider
        }
    }

    private static func makeLaneTarget(
        lane: Int,
        layout: TabletopBoardLayout
    ) -> ModelEntity {
        let size = layout.laneTargetSize
        let target = ModelEntity(
            mesh: .generatePlane(width: layout.cellSide, depth: layout.roadDepth),
            materials: [UnlitMaterial(color: UIColor.white.withAlphaComponent(0.001))]
        )
        target.name = "tabletop-lane-target-\(lane)"
        target.position = layout.laneTargetCenter(lane)
        target.components.set(CollisionComponent(shapes: [.generateBox(size: size)]))
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

    private static func makeSafetyMarker(
        index: Int,
        layout: TabletopBoardLayout,
        visualStyle: TabletopSceneVisualStyle
    ) -> ModelEntity {
        let emphasizesShape = visualStyle.increasedContrast
            || visualStyle.differentiateWithoutColor
        let marker = ModelEntity(
            mesh: .generatePlane(
                width: layout.roadWidth,
                depth: emphasizesShape ? 0.016 : 0.012
            ),
            materials: [UnlitMaterial(color: emphasizesShape ? .white : .yellow)]
        )
        marker.name = "tabletop-safety-marker-\(index)"
        marker.isEnabled = false
        return marker
    }
}

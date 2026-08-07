//
//  TabletopSceneEntityFactory.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import RealityKit
import RetroRacingShared
import SwiftUI
import UIKit

@MainActor
struct TabletopBoardEntities {
    let root: Entity
    let laneTargets: [ModelEntity]
    let roadDashes: [TabletopRoadDash]
    let finishMarker: ModelEntity
}

@MainActor
struct TabletopRoadDash {
    let row: Int
    let boundary: Int
    let entity: ModelEntity
}

@MainActor
enum TabletopSceneEntityFactory {
    static func makeBoard(
        layout: TabletopBoardLayout,
        visualStyle: TabletopSceneVisualStyle
    ) throws -> TabletopBoardEntities {
        let root = Entity()
        root.name = "tabletop-board"
        root.addChild(makeBase(layout: layout, visualStyle: visualStyle))
        root.addChild(makeRoad(layout: layout, visualStyle: visualStyle))
        makeVerges(layout: layout, visualStyle: visualStyle).forEach {
            root.addChild($0)
        }
        root.addChild(makeKeyLight())

        let laneTargets = (0..<layout.laneCount).map {
            makeLaneTarget(lane: $0, layout: layout)
        }
        laneTargets.forEach {
            root.addChild($0)
        }

        let roadDashes = makeRoadDashes(layout: layout, visualStyle: visualStyle)
        roadDashes.forEach {
            root.addChild($0.entity)
        }
        let finishMarker = try makeFinishMarker(
            layout: layout,
            visualStyle: visualStyle
        )
        root.addChild(finishMarker)
        return TabletopBoardEntities(
            root: root,
            laneTargets: laneTargets,
            roadDashes: roadDashes,
            finishMarker: finishMarker
        )
    }

    private static func makeBase(
        layout: TabletopBoardLayout,
        visualStyle: TabletopSceneVisualStyle
    ) -> ModelEntity {
        let material = SimpleMaterial(
            color: palette(for: visualStyle).verge,
            roughness: 0.84,
            isMetallic: false
        )
        let base = ModelEntity(
            mesh: .generateBox(
                size: SIMD3(layout.boardWidth, layout.boardHeight, layout.boardDepth),
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
            color: palette(for: visualStyle).road,
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
            color: palette(for: visualStyle).verge,
            roughness: 0.92,
            isMetallic: false
        )
        let sideVerges = [-1 as Float, 1].map { direction in
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
        let endVerges = [-1 as Float, 1].map { direction in
            let verge = ModelEntity(
                mesh: .generateBox(
                    size: SIMD3(layout.boardWidth, layout.vergeHeight, layout.endVergeDepth),
                    cornerRadius: 0.004
                ),
                materials: [material]
            )
            verge.name = direction < 0 ? "tabletop-far-verge" : "tabletop-near-verge"
            verge.position = SIMD3(
                0,
                layout.vergeCenterY,
                direction * (layout.roadDepth + layout.endVergeDepth) / 2
            )
            return verge
        }
        return sideVerges + endVerges
    }

    private static func makeRoadDashes(
        layout: TabletopBoardLayout,
        visualStyle: TabletopSceneVisualStyle
    ) -> [TabletopRoadDash] {
        let emphasizesShape = visualStyle.increasedContrast
            || visualStyle.differentiateWithoutColor
        let material = UnlitMaterial(color: palette(for: visualStyle).roadLine)
        return (0..<layout.rowCount).flatMap { row in
            layout.roadBoundaryPositions.enumerated().map { boundary, x in
                let entity = ModelEntity(
                    mesh: .generatePlane(
                        width: emphasizesShape ? 0.012 : 0.008,
                        depth: layout.roadDashDepth
                    ),
                    materials: [material]
                )
                entity.name = "tabletop-road-dash-\(row)-\(boundary)"
                entity.position = SIMD3(x, layout.roadOverlayY, layout.rowCenterZ(row))
                entity.isEnabled = false
                return TabletopRoadDash(row: row, boundary: boundary, entity: entity)
            }
        }
    }

    private static func makeLaneTarget(
        lane: Int,
        layout: TabletopBoardLayout
    ) -> ModelEntity {
        let size = layout.laneTargetSize
        let target = ModelEntity(
            mesh: .generatePlane(width: layout.laneWidth, depth: layout.roadDepth),
            materials: [UnlitMaterial(color: UIColor.white.withAlphaComponent(0.001))]
        )
        target.name = "tabletop-lane-target-\(lane)"
        target.position = layout.laneTargetCenter(lane)
        target.components.set(CollisionComponent(shapes: [.generateBox(size: size)]))
        target.components.set(InputTargetComponent(allowedInputTypes: .all))

        var accessibility = AccessibilityComponent()
        accessibility.isAccessibilityElement = true
        accessibility.label = LocalizedStringResource(
            stringLiteral: GameLocalizedStrings.format("vision_lane_format", lane + 1)
        )
        accessibility.systemActions = [.activate]
        target.components.set(accessibility)
        return target
    }

    private static func makeKeyLight() -> DirectionalLight {
        let light = DirectionalLight()
        light.name = "tabletop-key-light"
        light.light = DirectionalLightComponent(color: .white, intensity: 2_000)
        light.shadow = nil
        light.orientation = simd_quatf(
            angle: -.pi / 3,
            axis: SIMD3<Float>(1, 0, 0)
        ) * simd_quatf(
            angle: -.pi / 5,
            axis: SIMD3<Float>(0, 1, 0)
        )
        return light
    }

    private static func makeFinishMarker(
        layout: TabletopBoardLayout,
        visualStyle: TabletopSceneVisualStyle
    ) throws -> ModelEntity {
        let texture: TextureResource
        do {
            guard let mask = UIImage(
                named: "lapStripMask",
                in: VisionThemeSpriteAssets.bundle,
                compatibleWith: nil
            ), let cgImage = mask.cgImage else {
                throw TabletopSceneError.finishMarkerTextureUnavailable
            }
            texture = try TextureResource(
                image: cgImage,
                withName: "lapStripMask",
                options: .init(semantic: .color)
            )
        } catch {
            throw TabletopSceneError.finishMarkerTextureUnavailable
        }
        var material = UnlitMaterial()
        material.color = UnlitMaterial.BaseColor(
            tint: palette(for: visualStyle).finish,
            texture: UnlitMaterial.Texture(texture)
        )
        material.blending = .transparent(opacity: 1.0)
        let marker = ModelEntity(
            mesh: .generatePlane(
                width: layout.roadWidth,
                depth: layout.finishMarkerDepth
            ),
            materials: [material]
        )
        marker.name = "tabletop-finish-marker"
        marker.isEnabled = false
        return marker
    }

    private static func palette(
        for visualStyle: TabletopSceneVisualStyle
    ) -> TabletopRoadPalette {
        let theme = SixtyFourBitTheme()
        return TabletopRoadPalette(
            road: UIColor(theme.gridCellColor()),
            verge: UIColor(theme.roadExteriorColor() ?? theme.gridCellColor()),
            roadLine: UIColor(
                theme.roadLineColor(
                    isIncreaseContrastEnabled: visualStyle.increasedContrast
                )
            ),
            finish: UIColor(
                theme.lapMarkerColor(
                    isIncreaseContrastEnabled: visualStyle.increasedContrast
                )
            )
        )
    }
}

private struct TabletopRoadPalette {
    let road: UIColor
    let verge: UIColor
    let roadLine: UIColor
    let finish: UIColor
}

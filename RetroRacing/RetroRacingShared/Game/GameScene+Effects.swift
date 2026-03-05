//
//  GameScene+Effects.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SpriteKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private enum SpritePerspectiveConfiguration {
    static let farRowScale: CGFloat = 0.31
    static let depthExponent: CGFloat = 2.0
    static let linearDepthBlend: CGFloat = 0.45
}

/// Visual and accessibility effects applied to sprites within GameScene.
extension GameScene {

    func spriteNode(imageNamed name: String) -> SKSpriteNode {
        let texture = texture(imageNamed: name)
        return SKSpriteNode(texture: texture)
    }

    /// Loads texture via injected imageLoader so shared code has no UIKit/AppKit conditionals.
    func texture(imageNamed name: String) -> SKTexture {
        guard let imageLoader else {
            AppLog.error(AppLog.assets, "texture '\(name)' skipped: imageLoader not set yet (scene not fully initialized)")
            return SKTexture()
        }
        return imageLoader.loadTexture(imageNamed: name, bundle: Self.sharedBundle)
    }

    func addSprite(
        _ sprite: SKSpriteNode,
        toCell cell: SKShapeNode,
        row: Int,
        column: Int,
        accessibilityLabel: String? = nil,
        usesPlayerScale: Bool = false,
        laneCenterSceneX: CGFloat? = nil,
        sideLaneConvergenceFactor: CGFloat = 0
    ) {
        #if !os(watchOS)
        if let accessibilityLabel = accessibilityLabel {
            sprite.accessibilityLabel = accessibilityLabel
            sprite.isAccessibilityElement = true
        }
        #endif
        let cellSize = cell.frame.size
        let sizeFactor = spritePerspectiveScaleFactor(row: row, usesPlayerScale: usesPlayerScale)
        let spriteSize = CGSize(width: cellSize.width * sizeFactor, height: cellSize.height * sizeFactor)

        var horizontalTranslationFactor: CGFloat = 0.0
        let gap = cellSize.width - spriteSize.width
        if sideLaneConvergenceFactor > 0 {
            let depthDenominator = max(CGFloat(gridState.playerRowIndex), 1)
            let depth = CGFloat(gridState.playerRowIndex - row) / depthDenominator
            let convergenceOffset = (gap * 0.5) * depth * sideLaneConvergenceFactor
            if column < (gridState.numberOfColumns / 2) {
                horizontalTranslationFactor = convergenceOffset
            } else if column > (gridState.numberOfColumns / 2) {
                horizontalTranslationFactor = -convergenceOffset
            }
        }

        let cellOriginInLocal = cell.frame.origin
        let laneCenterX = laneCenterSceneX ?? (cellOriginInLocal.x + (cellSize.width / 2))
        let spritePosInCell = CGPoint(
            x: laneCenterX + horizontalTranslationFactor,
            y: cellOriginInLocal.y + cellSize.height / 2.0
        )
        sprite.position = spritePosInCell
        sprite.aspectFitToSize(spriteSize)
        sprite.zPosition = 2
        spritesForGivenState.append(sprite)
        cell.addChild(sprite)

        let texSize = sprite.texture?.size() ?? .zero
        if row == 0 && column == 0 && spritesForGivenState.count <= 1 {
            AppLog.log(AppLog.assets, "addSprite row=\(row) col=\(column) cellSize=\(cellSize) spriteSize=\(spriteSize) posInCell=\(spritePosInCell) textureSize=\(texSize) sprite.frame=\(sprite.frame) scale=\(sprite.xScale)")
        }

        if sprite.name == "crash" {
            let prefersReducedMotion: Bool = {
                #if os(iOS) || os(tvOS)
                return UIAccessibility.isReduceMotionEnabled
                #elseif os(macOS)
                return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
                #else
                return false
                #endif
            }()
            if prefersReducedMotion {
                sprite.run(SKAction.fadeIn(withDuration: 0.2))
            } else {
                let blinkOnce = SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.2),
                    SKAction.fadeIn(withDuration: 0.2)
                ])
                let blinkThreeTimes = SKAction.repeat(blinkOnce, count: 3)
                sprite.run(blinkThreeTimes)
            }
        }
    }

    private func spritePerspectiveScaleFactor(row: Int, usesPlayerScale: Bool) -> CGFloat {
        if usesPlayerScale {
            return 1
        }
        guard gridState.numberOfRows > 1 else {
            return 1
        }

        let clampedRow = max(0, min(row, gridState.numberOfRows - 1))
        let normalizedDepth = CGFloat(clampedRow) / CGFloat(gridState.numberOfRows - 1)
        let curvedDepth = CGFloat(pow(Double(normalizedDepth), Double(SpritePerspectiveConfiguration.depthExponent)))
        let easedDepth = (SpritePerspectiveConfiguration.linearDepthBlend * normalizedDepth)
            + ((1 - SpritePerspectiveConfiguration.linearDepthBlend) * curvedDepth)
        return SpritePerspectiveConfiguration.farRowScale
            + ((1 - SpritePerspectiveConfiguration.farRowScale) * easedDepth)
    }

    /// Applies a pulsing animation to the player car sprite during the start sequence.
    func applyStartPulseToPlayerCar() {
        let prefersReducedMotion: Bool = {
            #if os(iOS) || os(tvOS)
            return UIAccessibility.isReduceMotionEnabled
            #elseif os(macOS)
            return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            #else
            return false
            #endif
        }()

        guard !prefersReducedMotion else { return }

        let playerRow = gridState.playerRowIndex
        let playerColumn = gridState.playerRow().firstIndex(of: .Player) ?? lastPlayerColumn

        for sprite in spritesForGivenState {
            guard let parent = sprite.parent as? SKShapeNode else { continue }
            let cellName = nameForCell(column: playerColumn, row: playerRow)
            if parent.name == cellName {
                let fadeToSemi = SKAction.fadeAlpha(to: 0.4, duration: 0.3)
                let fadeToFull = SKAction.fadeAlpha(to: 1.0, duration: 0.3)
                let pulseOnce = SKAction.sequence([fadeToSemi, fadeToFull])
                let pulseAnimation = SKAction.repeat(pulseOnce, count: 3)
                sprite.run(pulseAnimation, withKey: "startPulse")
                break
            }
        }
    }

    /// Stops the pulsing animation on the player car sprite.
    func stopStartPulseOnPlayerCar() {
        let playerRow = gridState.playerRowIndex
        let playerColumn = gridState.playerRow().firstIndex(of: .Player) ?? lastPlayerColumn

        for sprite in spritesForGivenState {
            guard let parent = sprite.parent as? SKShapeNode else { continue }
            let cellName = nameForCell(column: playerColumn, row: playerRow)
            if parent.name == cellName {
                sprite.removeAction(forKey: "startPulse")
                sprite.alpha = 1.0
                break
            }
        }
    }
}

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

    func addSprite(_ sprite: SKSpriteNode, toCell cell: SKShapeNode, row: Int, column: Int, accessibilityLabel: String? = nil) {
        #if !os(watchOS)
        if let accessibilityLabel = accessibilityLabel {
            sprite.accessibilityLabel = accessibilityLabel
            sprite.isAccessibilityElement = true
        }
        #endif
        let cellSize = cell.frame.size
        let sizeFactor = CGFloat(gridState.numberOfRows - (gridState.numberOfRows - row - 1)) / CGFloat(gridState.numberOfRows)
        let spriteSize = CGSize(width: cellSize.width * sizeFactor, height: cellSize.height * sizeFactor)

        var horizontalTranslationFactor: CGFloat = 0.0

        if column < (gridState.numberOfColumns / 2) {
            horizontalTranslationFactor = (cellSize.width - spriteSize.width)
        } else if column > (gridState.numberOfColumns / 2) {
            horizontalTranslationFactor = -(cellSize.width - spriteSize.width)
        }

        let cellOriginInLocal = cell.frame.origin
        let spritePosInCell = CGPoint(
            x: cellOriginInLocal.x + (cellSize.width + horizontalTranslationFactor) / 2.0,
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
}

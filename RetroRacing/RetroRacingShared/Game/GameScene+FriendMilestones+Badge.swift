//
//  GameScene+FriendMilestones+Badge.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 05/04/2026.
//

import SpriteKit
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension GameScene {
    func makeFriendMilestoneBadge(
        milestone: UpcomingFriendMilestone,
        diameter: CGFloat,
        pinTintColor: SKColor,
        fallbackAvatarBackgroundColor: SKColor
    ) -> SKNode {
        let sourceDiameter = max(diameter, FriendMilestoneConfiguration.sourceRenderDiameter)
        let scale = diameter / sourceDiameter
        let container = SKNode()
        container.name = FriendMilestoneConfiguration.badgeNodeName
        container.zPosition = FriendMilestoneConfiguration.badgeZPosition

        let radius = sourceDiameter / 2
        let pointerPath = friendMilestonePointerPath(diameter: sourceDiameter)

        let pointer = SKShapeNode(path: pointerPath)
        pointer.fillColor = pinTintColor
        pointer.strokeColor = .clear
        pointer.lineWidth = 0
        pointer.isAntialiased = true
        pointer.zPosition = FriendMilestoneConfiguration.badgeZPosition
        pointer.name = FriendMilestoneConfiguration.badgePointerNodeName
        container.addChild(pointer)

        let backgroundCircle = SKShapeNode(circleOfRadius: radius)
        backgroundCircle.fillColor = pinTintColor
        backgroundCircle.strokeColor = .clear
        backgroundCircle.lineWidth = 0
        backgroundCircle.isAntialiased = true
        backgroundCircle.zPosition = FriendMilestoneConfiguration.badgeZPosition
        backgroundCircle.name = FriendMilestoneConfiguration.badgeNodeName
        container.addChild(backgroundCircle)

        let avatarDiameter = sourceDiameter * (1 - (FriendMilestoneConfiguration.avatarInsetFactor * 2))
        if let avatarNode = makeAvatarImageNode(for: milestone, diameter: sourceDiameter) {
            avatarNode.zPosition = FriendMilestoneConfiguration.badgeZPosition + 0.1
            container.addChild(avatarNode)
        } else {
            let avatarRadius = avatarDiameter / 2
            let avatarBackground = SKShapeNode(circleOfRadius: avatarRadius)
            avatarBackground.fillColor = fallbackAvatarBackgroundColor
            avatarBackground.strokeColor = .clear
            avatarBackground.lineWidth = 0
            avatarBackground.isAntialiased = true
            avatarBackground.name = FriendMilestoneConfiguration.badgeAvatarNodeName
            avatarBackground.zPosition = FriendMilestoneConfiguration.badgeZPosition + 0.05
            container.addChild(avatarBackground)

            let initialsNode = SKLabelNode(text: friendInitials(for: milestone.displayName))
            initialsNode.fontName = "Menlo-Bold"
            initialsNode.fontSize = sourceDiameter * 0.30
            initialsNode.fontColor = pinTintColor
            initialsNode.verticalAlignmentMode = .center
            initialsNode.horizontalAlignmentMode = .center
            initialsNode.name = FriendMilestoneConfiguration.badgeTextNodeName
            initialsNode.zPosition = FriendMilestoneConfiguration.badgeZPosition + 0.1
            container.addChild(initialsNode)
        }

        container.setScale(scale)

        #if !os(watchOS)
        container.isAccessibilityElement = true
        container.accessibilityLabel = GameLocalizedStrings.format(
            "friend_milestone_avatar %@ %lld",
            milestone.displayName,
            Int64(milestone.targetScore)
        )
        #endif

        return container
    }

    func friendMilestonePointerPath(diameter: CGFloat) -> CGPath {
        let radius = diameter / 2
        let baseHalfWidth = max(2, diameter * FriendMilestoneConfiguration.pointerBaseHalfWidthFactor)
        let pointerHeight = friendMilestonePointerHeight(diameter: diameter)
        let baseY = -radius + FriendMilestoneConfiguration.pointerCircleOverlap
        let tip = CGPoint(
            x: diameter * FriendMilestoneConfiguration.pointerRightLeanFactor,
            y: baseY - pointerHeight
        )

        let path = CGMutablePath()
        path.move(to: CGPoint(x: -baseHalfWidth, y: baseY))
        path.addLine(to: CGPoint(x: baseHalfWidth, y: baseY))
        path.addLine(to: tip)
        path.closeSubpath()
        return path
    }

    func friendMilestonePointerHeight(diameter: CGFloat) -> CGFloat {
        max(3, diameter * FriendMilestoneConfiguration.pointerHeightFactor)
    }

    func makeAvatarImageNode(for milestone: UpcomingFriendMilestone, diameter: CGFloat) -> SKNode? {
        let texture = textureForFriendAvatar(milestone)
        guard let texture else { return nil }
        texture.filteringMode = .linear

        let avatarDiameter = diameter * (1 - (FriendMilestoneConfiguration.avatarInsetFactor * 2))
        let sprite = SKSpriteNode(texture: texture)
        sprite.texture?.filteringMode = .linear
        sprite.size = CGSize(width: avatarDiameter, height: avatarDiameter)
        sprite.position = .zero

        let maskShape = SKShapeNode(circleOfRadius: avatarDiameter / 2)
        maskShape.fillColor = .white
        maskShape.strokeColor = .clear

        let cropNode = SKCropNode()
        cropNode.maskNode = maskShape
        cropNode.addChild(sprite)
        return cropNode
    }

    func textureForFriendAvatar(_ milestone: UpcomingFriendMilestone) -> SKTexture? {
        if let cachedTexture = cachedFriendAvatarTextures[milestone.playerID] {
            cachedTexture.filteringMode = .linear
            return cachedTexture
        }

        guard let avatarData = milestone.avatarPNGData else { return nil }
        #if os(iOS) || os(tvOS) || os(visionOS)
        guard let image = UIImage(data: avatarData) else { return nil }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        cachedFriendAvatarTextures[milestone.playerID] = texture
        return texture
        #elseif os(macOS)
        guard let image = NSImage(data: avatarData) else { return nil }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        cachedFriendAvatarTextures[milestone.playerID] = texture
        return texture
        #else
        return nil
        #endif
    }

    func friendInitials(for displayName: String) -> String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return "?" }
        let components = trimmed.split(separator: " ").filter { $0.isEmpty == false }
        if components.count >= 2,
           let first = components.first?.first,
           let second = components.dropFirst().first?.first {
            return String([first, second]).uppercased()
        }
        if let first = components.first?.first {
            return String(first).uppercased()
        }
        return "?"
    }
}

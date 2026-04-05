//
//  GameScene+FriendMilestones.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 05/04/2026.
//

import SpriteKit

enum FriendMilestoneConfiguration {
    static let badgeNodeName = "friend_milestone_badge"
    static let badgePointerNodeName = "friend_milestone_badge_pointer"
    static let badgeAvatarNodeName = "friend_milestone_badge_avatar"
    static let badgeTextNodeName = "friend_milestone_badge_text"
    static let badgeZPosition: CGFloat = 3.5
    static let minBadgeDiameter: CGFloat = 14
    static let maxBadgeDiameter: CGFloat = 42
    static let baseBadgeDiameterFactor: CGFloat = 0.56
    static let sourceRenderDiameter: CGFloat = 96
    static let pointerHeightFactor: CGFloat = 0.19
    static let pointerBaseHalfWidthFactor: CGFloat = 0.13
    static let pointerCircleOverlap: CGFloat = 1.1
    static let pointerRightLeanFactor: CGFloat = 0.05
    static let avatarInsetFactor: CGFloat = 0.07
    static let carClearanceFactor: CGFloat = 0.009
    static let overlapSpacingFactor: CGFloat = 0.58
}

extension GameScene {
    func upcomingMilestoneCarPosition(targetScore: Int, currentScore: Int) -> (row: Int, column: Int)? {
        let carsNeeded = targetScore - currentScore
        guard carsNeeded > 0 else { return nil }

        var remainingCars = carsNeeded
        let nearestRivalRow = gridState.playerRowIndex - 1
        guard nearestRivalRow >= 0 else { return nil }

        for row in stride(from: nearestRivalRow, through: 0, by: -1) {
            for column in 0..<gridState.numberOfColumns {
                guard gridState.grid[row][column] == .Car else { continue }
                remainingCars -= 1
                if remainingCars == 0 {
                    return (row: row, column: column)
                }
            }
        }

        return nil
    }

    func renderUpcomingFriendMilestoneMarkers() {
        guard upcomingFriendMilestones.isEmpty == false else { return }

        let candidates = friendMilestoneRenderCandidates()
        guard candidates.isEmpty == false else { return }

        let pinTintColor = roadLineColor()
        let fallbackAvatarBackgroundColor = gridCellFillColor()
        let xOffsets = friendMilestoneXOffsets(candidates: candidates)

        for (index, candidate) in candidates.enumerated() {
            let badgeNode = makeFriendMilestoneBadge(
                milestone: candidate.milestone,
                diameter: candidate.badgeDiameter,
                pinTintColor: pinTintColor,
                fallbackAvatarBackgroundColor: fallbackAvatarBackgroundColor
            )
            badgeNode.position = CGPoint(
                x: candidate.laneCenterX + xOffsets[index],
                y: candidate.centerY
            )
            friendMilestoneOverlayNodes.append(badgeNode)
            addChild(badgeNode)
        }
    }

    private struct FriendMilestoneRenderCandidate {
        let milestone: UpcomingFriendMilestone
        let row: Int
        let column: Int
        let laneCenterX: CGFloat
        let centerY: CGFloat
        let badgeDiameter: CGFloat
    }

    private func friendMilestoneRenderCandidates() -> [FriendMilestoneRenderCandidate] {
        var candidates = [FriendMilestoneRenderCandidate]()

        for milestone in upcomingFriendMilestones {
            guard let markerPosition = upcomingMilestoneCarPosition(
                targetScore: milestone.targetScore,
                currentScore: gameState.score
            ) else {
                continue
            }

            let cell = gridCell(column: markerPosition.column, row: markerPosition.row)
            let laneCenter = bigRivalCarsEnabled
                ? cell.frame.midX
                : laneCenterX(forColumn: markerPosition.column, row: markerPosition.row)
            let badgeDiameter = friendMilestoneBadgeDiameter(
                row: markerPosition.row,
                cellSize: cell.frame.size
            )
            let centerY = friendMilestoneCenterY(
                row: markerPosition.row,
                cell: cell,
                badgeDiameter: badgeDiameter
            )

            candidates.append(
                FriendMilestoneRenderCandidate(
                    milestone: milestone,
                    row: markerPosition.row,
                    column: markerPosition.column,
                    laneCenterX: laneCenter,
                    centerY: centerY,
                    badgeDiameter: badgeDiameter
                )
            )
        }

        return candidates
    }

    private func friendMilestoneXOffsets(candidates: [FriendMilestoneRenderCandidate]) -> [CGFloat] {
        var groupedIndices = [Int: [Int]]()
        for (index, candidate) in candidates.enumerated() {
            let key = (candidate.row * gridState.numberOfColumns) + candidate.column
            groupedIndices[key, default: []].append(index)
        }

        var xOffsets = Array(repeating: CGFloat.zero, count: candidates.count)
        for (_, indices) in groupedIndices {
            guard indices.count > 1 else { continue }
            let averageDiameter = indices.reduce(CGFloat.zero) { partial, idx in
                partial + candidates[idx].badgeDiameter
            } / CGFloat(indices.count)
            let spacing = averageDiameter * FriendMilestoneConfiguration.overlapSpacingFactor
            for (order, candidateIndex) in indices.enumerated() {
                let centered = CGFloat(order) - (CGFloat(indices.count - 1) / 2)
                xOffsets[candidateIndex] = centered * spacing
            }
        }

        return xOffsets
    }

    private func friendMilestoneBadgeDiameter(row: Int, cellSize: CGSize) -> CGFloat {
        let scaleFactor = spriteScaleFactorForRow(row: row, usesPlayerScale: bigRivalCarsEnabled)
        let scaledDiameter = cellSize.width * FriendMilestoneConfiguration.baseBadgeDiameterFactor * scaleFactor
        return max(
            FriendMilestoneConfiguration.minBadgeDiameter,
            min(FriendMilestoneConfiguration.maxBadgeDiameter, scaledDiameter)
        )
    }

    private func friendMilestoneCenterY(row: Int, cell: SKShapeNode, badgeDiameter: CGFloat) -> CGFloat {
        let carScale = spriteScaleFactorForRow(row: row, usesPlayerScale: bigRivalCarsEnabled)
        let carHeight = cell.frame.height * carScale
        let carTopY = cell.frame.midY + (carHeight / 2)
        let pointerHeight = friendMilestonePointerHeight(diameter: badgeDiameter)
        let clearance = max(0.1, cell.frame.height * FriendMilestoneConfiguration.carClearanceFactor)
        let tipY = carTopY + clearance
        return tipY + (badgeDiameter / 2) + pointerHeight
    }

}

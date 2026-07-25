//
//  GameSceneFriendMilestonesTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 03/04/2026.
//

import XCTest
import CoreGraphics
import SpriteKit
@testable import RetroRacingShared

final class GameSceneFriendMilestonesTests: XCTestCase {
    func testGivenVisibleCarsWhenResolvingUpcomingMilestonePositionThenReturnsMatchingCarCell() {
        // Given
        let scene = makeScene()
        scene.gridState = makeGridStateWithUpcomingCars()

        // When
        let position = scene.upcomingMilestoneCarPosition(targetScore: 103, currentScore: 100)

        // Then
        XCTAssertEqual(position?.row, 2)
        XCTAssertEqual(position?.column, 1)
    }

    func testGivenInsufficientVisibleCarsWhenResolvingUpcomingMilestonePositionThenReturnsNil() {
        // Given
        let scene = makeScene()
        scene.gridState = makeGridStateWithUpcomingCars()

        // When
        let position = scene.upcomingMilestoneCarPosition(targetScore: 110, currentScore: 100)

        // Then
        XCTAssertNil(position)
    }

    func testGivenTargetScoreNotAheadWhenResolvingUpcomingMilestonePositionThenReturnsNil() {
        // Given
        let scene = makeScene()
        scene.gridState = makeGridStateWithUpcomingCars()

        // When
        let position = scene.upcomingMilestoneCarPosition(targetScore: 100, currentScore: 100)

        // Then
        XCTAssertNil(position)
    }

    func testGivenUpcomingMilestoneWhenRenderingMarkerThenAddsPinPointerAndAvatarNodes() {
        // Given
        let scene = makeScene()
        scene.gridState = makeGridStateWithUpcomingCars()
        scene.createGrid()
        let milestone = UpcomingFriendMilestone(
            playerID: "friend-1",
            displayName: "Alex",
            targetScore: 1,
            avatarPNGData: nil
        )

        // When
        scene.setUpcomingFriendMilestone(milestone)

        // Then
        let marker = scene.children.first(where: { $0.name == "friend_milestone_badge" })
        XCTAssertNotNil(marker)
        XCTAssertNotNil(marker?.children.first(where: { $0.name == "friend_milestone_badge_pointer" }))
        XCTAssertNotNil(marker?.children.first(where: { $0.name == "friend_milestone_badge_avatar" }))
    }

    func testGivenTwoUpcomingMilestonesWhenRenderingMarkersThenBothMarkersAreAdded() {
        // Given
        let scene = makeScene()
        scene.gridState = makeGridStateWithUpcomingCars()
        scene.createGrid()
        let milestones = [
            UpcomingFriendMilestone(
                playerID: "friend-1",
                displayName: "Alex",
                targetScore: 1,
                avatarPNGData: nil
            ),
            UpcomingFriendMilestone(
                playerID: "friend-2",
                displayName: "Rita",
                targetScore: 2,
                avatarPNGData: nil
            )
        ]

        // When
        scene.setUpcomingFriendMilestones(milestones)

        // Then
        let markers = scene.children.filter { $0.name == "friend_milestone_badge" }
        XCTAssertEqual(markers.count, 2)
    }

    func testGivenPhonePlatformScaleWhenClampingBadgeDiameterThenKeepsBaseMinAndMax() {
        // Given
        let belowMin = FriendMilestoneConfiguration.minBadgeDiameter - 4
        let aboveMax = FriendMilestoneConfiguration.maxBadgeDiameter + 10
        let mid = (FriendMilestoneConfiguration.minBadgeDiameter + FriendMilestoneConfiguration.maxBadgeDiameter) / 2

        // When / Then
        XCTAssertEqual(
            FriendMilestoneConfiguration.clampedBadgeDiameter(scaledDiameter: belowMin, platformScale: 1),
            FriendMilestoneConfiguration.minBadgeDiameter
        )
        XCTAssertEqual(
            FriendMilestoneConfiguration.clampedBadgeDiameter(scaledDiameter: aboveMax, platformScale: 1),
            FriendMilestoneConfiguration.maxBadgeDiameter
        )
        XCTAssertEqual(
            FriendMilestoneConfiguration.clampedBadgeDiameter(scaledDiameter: mid, platformScale: 1),
            mid
        )
    }

    func testGivenExpandedPlatformScaleWhenClampingBadgeDiameterThenDoublesSizeAndClamps() {
        // Given
        let scale = FriendMilestoneConfiguration.expandedPlatformDiameterScale
        let belowMin = FriendMilestoneConfiguration.minBadgeDiameter - 4
        let aboveMax = FriendMilestoneConfiguration.maxBadgeDiameter + 10
        let mid = (FriendMilestoneConfiguration.minBadgeDiameter + FriendMilestoneConfiguration.maxBadgeDiameter) / 2

        // When / Then
        XCTAssertEqual(
            FriendMilestoneConfiguration.clampedBadgeDiameter(scaledDiameter: belowMin, platformScale: scale),
            FriendMilestoneConfiguration.minBadgeDiameter * scale
        )
        XCTAssertEqual(
            FriendMilestoneConfiguration.clampedBadgeDiameter(scaledDiameter: aboveMax, platformScale: scale),
            FriendMilestoneConfiguration.maxBadgeDiameter * scale
        )
        XCTAssertEqual(
            FriendMilestoneConfiguration.clampedBadgeDiameter(scaledDiameter: mid, platformScale: scale),
            mid * scale
        )
    }

    private func makeScene() -> GameScene {
        GameScene(
            size: CGSize(width: 200, height: 200),
            theme: nil,
            imageLoader: MilestoneMockImageLoader(),
            soundPlayer: MilestoneMockSoundPlayer(),
            laneCuePlayer: MilestoneMockLaneCuePlayer(),
            hapticController: nil,
            audioFeedbackMode: .retro,
            laneMoveCueStyle: .laneConfirmationAndSafety,
            difficulty: .rapid
        )
    }

    private func makeGridStateWithUpcomingCars() -> GridState {
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid[3] = [.Car, .Empty, .Car]
        gridState.grid[2] = [.Empty, .Car, .Empty]
        gridState.grid[1] = [.Car, .Empty, .Empty]
        gridState.grid[0] = [.Empty, .Empty, .Car]
        return gridState
    }
}

private final class MilestoneMockImageLoader: ImageLoader {
    func loadTexture(imageNamed name: String, bundle: Bundle) -> SKTexture {
        SKTexture()
    }
}

private final class MilestoneMockSoundPlayer: SoundEffectPlayer {
    func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        completion?()
    }

    func setVolume(_ volume: Double) {}
    func stopAll(fadeDuration: TimeInterval) {}
}

private final class MilestoneMockLaneCuePlayer: LaneCuePlayer {
    func playTickCue(safeColumns: Set<CueColumn>, mode: AudioFeedbackMode) {}
    func playMoveCue(column: CueColumn, isSafe: Bool, mode: AudioFeedbackMode, style: LaneMoveCueStyle) {}
    func playSpeedWarningCue() {}
    func setVolume(_ volume: Double) {}
    func stopAll(fadeDuration: TimeInterval) {}
}

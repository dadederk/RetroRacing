//
//  GameSceneDebugFrameStatsTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 04/04/2026.
//

import XCTest
import CoreGraphics
import SpriteKit
@testable import RetroRacingShared

final class GameSceneDebugFrameStatsTests: XCTestCase {
    func testGivenDebugFrameStatsDisabledWhenSceneMovesToViewThenBuiltInSpriteKitStatsAreDisabled() {
        // Given
        let scene = makeScene()
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 240, height: 240))

        // When
        scene.didMove(to: view)

        // Then
        XCTAssertFalse(view.showsFPS)
        XCTAssertFalse(view.showsNodeCount)
    }

    func testGivenDebugFrameStatsEnabledBeforeSceneMovesToViewThenBuiltInSpriteKitStatsAreEnabled() {
        // Given
        let scene = makeScene()
        scene.setDebugFrameStatsEnabled(true)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 240, height: 240))

        // When
        scene.didMove(to: view)

        // Then
        XCTAssertTrue(view.showsFPS)
        XCTAssertTrue(view.showsNodeCount)
    }

    func testGivenSceneIsHostedWhenTogglingDebugFrameStatsThenBuiltInSpriteKitStatsFollowToggle() {
        // Given
        let scene = makeScene()
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 240, height: 240))
        scene.didMove(to: view)

        // When
        scene.setDebugFrameStatsEnabled(true)

        // Then
        XCTAssertTrue(view.showsFPS)
        XCTAssertTrue(view.showsNodeCount)

        // When
        scene.setDebugFrameStatsEnabled(false)

        // Then
        XCTAssertFalse(view.showsFPS)
        XCTAssertFalse(view.showsNodeCount)
    }

    func testGivenDebugFrameStatsAlreadyEnabledWhenApplyingSameStateThenHostingViewFlagsAreReapplied() {
        // Given
        let scene = makeScene()
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 240, height: 240))
        scene.didMove(to: view)
        scene.setDebugFrameStatsEnabled(true)
        view.showsFPS = false
        view.showsNodeCount = false

        // When
        scene.setDebugFrameStatsEnabled(true)

        // Then
        XCTAssertTrue(view.showsFPS)
        XCTAssertTrue(view.showsNodeCount)
    }

    private func makeScene() -> GameScene {
        GameScene(
            size: CGSize(width: 200, height: 200),
            theme: nil,
            imageLoader: DebugStatsMockImageLoader(),
            soundPlayer: DebugStatsMockSoundPlayer(),
            laneCuePlayer: DebugStatsMockLaneCuePlayer(),
            hapticController: nil,
            audioFeedbackMode: .retro,
            laneMoveCueStyle: .laneConfirmationAndSafety,
            difficulty: .rapid
        )
    }
}

private final class DebugStatsMockImageLoader: ImageLoader {
    func loadTexture(imageNamed name: String, bundle: Bundle) -> SKTexture {
        SKTexture()
    }
}

private final class DebugStatsMockSoundPlayer: SoundEffectPlayer {
    func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        completion?()
    }

    func setVolume(_ volume: Double) {}
    func stopAll(fadeDuration: TimeInterval) {}
}

private final class DebugStatsMockLaneCuePlayer: LaneCuePlayer {
    func playTickCue(safeColumns: Set<CueColumn>, mode: AudioFeedbackMode) {}
    func playMoveCue(column: CueColumn, isSafe: Bool, mode: AudioFeedbackMode, style: LaneMoveCueStyle) {}
    func playSpeedWarningCue() {}
    func setVolume(_ volume: Double) {}
    func stopAll(fadeDuration: TimeInterval) {}
}

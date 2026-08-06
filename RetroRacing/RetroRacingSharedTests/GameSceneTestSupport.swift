//
//  GameSceneTestSupport.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 06/08/2026.
//

import CoreGraphics
import Foundation
@testable import RetroRacingShared

/// Keeps renderer-focused tests deterministic while production composition remains
/// responsible for explicitly injecting its gameplay engine.
@MainActor
extension GameScene {
    static func scene(
        size: CGSize,
        difficulty: GameDifficulty,
        theme: (any GameTheme)? = nil,
        imageLoader: some ImageLoader,
        soundPlayer: SoundEffectPlayer,
        laneCuePlayer: LaneCuePlayer? = nil,
        hapticController: HapticFeedbackController? = nil,
        audioFeedbackMode: AudioFeedbackMode = .defaultMode,
        laneMoveCueStyle: LaneMoveCueStyle = .defaultStyle,
        bigRivalCarsEnabled: Bool = false,
        roadVisualStyle: RoadVisualStyle = .defaultStyle
    ) -> GameScene {
        scene(
            size: size,
            difficulty: difficulty,
            gameEngine: makeDeterministicTestEngine(difficulty: difficulty),
            theme: theme,
            imageLoader: imageLoader,
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: hapticController,
            audioFeedbackMode: audioFeedbackMode,
            laneMoveCueStyle: laneMoveCueStyle,
            bigRivalCarsEnabled: bigRivalCarsEnabled,
            roadVisualStyle: roadVisualStyle
        )
    }
}

@MainActor
func makeDeterministicTestEngine(difficulty: GameDifficulty = .rapid) -> GameEngine {
    GameEngine(
        randomSource: DeterministicSceneRandomSource(),
        difficulty: difficulty
    )
}

@MainActor
func advanceTestScene(
    _ scene: GameScene,
    by duration: TimeInterval,
    frameDuration: TimeInterval = 1.0 / 60.0
) {
    var currentTime: TimeInterval = 0
    advanceTestScene(
        scene,
        currentTime: &currentTime,
        by: duration,
        frameDuration: frameDuration
    )
}

@MainActor
func advanceTestScene(
    _ scene: GameScene,
    currentTime: inout TimeInterval,
    by duration: TimeInterval,
    frameDuration: TimeInterval = 1.0 / 60.0
) {
    precondition(duration >= 0)
    precondition(frameDuration > 0)

    if currentTime == 0 {
        scene.update(currentTime)
    }
    let targetTime = currentTime + duration
    while currentTime < targetTime {
        currentTime = min(targetTime, currentTime + frameDuration)
        scene.update(currentTime)
    }
}

@MainActor
func applyTestGrid(
    _ gridState: GridState,
    to scene: GameScene,
    score: Int = 0,
    lives: Int = GameState.initialLives
) {
    scene.applyScreenshotLayout(
        GameScreenshotLayout(
            gridState: gridState,
            safetyMarkerRows: [],
            score: score,
            lives: lives,
            speedIncreaseImminent: false,
            upcomingMilestones: []
        )
    )
    scene.setOverlayPauseLock(false)
    scene.unpauseGameplay()
}

private final class DeterministicSceneRandomSource: RandomSource {
    func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return 0
    }
}

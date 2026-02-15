//
//  GameViewModel+Scene.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI
import SpriteKit

extension GameViewModel {
    /// Ensures the SpriteKit scene exists and stays in sync with the current layout.
    /// Scene creation is gated by `shouldStartGame` so that initial launch and
    /// post-Finish flows do not start gameplay while the menu overlay is visible.
    func setupSceneIfNeeded(side: CGFloat, volume: Double) {
        AppLog.info(AppLog.game, "setupSceneIfNeeded called - shouldStartGame: \(shouldStartGame), side: \(side), scene exists: \(scene != nil)")
        guard side > 0 else { return }

        if scene == nil {
            guard shouldStartGame else {
                AppLog.info(AppLog.game, "⏸️ Not creating scene yet because shouldStartGame is false")
                return
            }
            AppLog.info(AppLog.game, "✅ Creating new scene with side: \(side)")
            createSceneAndDelegate(side: side, volume: volume)
        } else if let gameScene = scene, delegate == nil {
            AppLog.info(AppLog.game, "✅ Attaching delegate to existing scene")
            attachDelegate(to: gameScene, volume: volume)
        } else if let gameScene = scene {
            AppLog.info(AppLog.game, "✅ Syncing score and lives from scene")
            syncScoreAndLives(from: gameScene)
        }
    }

    func updateSceneSizeIfNeeded(side: CGFloat) {
        guard side > 8, let gameScene = scene else { return }
        gameScene.resizeScene(to: CGSize(width: side, height: side))
    }

    private func createSceneAndDelegate(side: CGFloat, volume: Double) {
        let newScene = Self.makeScene(side: side, theme: theme, hapticController: hapticController, volume: volume)
        scene = newScene
        let newDelegate = makeGameSceneDelegate()
        delegate = newDelegate
        newScene.gameDelegate = newDelegate
        inputAdapter = inputAdapterFactory.makeAdapter(controller: newScene, hapticController: hapticController)
        pause.scenePaused = newScene.gameState.isPaused
        let (currentScore, currentLives) = Self.scoreAndLives(from: newScene)
        hud.score = currentScore
        hud.lives = currentLives

        // Record this session against the daily play limit, if enabled.
        playLimitService?.recordGamePlayed(on: Date())

        // Respect current overlay state: if the menu is on top, keep gameplay paused
        if isMenuOverlayPresented {
            AppLog.info(AppLog.game, "🔄 Created scene while menu overlay is presented – pausing gameplay")
            newScene.pauseGameplay()
        }
    }

    private func attachDelegate(to gameScene: GameScene, volume: Double) {
        let newDelegate = makeGameSceneDelegate()
        delegate = newDelegate
        gameScene.gameDelegate = newDelegate
        inputAdapter = inputAdapterFactory.makeAdapter(controller: gameScene, hapticController: hapticController)
        gameScene.setSoundVolume(volume)
        pause.scenePaused = gameScene.gameState.isPaused
        let (currentScore, currentLives) = Self.scoreAndLives(from: gameScene)
        hud.score = currentScore
        hud.lives = currentLives
        hud.speedIncreaseImminent = GameState.isLevelChangeImminent(score: currentScore, windowPoints: gameScene.speedAlertWindowPoints)
    }

    private func syncScoreAndLives(from gameScene: GameScene) {
        let (currentScore, currentLives) = Self.scoreAndLives(from: gameScene)
        hud.score = currentScore
        hud.lives = currentLives
        hud.speedIncreaseImminent = GameState.isLevelChangeImminent(score: currentScore, windowPoints: gameScene.speedAlertWindowPoints)
        pause.scenePaused = gameScene.gameState.isPaused
    }

    private func makeGameSceneDelegate() -> GameSceneDelegateImpl {
        GameSceneDelegateImpl(
            onScoreUpdate: { [weak self] in self?.hud.score = $0 },
            onLevelChangeImminent: { [weak self] in self?.hud.speedIncreaseImminent = $0 },
            onCollision: { [weak self] in self?.handleCollision() },
            onPauseStateChange: { [weak self] newPaused in
                guard let self else { return }
                self.pause.scenePaused = newPaused
                if !self.pause.isUserPaused { self.pause.isUserPaused = false }
            },
            hapticController: hapticController
        )
    }

    private static func makeScene(
        side: CGFloat,
        theme: (any GameTheme)?,
        hapticController: HapticFeedbackController?,
        volume: Double
    ) -> GameScene {
        let loader = PlatformFactories.makeImageLoader()
        let soundPlayer = PlatformFactories.makeSoundPlayer()
        soundPlayer.setVolume(volume)
        return GameScene.scene(
            size: CGSize(width: side, height: side),
            theme: theme,
            imageLoader: loader,
            soundPlayer: soundPlayer,
            hapticController: hapticController
        )
    }

    static func scoreAndLives(from scene: GameScene) -> (score: Int, lives: Int) {
        (scene.gameState.score, scene.gameState.lives)
    }
}

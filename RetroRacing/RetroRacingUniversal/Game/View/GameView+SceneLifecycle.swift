//
//  GameView+SceneLifecycle.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
import SpriteKit
import RetroRacingShared

/// Scene lifecycle helpers for creating and syncing the shared SpriteKit scene.
extension GameView {

    static func makeScene(side: CGFloat, theme: (any GameTheme)?, hapticController: HapticFeedbackController?, volume: Double) -> GameScene {
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

    /// Pure: returns current score and lives from a scene (no side effects).
    static func scoreAndLives(from scene: GameScene) -> (score: Int, lives: Int) {
        (scene.gameState.score, scene.gameState.lives)
    }

    @ViewBuilder
    func gameAreaContent(side: CGFloat) -> some View {
        if let scene = sceneBox.scene {
            SpriteView(scene: scene)
                .frame(width: side, height: side)
        } else {
            Color(red: 202/255, green: 220/255, blue: 159/255)
                .frame(width: side, height: side)
        }
    }

    #if os(macOS) || os(iOS)
    func setFocusForGameArea() {
        isGameAreaFocused = true
    }
    #else
    func setFocusForGameArea() {}
    #endif

    func setupSceneAndDelegateIfNeeded(side: CGFloat) {
        if sceneBox.scene == nil, side > 0 {
            createSceneAndDelegate(side: side)
        } else if let gameScene = sceneBox.scene, delegate == nil {
            attachDelegate(to: gameScene)
        } else if let gameScene = sceneBox.scene {
            syncScoreAndLivesFromScene(gameScene)
        }
    }

    func createSceneAndDelegate(side: CGFloat) {
        let newScene = Self.makeScene(side: side, theme: theme, hapticController: hapticController, volume: sfxVolume)
        sceneBox.scene = newScene
        let newDelegate = makeGameSceneDelegate()
        delegate = newDelegate
        newScene.gameDelegate = newDelegate
        inputAdapter = TouchGameInputAdapter(controller: newScene, hapticController: hapticController)
        scenePaused = newScene.gameState.isPaused
        let (currentScore, currentLives) = Self.scoreAndLives(from: newScene)
        score = currentScore
        lives = currentLives
    }

    func attachDelegate(to gameScene: GameScene) {
        let newDelegate = makeGameSceneDelegate()
        delegate = newDelegate
        gameScene.gameDelegate = newDelegate
        inputAdapter = TouchGameInputAdapter(controller: gameScene, hapticController: hapticController)
        gameScene.setSoundVolume(sfxVolume)
        scenePaused = gameScene.gameState.isPaused
        let (currentScore, currentLives) = Self.scoreAndLives(from: gameScene)
        score = currentScore
        lives = currentLives
    }

    func syncScoreAndLivesFromScene(_ gameScene: GameScene) {
        let (currentScore, currentLives) = Self.scoreAndLives(from: gameScene)
        score = currentScore
        lives = currentLives
        scenePaused = gameScene.gameState.isPaused
    }

    func updateSceneSizeIfNeeded(side: CGFloat) {
        guard side > 8, let gameScene = sceneBox.scene else { return }
        gameScene.resizeScene(to: CGSize(width: side, height: side))
    }

    func makeGameSceneDelegate() -> GameSceneDelegateImpl {
        GameSceneDelegateImpl(
            onScoreUpdate: { score = $0 },
            onCollision: handleCollision,
            onPauseStateChange: { newPaused in
                scenePaused = newPaused
                if !isUserPaused { isUserPaused = false } // ignore auto pauses for button state
            },
            hapticController: hapticController
        )
    }

    func handleCollision() {
        guard let scene = sceneBox.scene else { return }
        let (currentScore, currentLives) = Self.scoreAndLives(from: scene)
        lives = currentLives
        if currentLives == 0 {
            leaderboardService.submitScore(currentScore)
            ratingService.checkAndRequestRating(score: currentScore)
            gameOverScore = currentScore
            showGameOver = true
        } else {
            scene.resume()
        }
    }
}

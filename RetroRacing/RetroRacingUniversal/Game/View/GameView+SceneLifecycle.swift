//
//  GameView+SceneLifecycle.swift
//  RetroRacing
//

import SwiftUI
import SpriteKit
import RetroRacingShared

extension GameView {

    static func makeScene(side: CGFloat, theme: (any GameTheme)?) -> GameScene {
        #if os(macOS)
        let loader = AppKitImageLoader()
        #else
        let loader = UIKitImageLoader()
        #endif
        return GameScene.scene(size: CGSize(width: side, height: side), theme: theme, imageLoader: loader)
    }

    /// Pure: returns current score and lives from a scene (no side effects).
    static func scoreAndLives(from scene: GameScene) -> (score: Int, lives: Int) {
        (scene.gameState.score, scene.gameState.lives)
    }

    @ViewBuilder
    func gameAreaContent(side: CGFloat) -> some View {
        if let scene = scene {
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
        if scene == nil, side > 0 {
            createSceneAndDelegate(side: side)
        } else if let gameScene = scene, delegate == nil {
            attachDelegate(to: gameScene)
        } else if let gameScene = scene {
            syncScoreAndLivesFromScene(gameScene)
        }
    }

    func createSceneAndDelegate(side: CGFloat) {
        let newScene = Self.makeScene(side: side, theme: theme)
        scene = newScene
        let newDelegate = makeGameSceneDelegate()
        delegate = newDelegate
        newScene.gameDelegate = newDelegate
        let (currentScore, currentLives) = Self.scoreAndLives(from: newScene)
        score = currentScore
        lives = currentLives
    }

    func attachDelegate(to gameScene: GameScene) {
        let newDelegate = makeGameSceneDelegate()
        delegate = newDelegate
        gameScene.gameDelegate = newDelegate
        let (currentScore, currentLives) = Self.scoreAndLives(from: gameScene)
        score = currentScore
        lives = currentLives
    }

    func syncScoreAndLivesFromScene(_ gameScene: GameScene) {
        let (currentScore, currentLives) = Self.scoreAndLives(from: gameScene)
        score = currentScore
        lives = currentLives
    }

    func makeGameSceneDelegate() -> GameSceneDelegateImpl {
        GameSceneDelegateImpl(
            onScoreUpdate: { score = $0 },
            onCollision: handleCollision,
            hapticController: hapticController
        )
    }

    func handleCollision() {
        guard let scene = scene else { return }
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

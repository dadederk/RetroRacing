//
//  GameView+GameControl.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
import RetroRacingShared

// MARK: - Keyboard input (macOS / iOS)

#if os(macOS) || os(iOS)
/// Keyboard handling wrapper for the game area on macOS and iOS.
struct GameAreaKeyboardModifier: ViewModifier {
    let inputAdapter: GameInputAdapter?
    var onMoveLeft: (() -> Void)?
    var onMoveRight: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .onKeyPress(.leftArrow) {
                onMoveLeft?()
                inputAdapter?.handleLeft()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                onMoveRight?()
                inputAdapter?.handleRight()
                return .handled
            }
    }
}
#else
struct GameAreaKeyboardModifier: ViewModifier {
    let inputAdapter: GameInputAdapter?
    var onMoveLeft: (() -> Void)?
    var onMoveRight: (() -> Void)?

    func body(content: Content) -> some View {
        content
    }
}
#endif

// MARK: - Delegate implementation

/// Bridges GameScene callbacks to UI state updates and optional haptics.
final class GameSceneDelegateImpl: GameSceneDelegate {
    let onScoreUpdate: (Int) -> Void
    let onCollision: () -> Void
    let onPauseStateChange: (Bool) -> Void
    let hapticController: HapticFeedbackController?

    init(
        onScoreUpdate: @escaping (Int) -> Void,
        onCollision: @escaping () -> Void,
        onPauseStateChange: @escaping (Bool) -> Void = { _ in },
        hapticController: HapticFeedbackController? = nil
    ) {
        self.onScoreUpdate = onScoreUpdate
        self.onCollision = onCollision
        self.onPauseStateChange = onPauseStateChange
        self.hapticController = hapticController
    }

    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        onScoreUpdate(score)
    }

    func gameSceneDidDetectCollision(_ gameScene: GameScene) {
        onCollision()
    }

    func gameSceneDidUpdateGrid(_ gameScene: GameScene) {
        hapticController?.triggerGridUpdateHaptic()
    }

    func gameScene(_ gameScene: GameScene, didUpdatePauseState isPaused: Bool) {
        onPauseStateChange(isPaused)
    }

    func gameScene(_ gameScene: GameScene, didAchieveNewHighScore score: Int) {
        // Handled in view layer; no-op here to satisfy protocol.
    }
}

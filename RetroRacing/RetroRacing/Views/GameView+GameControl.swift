import SwiftUI
import RetroRacingShared

// MARK: - Keyboard input (macOS / iOS)

#if os(macOS) || os(iOS)
struct GameAreaKeyboardModifier: ViewModifier {
    let scene: GameScene?

    func body(content: Content) -> some View {
        content
            .onKeyPress(.leftArrow) {
                scene?.moveLeft()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                scene?.moveRight()
                return .handled
            }
    }
}
#else
struct GameAreaKeyboardModifier: ViewModifier {
    let scene: GameScene?

    func body(content: Content) -> some View {
        content
    }
}
#endif

// MARK: - Delegate implementation

final class GameSceneDelegateImpl: GameSceneDelegate {
    let onScoreUpdate: (Int) -> Void
    let onCollision: () -> Void

    init(onScoreUpdate: @escaping (Int) -> Void, onCollision: @escaping () -> Void) {
        self.onScoreUpdate = onScoreUpdate
        self.onCollision = onCollision
    }

    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        onScoreUpdate(score)
    }

    func gameSceneDidDetectCollision(_ gameScene: GameScene) {
        onCollision()
    }
}

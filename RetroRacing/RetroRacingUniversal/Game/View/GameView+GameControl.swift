import SwiftUI
import RetroRacingShared

// MARK: - Keyboard input (macOS / iOS)

#if os(macOS) || os(iOS)
struct GameAreaKeyboardModifier: ViewModifier {
    let scene: GameScene?
    var onMoveLeft: (() -> Void)?
    var onMoveRight: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .onKeyPress(.leftArrow) {
                onMoveLeft?()
                scene?.moveLeft()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                onMoveRight?()
                scene?.moveRight()
                return .handled
            }
    }
}
#else
struct GameAreaKeyboardModifier: ViewModifier {
    let scene: GameScene?
    var onMoveLeft: (() -> Void)?
    var onMoveRight: (() -> Void)?

    func body(content: Content) -> some View {
        content
    }
}
#endif

// MARK: - Delegate implementation

final class GameSceneDelegateImpl: GameSceneDelegate {
    let onScoreUpdate: (Int) -> Void
    let onCollision: () -> Void
    let hapticController: HapticFeedbackController?

    init(onScoreUpdate: @escaping (Int) -> Void, onCollision: @escaping () -> Void, hapticController: HapticFeedbackController? = nil) {
        self.onScoreUpdate = onScoreUpdate
        self.onCollision = onCollision
        self.hapticController = hapticController
    }

    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        onScoreUpdate(score)
    }

    func gameSceneDidDetectCollision(_ gameScene: GameScene) {
        hapticController?.triggerCrashHaptic()
        onCollision()
    }

    func gameSceneDidUpdateGrid(_ gameScene: GameScene) {
        hapticController?.triggerGridUpdateHaptic()
    }
}

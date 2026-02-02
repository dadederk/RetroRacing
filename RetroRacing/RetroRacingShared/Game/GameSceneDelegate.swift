import Foundation

public protocol GameSceneDelegate: AnyObject {
    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int)
    func gameSceneDidDetectCollision(_ gameScene: GameScene)
    /// Called once per timer-driven grid advance (new row), not on move left/right.
    func gameSceneDidUpdateGrid(_ gameScene: GameScene)
}

import Foundation

public protocol GameSceneDelegate: AnyObject {
    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int)
    func gameSceneDidDetectCollision(_ gameScene: GameScene)
}

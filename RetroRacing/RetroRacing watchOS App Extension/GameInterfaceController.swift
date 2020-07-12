import WatchKit
import Foundation
import GameKit

class GameInterfaceController: WKInterfaceController {
    @IBOutlet private var skInterface: WKInterfaceSKScene!
    
    private var allowRotation = true
    private var scene: GameScene!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        scene = GameScene(size: contentFrame.size)
        scene.gameDelegate = self

        skInterface.presentScene(scene)
        skInterface.preferredFramesPerSecond = 30
        
        crownSequencer.delegate = self
        
        setTitle(scoreString(forScore: 0))
    }
    
    override func willActivate() {
        super.willActivate()
        crownSequencer.focus()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    private func scoreString(forScore score: Int) -> String {
        return "\(NSLocalizedString("score", comment: "")): \(score)"
    }
    
    private func updateGameCenterScore(_ score: Int) {
        let scoreValue = Int64(score)
        let gameCenterScore = GKScore(leaderboardIdentifier: "bestwatchos001", player: GKLocalPlayer.local)
        gameCenterScore.value = scoreValue
        
        GKScore.report([gameCenterScore], withCompletionHandler: nil)
    }
}

extension GameInterfaceController: WKCrownDelegate {
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        //print("RotationDelta: \(rotationalDelta)")
        if allowRotation && abs(rotationalDelta) > 0.05  {
            if rotationalDelta > 0 {
                scene.moveRight()
            } else {
                scene.moveLeft()
            }
            
            allowRotation = false
        }
    }
    
    func crownDidBecomeIdle(_ crownSequencer: WKCrownSequencer?) {
        //print("Idle")
        allowRotation = true
    }
}

extension GameInterfaceController: GameSceneDelegate {
    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        setTitle(scoreString(forScore: score))
    }
    
    func gameSceneDidDetectCollision(_ gameScene: GameScene) {
        let title = NSLocalizedString("gameOver", comment: "")
        let score = gameScene.gameState.score
        let message = scoreString(forScore: score)

        let restartAction = WKAlertAction(title: NSLocalizedString("restart", comment: ""), style: .default, handler: { self.scene.start() })
        
        let finishAction = WKAlertAction(title: NSLocalizedString("finish", comment: ""), style: .default, handler: { [unowned self] in
            DispatchQueue.main.async { self.dismiss() }
        })

        presentAlert(withTitle: title, message: message, preferredStyle: .alert, actions: [restartAction, finishAction])
        
        updateGameCenterScore(score)
    }
}

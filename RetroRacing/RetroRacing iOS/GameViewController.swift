import UIKit
import SpriteKit
import GameKit

class GameViewController: UIViewController {
    @IBOutlet private weak var sceneView: SKView!
    @IBOutlet private weak var scoreLabel: UILabel!
    
    private lazy var scene: GameScene = { GameScene(size: sceneView.frame.size) }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene.gameDelegate = self
        
        // Present the scene
        sceneView.presentScene(scene)
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        let swipeLeftGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(recognizer:)))
        let swipeRightGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(recognizer:)))
        
        swipeLeftGestureRecognizer.direction = .left
        swipeRightGestureRecognizer.direction = .right
        
        view.addGestureRecognizer(tapGestureRecognizer)
        view.addGestureRecognizer(swipeLeftGestureRecognizer)
        view.addGestureRecognizer(swipeRightGestureRecognizer)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .landscape
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func pressesBegan(_ presses: Set<UIPress>,
                               with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        presses.first?.key.map(keyPressed)
    }
    
    @objc private func handleTap(recognizer: UITapGestureRecognizer) {
        let view = recognizer.view
        let location = recognizer.location(in: view)
        
        if location.x < (view?.frame.size.width)! / 2.0 {
            scene.left()
        } else {
            scene.right()
        }
    }
    
    @objc private func handleSwipeGesture(recognizer: UISwipeGestureRecognizer) {
        switch recognizer.direction {
        case .left: scene.left()
        case .right: scene.right()
        case .down, .up: break
        default: break
        }
    }
    
    private func scoreString(forScore score: Int) -> String {
        return "\(NSLocalizedString("score", comment: "")): \(score)"
    }
    
    private func updateGameCenterScore(_ score: Int) {
        let scoreValue = Int64(score)
        let gameCenterScore = GKScore(leaderboardIdentifier: "bestios001", player: GKLocalPlayer.local)
        gameCenterScore.value = scoreValue
        
        GKScore.report([gameCenterScore], withCompletionHandler: nil)
    }
    
    private func keyPressed(_ key: UIKey) {
        switch key.keyCode {
        case .keyboardLeftArrow: scene.left()
        case .keyboardRightArrow: scene.right()
        default: break
        }
    }
}

extension GameViewController: GameSceneDelegate {
    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        scoreLabel.text = scoreString(forScore: score)
    }
    
    func gameScene(_ gameScene: GameScene, didDetectCollisionWithScore score: Int) {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
        impactFeedbackGenerator.impactOccurred()
        
        let gameOverAlertController = UIAlertController(title: NSLocalizedString("gameOver", comment: ""),
                                                        message: scoreString(forScore: score),
                                                        preferredStyle: .alert)
        
        gameOverAlertController.addAction(UIAlertAction(title: NSLocalizedString("restart", comment: ""), style: .default, handler: { alertAction in
            self.scene.start()
        }))
        gameOverAlertController.addAction(UIAlertAction(title: NSLocalizedString("finish", comment: ""), style: .default, handler: { alertAction in
            self.dismiss(animated: true, completion: nil)
        }))
        
        present(gameOverAlertController, animated: true, completion: nil)
        
        updateGameCenterScore(score)
    }
}

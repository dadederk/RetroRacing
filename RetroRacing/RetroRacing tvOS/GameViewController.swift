import UIKit
import SpriteKit
import GameKit

class GameViewController: UIViewController {
    @IBOutlet private weak var sceneView: SKView!
    @IBOutlet private weak var scoreLabel: UILabel!
    
    private lazy var scene: GameScene = { GameScene(size: sceneView.frame.size) }()
    private let leaderboardService: LeaderboardService
    private let ratingService: RatingService
    
    init(leaderboardService: LeaderboardService = GameCenterService(configuration: tvOSLeaderboardConfiguration()),
         ratingService: RatingService = StoreReviewService()) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.leaderboardService = GameCenterService(configuration: tvOSLeaderboardConfiguration())
        self.ratingService = StoreReviewService()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scene.gameDelegate = self

        sceneView.presentScene(scene)
        sceneView.ignoresSiblingOrder = true
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        
        let leftSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(swipeGestureRecognizer:)))
        leftSwipeGestureRecognizer.direction = .left
        view.addGestureRecognizer(leftSwipeGestureRecognizer)
        
        let rightSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(swipeGestureRecognizer:)))
        rightSwipeGestureRecognizer.direction = .right
        view.addGestureRecognizer(rightSwipeGestureRecognizer)
    }
    
    @objc private func handleSwipe(swipeGestureRecognizer: UISwipeGestureRecognizer) {
        if swipeGestureRecognizer.direction == .left {
            scene.moveLeft()
        } else if swipeGestureRecognizer.direction == .right {
            scene.moveRight()
        }
    }
    
    private func scoreString(forScore score: Int) -> String {
        return "\(NSLocalizedString("score", comment: "")): \(score)"
    }
    
    private func updateGameCenterScore(_ score: Int) {
        leaderboardService.submitScore(score)
    }
}

extension GameViewController: GameSceneDelegate {
    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        scoreLabel.text = scoreString(forScore: score)
    }
    
    func gameSceneDidDetectCollision(_ gameScene: GameScene) {
        let score = gameScene.gameState.score
        
        updateGameCenterScore(score)
        ratingService.checkAndRequestRating(score: score)
        
        let gameOverAlertController = UIAlertController(title: NSLocalizedString("gameOver", comment: ""),
                                                        message: scoreString(forScore: score),
            preferredStyle: .alert)
        gameOverAlertController.addAction(UIAlertAction(title: NSLocalizedString("restart", comment: ""), style: .default, handler: { [weak self] alertAction in
            self?.scene.start()
        }))
        gameOverAlertController.addAction(UIAlertAction(title: NSLocalizedString("finish", comment: ""), style: .default, handler: { [weak self] alertAction in
            self?.dismiss(animated: true, completion: nil)
        }))
        
        present(gameOverAlertController, animated: true, completion: nil)
    }
}

//
//  GameViewController.swift
//  RetroRacing iOS
//
//  Created by Dani on 04/04/2025.
//

import UIKit
import SpriteKit
import GameKit

final class GameViewController: UIViewController {
    @IBOutlet private weak var scoreLabel: UILabel!
    @IBOutlet private weak var livesLabel: UILabel!
    @IBOutlet private weak var skView: SKView!
    @IBOutlet private weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    
    private lazy var scene: GameScene = { GameScene(size: skView.frame.size) }()
    private let leaderboardService: LeaderboardService
    private let ratingService: RatingService
    
    init(leaderboardService: LeaderboardService = GameCenterService(configuration: iOSLeaderboardConfiguration()),
         ratingService: RatingService = StoreReviewService()) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.leaderboardService = GameCenterService(configuration: iOSLeaderboardConfiguration())
        self.ratingService = StoreReviewService()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene.gameDelegate = self
        skView.translatesAutoresizingMaskIntoConstraints = false
        skView.presentScene(scene)
        
#if DEBUG
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
#endif
        
        configureGestures()
        
        livesLabel.text = livesString(withNumberOfLives: scene.gameState.lives)
        
        if let font = UIFont(name: "PressStart2P-Regular", size: 22.0) {
            scoreLabel.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: font)
            livesLabel.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: font)
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Gesture configuration
    
    private func configureGestures() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        let swipeLeftGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(recognizer:)))
        let swipeRightGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(recognizer:)))
        
        swipeLeftGestureRecognizer.direction = .left
        swipeRightGestureRecognizer.direction = .right
        
        view.addGestureRecognizer(swipeLeftGestureRecognizer)
        view.addGestureRecognizer(swipeRightGestureRecognizer)
    }
    
    // MARK: - Input Handlers
    
    @objc
    private func handleTap(recognizer: UITapGestureRecognizer) {
        guard let view = recognizer.view else { return }
        let location = recognizer.location(in: view)
        
        if location.x < view.frame.size.width / 2.0 {
            scene.moveLeft()
        } else {
            scene.moveRight()
        }
    }
    
    @objc private func handleSwipeGesture(recognizer: UISwipeGestureRecognizer) {
        switch recognizer.direction {
        case .left: scene.moveLeft()
        case .right: scene.moveRight()
        case .down, .up: break
        default: break
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>,
                               with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        presses.first?.key.map(keyPressed)
    }
    
    private func keyPressed(_ key: UIKey) {
        switch key.keyCode {
        case .keyboardLeftArrow: scene.moveLeft()
        case .keyboardRightArrow: scene.moveRight()
        default: break
        }
    }
    
    // MARK: - Label Helpers
    
    private func scoreString(forScore score: Int) -> String {
        return "\(NSLocalizedString("score", comment: "")):\(score)"
    }
    
    private func livesString(withNumberOfLives numberOfLives: Int) -> String {
        return "x\(numberOfLives)"
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
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
        
        impactFeedbackGenerator.impactOccurred()
        
        livesLabel.text = livesString(withNumberOfLives: scene.gameState.lives)
        
        if gameScene.gameState.lives == 0 {
            updateGameCenterScore(score)
            ratingService.checkAndRequestRating(score: score)
            presentGameFinishedAlert(forScore: score)
        } else {
            self.scene.resume()
        }
    }
    
    private func presentGameFinishedAlert(forScore score: Int) {
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
    }
}

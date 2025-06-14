//
//  GameViewController.swift
//  RetroRacing iOS
//
//  Created by Dani on 04/04/2025.
//

import UIKit
import SpriteKit
import GameplayKit
import GameKit

final class GameViewController: UIViewController {
    @IBOutlet private weak var scoreLabel: UILabel!
    @IBOutlet private weak var lifesLabel: UILabel!
    @IBOutlet private weak var skView: SKView!
    @IBOutlet private weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    
    private lazy var scene: GameScene = { GameScene(size: skView.frame.size) }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene.gameDelegate = self
        skView.translatesAutoresizingMaskIntoConstraints = false
        skView.presentScene(scene)
//        updateLayout()
        
#if DEBUG
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
#endif
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        let swipeLeftGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(recognizer:)))
        let swipeRightGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(recognizer:)))
        
        swipeLeftGestureRecognizer.direction = .left
        swipeRightGestureRecognizer.direction = .right
        
        view.addGestureRecognizer(tapGestureRecognizer)
        view.addGestureRecognizer(swipeLeftGestureRecognizer)
        view.addGestureRecognizer(swipeRightGestureRecognizer)
        
        lifesLabel.text = lifesString(withNumberOfLifes: scene.gameState.lives)
        
        if let font = UIFont(name: "PressStart2P-Regular", size: 22.0) {
            scoreLabel.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: font)
            lifesLabel.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: font)
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
    
    override func pressesBegan(_ presses: Set<UIPress>,
                               with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        presses.first?.key.map(keyPressed)
    }
    
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }
//        updateLayout()
//    }
//    
//    private func updateLayout() {
//        if traitCollection.horizontalSizeClass == .compact {
//            bottomConstraint.priority = .defaultLow
//            leadingConstraint.priority = .required
//        } else {
//            bottomConstraint.priority = .required
//            leadingConstraint.priority = .defaultLow
//        }
//    }
    
    @objc
    private func handleTap(recognizer: UITapGestureRecognizer) {
        let view = recognizer.view
        let location = recognizer.location(in: view)
        
        if location.x < (view?.frame.size.width)! / 2.0 {
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
    
    private func scoreString(forScore score: Int) -> String {
        return "\(NSLocalizedString("score", comment: "")):\(score)"
    }
    
    private func lifesString(withNumberOfLifes numberOfLifes: Int) -> String {
        return "x\(numberOfLifes)"
    }
    
    private func updateGameCenterScore(_ score: Int) {
//        let scoreValue = Int64(score)
//        let gameCenterScore = GKScore(leaderboardIdentifier: "bestios001test", player: GKLocalPlayer.local)
//        gameCenterScore.value = scoreValue
//        
//        GKScore.report([gameCenterScore], withCompletionHandler: nil)
    }
    
    private func keyPressed(_ key: UIKey) {
        switch key.keyCode {
        case .keyboardLeftArrow: scene.moveLeft()
        case .keyboardRightArrow: scene.moveRight()
        default: break
        }
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
        
        lifesLabel.text = lifesString(withNumberOfLifes: scene.gameState.lives)
        
        if gameScene.gameState.lives == 0 {
            presentGameFinishedAlert(forScore: score)
            updateGameCenterScore(score)
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

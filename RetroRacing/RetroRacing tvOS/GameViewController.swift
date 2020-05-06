//
//  GameViewController.swift
//  RetroRacing tvOS
//
//  Created by Daniel Devesa Derksen-Staats on 19/04/2020.
//  Copyright © 2020 Desfici Ltd. All rights reserved.
//

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
            scene.left()
        } else if swipeGestureRecognizer.direction == .right {
            scene.right()
        }
    }
    
    private func scoreString(forScore score: Int) -> String {
        return "\(NSLocalizedString("score", comment: "")): \(score)"
    }
    
    private func updateGameCenterScore(_ score: Int) {
        let scoreValue = Int64(score)
        let gameCenterScore = GKScore(leaderboardIdentifier: "besttvos001", player: GKLocalPlayer.local)
        gameCenterScore.value = scoreValue
        
        GKScore.report([gameCenterScore], withCompletionHandler: nil)
    }
}

extension GameViewController: GameSceneDelegate {
    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        scoreLabel.text = scoreString(forScore: score)
    }
    
    func gameScene(_ gameScene: GameScene, didDetectCollisionWithScore score: Int) {
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
        
        updateGameCenterScore(score)
    }
}

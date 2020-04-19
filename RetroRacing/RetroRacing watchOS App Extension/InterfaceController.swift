//
//  GameInterfaceController.swift
//  RetroRacing watchOS App Extension
//
//  Created by Daniel Devesa Derksen-Staats on 19/04/2020.
//  Copyright © 2020 Desfici Ltd. All rights reserved.
//

import WatchKit
import Foundation


class GameInterfaceController: WKInterfaceController {
    @IBOutlet var skInterface: WKInterfaceSKScene!
    
    private var allowRotation = true
    private var scene: GameScene!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        scene = GameScene(size: contentFrame.size)
        scene.gameDelegate = self

        skInterface.presentScene(scene)
        skInterface.preferredFramesPerSecond = 30
        
        crownSequencer.delegate = self
        
        setTitle("Score: 0")
    }
    
    override func willActivate() {
        super.willActivate()
        crownSequencer.focus()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
}

extension GameInterfaceController: WKCrownDelegate {
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        //print("RotationDelta: \(rotationalDelta)")
        if allowRotation && abs(rotationalDelta) > 0.05  {
            if rotationalDelta > 0 {
                scene.right()
            } else {
                scene.left()
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
        setTitle("Score: \(score)")
    }
    
    func gameSceneDidDetectCollision(_ gameScene: GameScene) {
        
        let title = "Game Over"
        let message = "Your score: \(gameScene.gameState.score)"

        
        let restartAction = WKAlertAction(title: "Restart", style: .default, handler: {
            self.scene.start()
        })
        
        let finishAction = WKAlertAction(title: "Finish", style: .default, handler: {
            self.dismiss()
        })

        presentAlert(withTitle: title, message: message, preferredStyle: .alert, actions: [restartAction, finishAction])
    }
}

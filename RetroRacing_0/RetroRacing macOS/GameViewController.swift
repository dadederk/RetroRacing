//
//  GameViewController.swift
//  RetroRacing macOS
//
//  Created by Dani on 04/04/2025.
//

import Cocoa
import SpriteKit
import GameplayKit

class GameViewController: NSViewController {
    @IBOutlet weak var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = GameScene.newGameScene()
        
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        
        skView.showsFPS = true

        skView.showsNodeCount = true
    }

}


import Cocoa
import SpriteKit
import GameplayKit

class GameViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = GameScene()
        
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

}


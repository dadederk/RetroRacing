import UIKit
import GameKit

final class MenuViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    
    private let gameCenterController = GKGameCenterViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        authenticateUserInGameCenter()
    }
    
    private func setupUI() {        
        playButton.titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel.text = NSLocalizedString("gameName", comment: "")
    }
    
    private func authenticateUserInGameCenter() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            guard error != nil else { return }
            guard let viewController = viewController else { return }
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction private func leaderboardButtonPressed(_ sender: Any) {
        gameCenterController.gameCenterDelegate = self
        present(gameCenterController, animated: true, completion: nil)
    }
}

extension MenuViewController: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        dismiss(animated: true, completion: nil)
    }
}

import UIKit

final class MenuViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    
    private let gameCenterService: GameCenterService
    
    init(gameCenterService: GameCenterService = GameCenterService(configuration: tvOSLeaderboardConfiguration())) {
        self.gameCenterService = gameCenterService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.gameCenterService = GameCenterService(configuration: tvOSLeaderboardConfiguration())
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        gameCenterService.authenticate(presentingViewController: self)
    }
    
    private func configureUI() {        
        playButton.titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel.text = NSLocalizedString("gameName", comment: "")
    }
    
    @IBAction private func leaderboardButtonPressed(_ sender: Any) {
        gameCenterService.createLeaderboardViewController(delegate: self)?.present(from: self)
    }
}

extension MenuViewController: AuthenticationViewController {
    func presentAuthenticationUI(_ viewController: UIViewController) {
        present(viewController, animated: true)
    }
}

extension MenuViewController: LeaderboardViewControllerDelegate {
    func leaderboardViewControllerDidFinish() {
        // Optional: Add any cleanup or analytics here
    }
}

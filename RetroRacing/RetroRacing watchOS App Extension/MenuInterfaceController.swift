import WatchKit
import GameKit

class MenuInterfaceController: WKInterfaceController {
    @IBOutlet private weak var titleLabel: WKInterfaceLabel!
    @IBOutlet private weak var playButton: WKInterfaceButton!
    
    override func didAppear() {
        super.didAppear()
        setupUI()
        authenticateUserInGameCenter()
    }
    
    private func setupUI() {
        titleLabel.setText(NSLocalizedString("gameName", comment: ""))
    }
    
    private func authenticateUserInGameCenter() {
        GKLocalPlayer.local.authenticateHandler = { _ in }
    }
}

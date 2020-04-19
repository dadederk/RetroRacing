//
//  MenuViewController.swift
//  RetroRacing
//
//  Created by Daniel Devesa Derksen-Staats on 19/04/2020.
//  Copyright © 2020 Desfici Ltd. All rights reserved.
//

import UIKit
import GameKit
import StoreKit

class MenuViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var leaderboardButton: UIButton!
    @IBOutlet private weak var rateAppButton: UIButton!
    
    private let gameCenterController = GKGameCenterViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        authenticateUserInGameCenter()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        playButton.titleLabel?.adjustsFontForContentSizeCategory = true
        leaderboardButton.titleLabel?.adjustsFontForContentSizeCategory = true
        rateAppButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
        titleLabel.text = NSLocalizedString("gameName", comment: "")
    }
    
    private func authenticateUserInGameCenter() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            guard error != nil else { return }
            guard let viewController = viewController else { return }
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    @IBAction private func rateAppButtonPressed(_ sender: Any) {
        SKStoreReviewController.requestReview()
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

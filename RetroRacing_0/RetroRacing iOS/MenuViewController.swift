//
//  MenuViewController.swift
//  RetroRacing
//
//  Created by Dani on 06/04/2025.
//

import UIKit

final class MenuViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var leaderboardButton: UIButton!
    @IBOutlet private weak var rateAppButton: UIButton!
    
    private let gameCenterService: GameCenterService
    private let ratingService: RatingService
    
    init(gameCenterService: GameCenterService = GameCenterService(configuration: iOSLeaderboardConfiguration()),
         ratingService: RatingService = StoreReviewService()) {
        self.gameCenterService = gameCenterService
        self.ratingService = ratingService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.gameCenterService = GameCenterService(configuration: iOSLeaderboardConfiguration())
        self.ratingService = StoreReviewService()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        gameCenterService.authenticate(presentingViewController: self)
    }
    
    private func configureUI() {
        view.backgroundColor = .systemBackground
        
        titleLabel.adjustsFontForContentSizeCategory = true
        playButton.titleLabel?.adjustsFontForContentSizeCategory = true
        leaderboardButton.titleLabel?.adjustsFontForContentSizeCategory = true
        rateAppButton.titleLabel?.adjustsFontForContentSizeCategory = true
        
        titleLabel.text = String(localized: "gameName")
        playButton.setTitle(String(localized: "play"), for: .normal)
        leaderboardButton.setTitle(String(localized: "leaderboard"), for: .normal)
        rateAppButton.setTitle(String(localized: "rateApp"), for: .normal)
        
        if let font = UIFont(name: "PressStart2P-Regular", size: 27.0) {
            titleLabel.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: font)
        }
    }
    
    @IBAction private func leaderboardButtonPressed(_ sender: Any) {
        guard gameCenterService.isAuthenticated() else {
            showSignInAlert()
            return
        }
        
        gameCenterService.createLeaderboardViewController(delegate: self)?.present(from: self)
    }
    
    @IBAction private func rateAppButtonPressed(_ sender: Any) {
        ratingService.requestRating()
    }
    
    private func showSignInAlert() {
        let alert = UIAlertController(
            title: String(localized: "leaderboard"),
            message: String(localized: "Sign in to Game Center to view the leaderboard."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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


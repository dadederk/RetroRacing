//
//  GameCenterPresenter.swift
//  RetroRacing
//
//  Created by Dani on 30/01/2026.
//

import GameKit

#if os(iOS) || os(tvOS)
import UIKit

/// Protocol for presenting Game Center UI
protocol GameCenterPresenter {
    func createLeaderboardViewController(
        leaderboardID: String,
        delegate: LeaderboardViewControllerDelegate
    ) -> LeaderboardViewController?
}

/// Modern iOS 14+ Game Center presenter using the updated initializer
final class ModernGameCenterPresenter: GameCenterPresenter {
    func createLeaderboardViewController(
        leaderboardID: String,
        delegate: LeaderboardViewControllerDelegate
    ) -> LeaderboardViewController? {
        guard GKLocalPlayer.local.isAuthenticated else { return nil }
        
        let viewController = GKGameCenterViewController(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        
        return LeaderboardViewController(
            gameCenterViewController: viewController,
            delegate: delegate
        )
    }
}

/// Wrapper for GKGameCenterViewController
final class LeaderboardViewController: NSObject {
    private let gameCenterViewController: GKGameCenterViewController
    private weak var delegate: LeaderboardViewControllerDelegate?
    
    init(gameCenterViewController: GKGameCenterViewController, delegate: LeaderboardViewControllerDelegate) {
        self.gameCenterViewController = gameCenterViewController
        self.delegate = delegate
        super.init()
        gameCenterViewController.gameCenterDelegate = self
    }
    
    func present(from viewController: UIViewController) {
        viewController.present(gameCenterViewController, animated: true)
    }
}

extension LeaderboardViewController: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
        delegate?.leaderboardViewControllerDidFinish()
    }
}

protocol LeaderboardViewControllerDelegate: AnyObject {
    func leaderboardViewControllerDidFinish()
}
#endif

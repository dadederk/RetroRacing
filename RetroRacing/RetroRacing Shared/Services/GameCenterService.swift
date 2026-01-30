//
//  GameCenterService.swift
//  RetroRacing
//
//  Created by Dani on 30/01/2026.
//

import GameKit

final class GameCenterService: LeaderboardService {
    private let configuration: LeaderboardConfiguration
    private let presenter: GameCenterPresenter
    
    init(configuration: LeaderboardConfiguration, presenter: GameCenterPresenter = ModernGameCenterPresenter()) {
        self.configuration = configuration
        self.presenter = presenter
    }
    
    func authenticate(presentingViewController: AuthenticationViewController) {
        GKLocalPlayer.local.authenticateHandler = { [weak presentingViewController] viewController, _ in
            guard let viewController = viewController else { return }
            presentingViewController?.presentAuthenticationUI(viewController)
        }
    }
    
    func submitScore(_ score: Int) {
        guard isAuthenticated() else { return }
        
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [configuration.leaderboardID]
        ) { error in
            if let error = error {
                print("Failed to submit score: \(error.localizedDescription)")
            }
        }
    }
    
    func isAuthenticated() -> Bool {
        GKLocalPlayer.local.isAuthenticated
    }
    
    #if os(iOS) || os(tvOS)
    func createLeaderboardViewController(delegate: LeaderboardViewControllerDelegate) -> LeaderboardViewController? {
        presenter.createLeaderboardViewController(
            leaderboardID: configuration.leaderboardID,
            delegate: delegate
        )
    }
    #endif
}

// MARK: - Protocols

protocol AuthenticationViewController: AnyObject {
    func presentAuthenticationUI(_ viewController: ViewControllerType)
}

// MARK: - Platform Types

#if os(iOS) || os(tvOS)
import UIKit
typealias ViewControllerType = UIViewController
#elseif os(macOS)
import AppKit
typealias ViewControllerType = NSViewController
#endif

//
//  PlayStartEligibilityPolicy.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

public enum PlayStartEligibilityDecision: Equatable {
    case startGame
    case showLimitPaywall
}

/// Pure play-start gating shared by menu Play and game-over Restart.
public enum PlayStartEligibilityPolicy {
    public static func decision(
        hasUnlimitedAccessForGating: Bool,
        isSpecialEventActive: Bool,
        playLimitServiceExists: Bool,
        canStartNewGame: Bool
    ) -> PlayStartEligibilityDecision {
        if hasUnlimitedAccessForGating || isSpecialEventActive {
            return .startGame
        }

        if playLimitServiceExists && canStartNewGame == false {
            return .showLimitPaywall
        }

        return .startGame
    }
}

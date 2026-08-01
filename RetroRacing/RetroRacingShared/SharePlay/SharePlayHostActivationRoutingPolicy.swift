//
//  SharePlayHostActivationRoutingPolicy.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 31/07/2026.
//

import Foundation

public enum SharePlayHostActivationRoute: Sendable, Equatable {
    case directActivation
    case sharingController
}

/// Selects the system-supported SharePlay start path for the current conversation state.
public enum SharePlayHostActivationRoutingPolicy {
    public static func route(
        isEligibleForGroupSession: Bool
    ) -> SharePlayHostActivationRoute {
        isEligibleForGroupSession ? .directActivation : .sharingController
    }

    public static func shouldRecoverControllerHandoff(
        isEligibleForGroupSession: Bool,
        isActivationRequestCurrent: Bool,
        hasAttemptedRecovery: Bool
    ) -> Bool {
        isEligibleForGroupSession
            && isActivationRequestCurrent
            && hasAttemptedRecovery == false
    }
}

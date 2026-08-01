//
//  SharePlayParticipantCountPolicy.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/08/2026.
//

import Foundation

@frozen public nonisolated enum SharePlayParticipantCountDisposition: Sendable, Equatable {
    case waitingBeforeReady
    case exactlyTwoReady
    case exactlyTwoAlreadyReady
    case unsupportedMoreThanTwo
    case lossAfterReady
    case ignoredIntentionalTeardown

    public var ignoredLossReason: String? {
        switch self {
        case .waitingBeforeReady:
            "before_ready"
        case .ignoredIntentionalTeardown:
            "intentional_teardown"
        case .exactlyTwoReady,
             .exactlyTwoAlreadyReady,
             .unsupportedMoreThanTwo,
             .lossAfterReady:
            nil
        }
    }
}

public nonisolated enum SharePlayParticipantCountPolicy {
    public static func disposition(
        participantCount: Int,
        hasObservedTwoParticipants: Bool,
        isIntentionalTeardown: Bool
    ) -> SharePlayParticipantCountDisposition {
        if participantCount == 2 {
            return hasObservedTwoParticipants ? .exactlyTwoAlreadyReady : .exactlyTwoReady
        }
        if participantCount > 2 {
            return .unsupportedMoreThanTwo
        }
        if hasObservedTwoParticipants {
            return isIntentionalTeardown ? .ignoredIntentionalTeardown : .lossAfterReady
        }
        return .waitingBeforeReady
    }
}

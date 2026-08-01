//
//  SharePlaySessionAdmissionPolicy.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 30/07/2026.
//

import Foundation

public enum SharePlaySessionInvalidationDisposition: Sendable, Equatable {
    case discard
    case abort
}

/// Keeps provisional GroupActivities sessions out of app navigation until `GroupSession.join()`
/// has completed. The system may deliver a waiting session that invalidates during handoff setup;
/// that transport artifact is not a user-visible match or disconnect.
public enum SharePlaySessionAdmissionPolicy {
    public static func shouldPublish(
        state: SharePlayMatchState,
        isSessionJoined: Bool
    ) -> Bool {
        state == .idle || isSessionJoined
    }

    public static func invalidationDisposition(
        isSessionJoined: Bool
    ) -> SharePlaySessionInvalidationDisposition {
        isSessionJoined ? .abort : .discard
    }
}

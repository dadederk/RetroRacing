//
//  RetroRacingGroupActivity.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 22/07/2026.
//

#if canImport(GroupActivities) && os(iOS)
import GroupActivities
import Foundation
import RetroRacingShared

/// SharePlay activity advertising the RetroRapid! competitive mode. Carries no gameplay state
/// itself — all round state travels separately over `GroupSessionMessenger` as
/// `SharePlayMatchCommand` values once the resulting `GroupSession` is configured.
public nonisolated struct RetroRacingGroupActivity: GroupActivity, Sendable {
    public static var activityIdentifier: String {
        "com.accessibilityUpTo11.RetroRacing.shareplay.competitive"
    }

    public init() {}

    public var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = GameLocalizedStrings.string("shareplay_activity_title")
        metadata.type = .generic
        return metadata
    }
}
#endif

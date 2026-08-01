//
//  RetroRacingGroupActivity.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 22/07/2026.
//

#if canImport(GroupActivities) && os(iOS)
import CoreTransferable
import Foundation
import GroupActivities
import RetroRacingShared

/// SharePlay activity advertising the RetroRapid! competitive mode. Carries no gameplay state
/// itself — all round state travels separately over `GroupSessionMessenger` as
/// `SharePlayMatchCommand` values once the resulting `GroupSession` is configured.
public nonisolated struct RetroRacingGroupActivity: GroupActivity, Transferable, Sendable {
    private static let fallbackURL = URL(string: "https://accessibilityupto11.com/apps/retrorapid/open")

    public static var activityIdentifier: String {
        "com.accessibilityUpTo11.RetroRacing.shareplay.competitive"
    }

    public init() {}

    public var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = GameLocalizedStrings.string("shareplay_activity_title")
        metadata.subtitle = GameLocalizedStrings.string("menu_play_with_friends_free_footer")
        metadata.type = .generic
        metadata.fallbackURL = Self.fallbackURL
        return metadata
    }
}
#endif

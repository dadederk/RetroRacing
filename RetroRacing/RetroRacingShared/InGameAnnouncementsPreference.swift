//
//  InGameAnnouncementsPreference.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-16.
//

import Foundation

/// Storage keys for user-controlled in-game VoiceOver announcements.
public enum InGameAnnouncementsPreference {
    public static let storageKey = "inGameAnnouncementsEnabled"
    public static let defaultEnabled = true
}

/// User preference for VoiceOver announcements when overtaking Game Center friends.
public enum FriendOvertakeVoiceOverAnnouncementPreference {
    public static let storageKey = "friendOvertakeVoiceOverAnnouncementsEnabled"
    public static let defaultEnabled = false

    public static func currentSelection(from userDefaults: UserDefaults) -> Bool {
        guard userDefaults.object(forKey: storageKey) != nil else {
            return defaultEnabled
        }
        return userDefaults.bool(forKey: storageKey)
    }
}

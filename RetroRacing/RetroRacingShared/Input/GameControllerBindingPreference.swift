//
//  GameControllerBindingPreference.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-03-02.
//

import Foundation

/// Persistence helpers for the global game controller binding profile.
///
/// A single profile applies to all connected controllers. There is no per-device
/// mapping in v1.
public enum GameControllerBindingPreference {
    public static let storageKey = "gameControllerBindingProfile"

    /// Reads the current binding profile from storage, returning defaults if not stored.
    public static func currentProfile(from userDefaults: UserDefaults) -> GameControllerBindingProfile {
        guard
            let data = userDefaults.data(forKey: storageKey),
            let profile = try? JSONDecoder().decode(GameControllerBindingProfile.self, from: data)
        else {
            return .default
        }
        return profile
    }

    /// Persists a binding profile to storage.
    public static func setProfile(_ profile: GameControllerBindingProfile, in userDefaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}

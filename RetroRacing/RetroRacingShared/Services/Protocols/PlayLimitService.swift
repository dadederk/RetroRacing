//
//  PlayLimitService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 10/02/2026.
//

import Foundation

/// Abstraction for tracking how many games a user can play per day
/// under the freemium model.
///
/// Implementations must be thread-safe.
public protocol PlayLimitService {
    /// Returns `true` when the user has purchased unlimited access.
    var hasUnlimitedAccess: Bool { get }

    /// Returns `true` when the user is allowed to start a new game
    /// at the given date.
    func canStartNewGame(on date: Date) -> Bool

    /// Records that a game has been played at the given date.
    /// Implementations should ignore calls when `hasUnlimitedAccess` is `true`.
    func recordGamePlayed(on date: Date)

    /// Returns the remaining number of games the user can play today.
    /// Implementations should return `Int.max` when `hasUnlimitedAccess` is `true`.
    func remainingPlays(on date: Date) -> Int

    /// Returns the next date at which the daily counter will reset.
    func nextResetDate(after date: Date) -> Date

    /// Marks the user as having unlimited access.
    /// Implementations should update any persisted state accordingly.
    func unlockUnlimitedAccess()
}


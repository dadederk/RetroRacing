//
//  SpecialEventService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 09/04/2026.
//

import Foundation

/// Metadata describing a special in-app event that grants temporary unlimited play.
public struct SpecialEventInfo {
    /// Localised display name shown to the user (e.g. "Miami Grand Prix").
    public let name: String
    /// Inclusive start of the event window — midnight of the first event day (UTC).
    public let startDate: Date
    /// The last day of the event at midnight UTC, used only for display (e.g. "3 May").
    /// The active window ends at midnight of the day *after* this date.
    public let inclusiveEndDate: Date

    public init(name: String, startDate: Date, inclusiveEndDate: Date) {
        self.name = name
        self.startDate = startDate
        self.inclusiveEndDate = inclusiveEndDate
    }
}

/// Abstraction for time-limited in-app events that temporarily grant unlimited play
/// to all users, regardless of purchase status.
///
/// The play-gating chain in MenuView and GameView is:
///   1. `StoreKitService.hasPremiumAccess` — permanent purchase
///   2. `SpecialEventService.isEventActive(on:)` — temporary event bypass
///   3. `PlayLimitService.canStartNewGame(on:)` — daily limit check
///
/// Keeping the event check separate from premium ensures that changes to event
/// logic can never accidentally affect the premium entitlement.
public protocol SpecialEventService {
    /// Returns `true` when a special event is active at the given date.
    func isEventActive(on date: Date) -> Bool

    /// Returns display metadata for the active event on the given date, or `nil`
    /// when no event is active.
    func eventInfo(on date: Date) -> SpecialEventInfo?
}

//
//  DateRangeSpecialEventService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 09/04/2026.
//

import Foundation

/// A `SpecialEventService` implementation driven by a fixed UTC date range.
///
/// The event is considered active during `[startDate, exclusiveEndDate)` where
/// `exclusiveEndDate` is the calendar day immediately after `inclusiveEndDate`.
///
/// Prefer the static factory properties for well-known events:
/// ```swift
/// let service: SpecialEventService = DateRangeSpecialEventService.miamiGrandPrix2026
/// ```
public struct DateRangeSpecialEventService: SpecialEventService {
    private let info: SpecialEventInfo
    /// One calendar day after `inclusiveEndDate` (the exclusive upper bound of the window).
    private let exclusiveEndDate: Date

    /// - Parameters:
    ///   - name: Localised display name for the event.
    ///   - startDate: Midnight UTC on the first event day.
    ///   - inclusiveEndDate: Midnight UTC on the last event day; the active window
    ///     ends at midnight the following day.
    public init(name: String, startDate: Date, inclusiveEndDate: Date) {
        info = SpecialEventInfo(name: name, startDate: startDate, inclusiveEndDate: inclusiveEndDate)
        // Adding a day to a valid Date with a well-formed Calendar cannot fail; fall back to
        // inclusiveEndDate so the window is zero-length (event immediately inactive) rather than crashing.
        exclusiveEndDate = Calendar.utc.date(byAdding: .day, value: 1, to: inclusiveEndDate) ?? inclusiveEndDate
    }

    public func isEventActive(on date: Date) -> Bool {
        date >= info.startDate && date < exclusiveEndDate
    }

    public func eventInfo(on date: Date) -> SpecialEventInfo? {
        isEventActive(on: date) ? info : nil
    }
}

// MARK: - Miami Grand Prix 2026

public extension DateRangeSpecialEventService {
    /// Pre-built service for the Miami Grand Prix 2026 weekend (May 1–3 UTC).
    ///
    /// Using UTC epoch timestamps avoids `Optional` calendar arithmetic for well-known dates.
    /// `static let` stores the value once (lazy, thread-safe) — appropriate for immutable config.
    static let miamiGrandPrix2026 = DateRangeSpecialEventService(
        name: "Miami Grand Prix",
        startDate: Date(timeIntervalSince1970: 1_746_057_600),   // 2026-05-01 00:00 UTC
        inclusiveEndDate: Date(timeIntervalSince1970: 1_746_230_400) // 2026-05-03 00:00 UTC
    )
}

// MARK: - Calendar helpers

private extension Calendar {
    /// A Gregorian calendar fixed to UTC, used for deterministic event-boundary comparisons.
    static let utc: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .gmt   // TimeZone.gmt: iOS 16+, project targets iOS 26+
        return cal
    }()
}

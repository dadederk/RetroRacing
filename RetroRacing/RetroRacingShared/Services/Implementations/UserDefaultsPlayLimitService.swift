//
//  UserDefaultsPlayLimitService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 10/02/2026.
//

import Foundation

/// UserDefaults-backed implementation of `PlayLimitService`.
/// Thread-safety is provided by the implicit `@MainActor` isolation
/// from the project's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` build setting.
/// Counts reset at local midnight via a calendar-based day boundary.
public final class UserDefaultsPlayLimitService: PlayLimitService {
    private enum Keys {
        static let lastPlayDate = "PlayLimit.lastPlayDate"
        static let todayCount = "PlayLimit.todayCount"
        static let hasUnlimitedAccess = "PlayLimit.hasUnlimitedAccess"
        static let debugForceFreemium = StoreKitService.DebugStorageKeys.forceFreemiumPlayLimit
        static let firstPlayDate = "PlayLimit.firstPlayDate"
    }

    private let userDefaults: UserDefaults
    private let calendar: Calendar
    private let maxPlaysPerDay: Int
    private let firstDayMaxPlays: Int

    /// - Parameters:
    ///   - userDefaults: Backing store. Prefer `InfrastructureDefaults.userDefaults`.
    ///   - calendar: Calendar used to determine day boundaries. Defaults to `.current`.
    ///   - maxPlaysPerDay: Maximum allowed plays per calendar day from day 2 onward. Defaults to 4.
    ///   - firstDayMaxPlays: Maximum plays on the first day the user ever plays (welcome bonus).
    ///     Resets on reinstall since UserDefaults is cleared. Defaults to 8.
    public init(
        userDefaults: UserDefaults,
        calendar: Calendar = .current,
        maxPlaysPerDay: Int = 4,
        firstDayMaxPlays: Int = 8
    ) {
        self.userDefaults = userDefaults
        self.calendar = calendar
        self.maxPlaysPerDay = maxPlaysPerDay
        self.firstDayMaxPlays = firstDayMaxPlays
    }

    // MARK: - PlayLimitService

    public var hasUnlimitedAccess: Bool {
        hasUnlimitedAccessEnabled()
    }

    public func canStartNewGame(on date: Date) -> Bool {
        guard !hasUnlimitedAccessEnabled() else { return true }
        let state = normalizedState(for: date)
        return state.count < effectiveLimit(for: date)
    }

    public func recordGamePlayed(on date: Date) {
        guard !hasUnlimitedAccessEnabled() else { return }

        if userDefaults.object(forKey: Keys.firstPlayDate) == nil {
            userDefaults.set(date, forKey: Keys.firstPlayDate)
            AppLog.info(AppLog.monetization, "First play day recorded — welcome bonus active")
        }

        var state = normalizedState(for: date)
        let limit = effectiveLimit(for: date)

        if state.count >= limit {
            AppLog.info(AppLog.monetization, "Daily limit (\(limit)) already reached — record ignored")
            return
        }

        state.count = min(state.count + 1, limit)
        persist(state: state)
        AppLog.info(AppLog.monetization, "Game recorded — \(state.count)/\(limit) plays used today")
    }

    public func remainingPlays(on date: Date) -> Int {
        if hasUnlimitedAccessEnabled() { return .max }
        let state = normalizedState(for: date)
        return max(0, effectiveLimit(for: date) - state.count)
    }

    public func maxPlays(on date: Date) -> Int {
        if hasUnlimitedAccessEnabled() { return .max }
        return effectiveLimit(for: date)
    }

    public func isFirstPlayDay(on date: Date) -> Bool {
        guard let firstPlay = userDefaults.object(forKey: Keys.firstPlayDate) as? Date else {
            return false
        }
        return calendar.isDate(firstPlay, inSameDayAs: date)
    }

    public func nextResetDate(after date: Date) -> Date {
        // Next midnight in the user's current calendar/locale.
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
    }

    public func unlockUnlimitedAccess() {
        userDefaults.set(true, forKey: Keys.hasUnlimitedAccess)
        AppLog.info(AppLog.monetization, "Unlimited access unlocked")
    }

    // MARK: - Private helpers

    private struct State {
        var date: Date
        var count: Int
    }

    /// Returns the play limit that applies on the given date.
    /// The first calendar day on which `recordGamePlayed` is ever called gets
    /// `firstDayMaxPlays`; every subsequent day gets `maxPlaysPerDay`.
    /// Clearing UserDefaults (e.g. on reinstall) resets the bonus.
    private func effectiveLimit(for date: Date) -> Int {
        guard let firstPlay = userDefaults.object(forKey: Keys.firstPlayDate) as? Date else {
            return firstDayMaxPlays
        }
        return calendar.isDate(firstPlay, inSameDayAs: date) ? firstDayMaxPlays : maxPlaysPerDay
    }

    /// Returns the stored state normalized for the given date.
    /// If the stored date is not the same calendar day as `date`,
    /// the count is reset to 0 and the date is updated.
    private func normalizedState(for date: Date) -> State {
        let storedDate = userDefaults.object(forKey: Keys.lastPlayDate) as? Date
        let storedCount = userDefaults.integer(forKey: Keys.todayCount)

        guard let lastDate = storedDate,
              calendar.isDate(lastDate, inSameDayAs: date) else {
            // New day: reset count.
            return State(date: date, count: 0)
        }

        return State(date: lastDate, count: storedCount)
    }

    private func persist(state: State) {
        userDefaults.set(state.date, forKey: Keys.lastPlayDate)
        userDefaults.set(state.count, forKey: Keys.todayCount)
    }

    private func hasUnlimitedAccessEnabled() -> Bool {
        let forceFreemium = userDefaults.bool(forKey: Keys.debugForceFreemium)
        return userDefaults.bool(forKey: Keys.hasUnlimitedAccess) && !forceFreemium
    }
}

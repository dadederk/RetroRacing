//
//  UserDefaultsPlayLimitService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 10/02/2026.
//

import Foundation

/// UserDefaults-backed implementation of `PlayLimitService`.
/// Uses a serial queue for thread-safety and a calendar-based
/// day boundary so counts reset at local midnight.
public final class UserDefaultsPlayLimitService: PlayLimitService {
    private enum Keys {
        static let lastPlayDate = "PlayLimit.lastPlayDate"
        static let todayCount = "PlayLimit.todayCount"
        static let hasUnlimitedAccess = "PlayLimit.hasUnlimitedAccess"
        static let debugForceFreemium = StoreKitService.DebugStorageKeys.forceFreemiumPlayLimit
    }

    private let userDefaults: UserDefaults
    private let calendar: Calendar
    private let maxPlaysPerDay: Int
    private let queue = DispatchQueue(label: "com.retroracing.playlimit")

    /// - Parameters:
    ///   - userDefaults: Backing store. Prefer `InfrastructureDefaults.userDefaults`.
    ///   - calendar: Calendar used to determine day boundaries. Defaults to `.current`.
    ///   - maxPlaysPerDay: Maximum allowed plays per calendar day. Defaults to 5.
    public init(
        userDefaults: UserDefaults,
        calendar: Calendar = .current,
        maxPlaysPerDay: Int = 5
    ) {
        self.userDefaults = userDefaults
        self.calendar = calendar
        self.maxPlaysPerDay = maxPlaysPerDay
    }

    // MARK: - PlayLimitService

    public var hasUnlimitedAccess: Bool {
        queue.sync {
            hasUnlimitedAccessEnabled()
        }
    }

    public func canStartNewGame(on date: Date) -> Bool {
        queue.sync {
            guard !hasUnlimitedAccessEnabled() else {
                return true
            }

            let state = normalizedState(for: date)
            return state.count < maxPlaysPerDay
        }
    }

    public func recordGamePlayed(on date: Date) {
        queue.sync {
            guard !hasUnlimitedAccessEnabled() else {
                return
            }

            var state = normalizedState(for: date)
            state.count = min(state.count + 1, maxPlaysPerDay)
            persist(state: state)
        }
    }

    public func remainingPlays(on date: Date) -> Int {
        queue.sync {
            if hasUnlimitedAccessEnabled() {
                return .max
            }
            let state = normalizedState(for: date)
            return max(0, maxPlaysPerDay - state.count)
        }
    }

    public func nextResetDate(after date: Date) -> Date {
        // Next midnight in the user's current calendar/locale.
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
    }

    public func unlockUnlimitedAccess() {
        queue.sync {
            userDefaults.set(true, forKey: Keys.hasUnlimitedAccess)
        }
    }

    // MARK: - Private helpers

    private struct State {
        var date: Date
        var count: Int
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

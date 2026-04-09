//
//  PlayLimitServiceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 10/02/2026.
//

import XCTest
@testable import RetroRacingShared

final class PlayLimitServiceTests: XCTestCase {

    private var userDefaults: UserDefaults!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "PlayLimitServiceTests")!
        userDefaults.removePersistentDomain(forName: "PlayLimitServiceTests")
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "PlayLimitServiceTests")
        userDefaults = nil
        calendar = nil
        super.tearDown()
    }

    // MARK: - First-day bonus

    func testGivenFirstDayWhenPlayingEightGamesThenNinthGameIsBlocked() {
        // Given
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar)
        let now = date(year: 2026, month: 2, day: 10, hour: 10)

        // When
        for i in 0..<8 {
            XCTAssertTrue(service.canStartNewGame(on: now), "Game \(i + 1) should be allowed on first day")
            service.recordGamePlayed(on: now)
        }

        // Then
        XCTAssertFalse(service.canStartNewGame(on: now))
        XCTAssertEqual(service.remainingPlays(on: now), 0)
    }

    func testGivenFirstDayWhenCheckingMaxPlaysThenReturnsEight() {
        // Given
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar)
        let now = date(year: 2026, month: 2, day: 10, hour: 10)

        // When
        service.recordGamePlayed(on: now)

        // Then
        XCTAssertEqual(service.maxPlays(on: now), 8)
    }

    func testGivenFirstDayWhenCheckingIsFirstPlayDayThenReturnsTrue() {
        // Given
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar)
        let now = date(year: 2026, month: 2, day: 10, hour: 10)
        service.recordGamePlayed(on: now)

        // When / Then
        XCTAssertTrue(service.isFirstPlayDay(on: now))
    }

    func testGivenSecondDayWhenCheckingIsFirstPlayDayThenReturnsFalse() {
        // Given
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar)
        let day1 = date(year: 2026, month: 2, day: 10, hour: 10)
        let day2 = date(year: 2026, month: 2, day: 11, hour: 10)
        service.recordGamePlayed(on: day1)

        // When / Then
        XCTAssertFalse(service.isFirstPlayDay(on: day2))
    }

    func testGivenNoGamesPlayedWhenCheckingIsFirstPlayDayThenReturnsFalse() {
        // Given
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar)
        let now = date(year: 2026, month: 2, day: 10, hour: 10)

        // When / Then — no firstPlayDate recorded yet
        XCTAssertFalse(service.isFirstPlayDay(on: now))
    }

    func testGivenSecondDayWhenCheckingMaxPlaysThenReturnsFour() {
        // Given
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar)
        let day1 = date(year: 2026, month: 2, day: 10, hour: 10)
        let day2 = date(year: 2026, month: 2, day: 11, hour: 10)
        service.recordGamePlayed(on: day1)

        // When / Then
        XCTAssertEqual(service.maxPlays(on: day2), 4)
    }

    func testGivenSecondDayWhenPlayingFourGamesThenFifthGameIsBlocked() {
        // Given
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar)
        let day1 = date(year: 2026, month: 2, day: 10, hour: 23)
        let day2 = date(year: 2026, month: 2, day: 11, hour: 9)
        service.recordGamePlayed(on: day1)

        // When
        for i in 0..<4 {
            XCTAssertTrue(service.canStartNewGame(on: day2), "Game \(i + 1) should be allowed on day 2")
            service.recordGamePlayed(on: day2)
        }

        // Then
        XCTAssertFalse(service.canStartNewGame(on: day2))
        XCTAssertEqual(service.remainingPlays(on: day2), 0)
    }

    func testGivenFirstDayExhaustedWhenMidnightPassesThenCounterResetsToFour() {
        // Given
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar)
        let day1 = date(year: 2026, month: 2, day: 10, hour: 23)
        for _ in 0..<8 {
            service.recordGamePlayed(on: day1)
        }
        XCTAssertFalse(service.canStartNewGame(on: day1))

        // When
        let day2 = date(year: 2026, month: 2, day: 11, hour: 0, minute: 1)

        // Then
        XCTAssertTrue(service.canStartNewGame(on: day2))
        XCTAssertEqual(service.remainingPlays(on: day2), 4)
        XCTAssertEqual(service.maxPlays(on: day2), 4)
    }

    // MARK: - Unlimited access

    func testGivenUnlimitedAccessWhenPlayingManyGamesThenAllGamesAreAllowed() {
        // Given
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar)
        let now = date(year: 2026, month: 2, day: 10, hour: 9)
        service.unlockUnlimitedAccess()

        // When
        for _ in 0..<20 {
            XCTAssertTrue(service.canStartNewGame(on: now))
            service.recordGamePlayed(on: now)
        }

        // Then
        XCTAssertTrue(service.hasUnlimitedAccess)
        XCTAssertEqual(service.remainingPlays(on: now), Int.max)
        XCTAssertEqual(service.maxPlays(on: now), Int.max)
    }

    @MainActor
    func testGivenUnlimitedAccessWhenFreemiumSimulationEnabledThenDailyLimitIsEnforced() {
        // Given — use firstDayMaxPlays: 4 so the flat-limit behavior is predictable
        let service = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 4,
            firstDayMaxPlays: 4
        )
        let storeKit = StoreKitService(userDefaults: userDefaults)
        let now = date(year: 2026, month: 2, day: 10, hour: 9)
        service.unlockUnlimitedAccess()
        storeKit.debugPremiumSimulationMode = .freemium

        // When
        for _ in 0..<4 {
            XCTAssertTrue(service.canStartNewGame(on: now))
            service.recordGamePlayed(on: now)
        }

        // Then
        XCTAssertFalse(service.hasUnlimitedAccess)
        XCTAssertFalse(service.canStartNewGame(on: now))
        XCTAssertEqual(service.remainingPlays(on: now), 0)
    }

    @MainActor
    func testGivenUnlimitedAccessWhenFreemiumIsSetButSimulationDisabledThenUnlimitedRemainsEnabled() {
        // Given
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar)
        let storeKit = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: false
        )
        let now = date(year: 2026, month: 2, day: 10, hour: 9)
        service.unlockUnlimitedAccess()

        // When
        storeKit.debugPremiumSimulationMode = .freemium
        for _ in 0..<20 {
            service.recordGamePlayed(on: now)
        }

        // Then
        XCTAssertTrue(service.hasUnlimitedAccess)
        XCTAssertTrue(service.canStartNewGame(on: now))
        XCTAssertEqual(service.remainingPlays(on: now), Int.max)
    }

    // MARK: - Reset date

    func testGivenAfternoonDateWhenRequestingNextResetThenReturnsNextMidnight() {
        // Given
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar)
        let now = date(year: 2026, month: 2, day: 10, hour: 15, minute: 30)

        // When
        let reset = service.nextResetDate(after: now)

        // Then
        let expected = date(year: 2026, month: 2, day: 11, hour: 0)
        XCTAssertEqual(reset, expected)
    }

    // MARK: - Helpers

    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
}

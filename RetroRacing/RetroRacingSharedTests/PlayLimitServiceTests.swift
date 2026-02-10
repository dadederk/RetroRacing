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

    func testInitialState_AllowsSixGamesPerDay() {
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar, maxPlaysPerDay: 6)
        let now = date(year: 2026, month: 2, day: 10, hour: 10)

        for i in 0..<6 {
            XCTAssertTrue(service.canStartNewGame(on: now), "Game \(i) should be allowed")
            service.recordGamePlayed(on: now)
        }

        XCTAssertFalse(service.canStartNewGame(on: now), "Seventh game should be blocked")
        XCTAssertEqual(service.remainingPlays(on: now), 0)
    }

    func testCounterResetsAtMidnight() {
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar, maxPlaysPerDay: 6)

        let day1 = date(year: 2026, month: 2, day: 10, hour: 23)
        for _ in 0..<6 {
            XCTAssertTrue(service.canStartNewGame(on: day1))
            service.recordGamePlayed(on: day1)
        }
        XCTAssertFalse(service.canStartNewGame(on: day1))

        // Next day at 00:01
        let day2 = date(year: 2026, month: 2, day: 11, hour: 0, minute: 1)
        XCTAssertTrue(service.canStartNewGame(on: day2))
        XCTAssertEqual(service.remainingPlays(on: day2), 6)
    }

    func testUnlockUnlimitedAccess_DisablesCounting() {
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar, maxPlaysPerDay: 6)
        let now = date(year: 2026, month: 2, day: 10, hour: 9)

        service.unlockUnlimitedAccess()
        XCTAssertTrue(service.hasUnlimitedAccess)

        // Should never block, and remaining plays should be effectively unlimited.
        for _ in 0..<20 {
            XCTAssertTrue(service.canStartNewGame(on: now))
            service.recordGamePlayed(on: now)
        }

        XCTAssertEqual(service.remainingPlays(on: now), Int.max)
    }

    func testNextResetDate_IsNextMidnight() {
        let service = UserDefaultsPlayLimitService(userDefaults: userDefaults, calendar: calendar, maxPlaysPerDay: 6)

        let now = date(year: 2026, month: 2, day: 10, hour: 15, minute: 30)
        let reset = service.nextResetDate(after: now)

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


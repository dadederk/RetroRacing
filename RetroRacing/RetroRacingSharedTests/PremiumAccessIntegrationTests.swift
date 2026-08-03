//
//  PremiumAccessIntegrationTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 10/02/2026.
//

import XCTest
import Foundation
@testable import RetroRacingShared

@MainActor
final class PremiumAccessIntegrationTests: XCTestCase {
    private let suiteName = "PremiumAccessIntegrationTests"
    private var storedUserDefaults: UserDefaults?

    private var userDefaults: UserDefaults {
        guard let storedUserDefaults else {
            XCTFail("Test UserDefaults accessed outside XCTest setup")
            return UserDefaults()
        }
        return storedUserDefaults
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        storedUserDefaults = defaults
    }

    override func tearDownWithError() throws {
        storedUserDefaults?.removePersistentDomain(forName: suiteName)
        storedUserDefaults = nil
        try super.tearDownWithError()
    }

    private func makeStoreKitService() -> StoreKitService {
        StoreKitService(userDefaults: userDefaults, refreshEntitlementsOnInit: false)
    }
    
    func testGivenPremiumUserWithExhaustedLimitWhenCheckingAccessThenPlayLimitIsBypassed() throws {
        // Given
        let storeKit = makeStoreKitService()
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 4,
            firstDayMaxPlays: 4
        )
        storeKit.debugPremiumSimulationMode = .unlimitedPlays
        let now = try date(year: 2026, month: 2, day: 10, hour: 15)
        for _ in 0..<4 {
            playLimit.recordGamePlayed(on: now)
        }
        XCTAssertTrue(playLimit.canStartNewGame(on: now) == false)
        
        // When
        let hasPremiumAccess = storeKit.hasPremiumAccess
        
        // Then
        XCTAssertTrue(hasPremiumAccess)
        XCTAssertTrue(playLimit.remainingPlays(on: now) == 0)
    }
    
    func testGivenFreeUserWhenPlayingFourGamesThenFifthGameIsBlocked() throws {
        // Given
        let storeKit = makeStoreKitService()
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 4,
            firstDayMaxPlays: 4
        )
        storeKit.debugPremiumSimulationMode = .freemium
        let now = try date(year: 2026, month: 2, day: 10, hour: 15)

        // When
        for i in 0..<4 {
            XCTAssertTrue(playLimit.canStartNewGame(on: now), "Game \(i + 1) should be allowed")
            playLimit.recordGamePlayed(on: now)
        }

        // Then
        XCTAssertTrue(storeKit.hasPremiumAccess == false)
        XCTAssertTrue(playLimit.canStartNewGame(on: now) == false)
        XCTAssertTrue(playLimit.remainingPlays(on: now) == 0)
    }
    
    func testGivenFreeUserWithExhaustedLimitWhenSwitchingToUnlimitedSimulationThenUnlimitedAccessIsGranted() throws {
        // Given
        let storeKit = makeStoreKitService()
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 4,
            firstDayMaxPlays: 4
        )
        let now = try date(year: 2026, month: 2, day: 10, hour: 15)
        storeKit.debugPremiumSimulationMode = .freemium
        XCTAssertTrue(storeKit.hasPremiumAccess == false)
        for _ in 0..<4 {
            playLimit.recordGamePlayed(on: now)
        }
        XCTAssertTrue(playLimit.canStartNewGame(on: now) == false)
        
        // When
        storeKit.debugPremiumSimulationMode = .unlimitedPlays
        
        // Then
        XCTAssertTrue(storeKit.hasPremiumAccess)
        XCTAssertTrue(playLimit.canStartNewGame(on: now) == false)
    }
    
    func testGivenUnlimitedSimulationWhenSwitchingToFreemiumThenPlayLimitsUseFreeTierState() throws {
        // Given — firstDayMaxPlays: 4 so the remaining count is predictable after the switch
        let storeKit = makeStoreKitService()
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 4,
            firstDayMaxPlays: 4
        )
        let now = try date(year: 2026, month: 2, day: 10, hour: 15)
        playLimit.unlockUnlimitedAccess()
        storeKit.debugPremiumSimulationMode = .unlimitedPlays
        XCTAssertTrue(storeKit.hasPremiumAccess)
        for _ in 0..<4 {
            playLimit.recordGamePlayed(on: now)
        }

        // When
        storeKit.debugPremiumSimulationMode = .freemium

        // Then
        XCTAssertTrue(storeKit.hasPremiumAccess == false)
        XCTAssertTrue(playLimit.hasUnlimitedAccess == false)
        XCTAssertTrue(playLimit.canStartNewGame(on: now))
        XCTAssertTrue(playLimit.remainingPlays(on: now) == 4)
    }
    
    func testGivenPremiumUserWhenCheckingSettingsVisibilityThenPlayLimitSectionIsHidden() {
        // Given
        let storeKit = makeStoreKitService()
        storeKit.debugPremiumSimulationMode = .unlimitedPlays
        
        // When
        let shouldShowSection = !storeKit.hasPremiumAccess
        
        // Then
        XCTAssertTrue(storeKit.hasPremiumAccess)
        XCTAssertTrue(shouldShowSection == false)
    }
    
    func testGivenFreeUserWhenCheckingSettingsVisibilityThenPlayLimitSectionIsVisible() {
        // Given
        let storeKit = makeStoreKitService()
        storeKit.debugPremiumSimulationMode = .freemium
        
        // When
        let shouldShowSection = !storeKit.hasPremiumAccess
        
        // Then
        XCTAssertTrue(storeKit.hasPremiumAccess == false)
        XCTAssertTrue(shouldShowSection)
    }
    
    func testGivenUnlimitedAccessFlagWhenRecordingGamesThenCountingIsStopped() throws {
        // Given
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 4,
            firstDayMaxPlays: 4
        )
        let now = try date(year: 2026, month: 2, day: 10, hour: 15)
        playLimit.unlockUnlimitedAccess()
        
        // When
        for _ in 0..<20 {
            playLimit.recordGamePlayed(on: now)
        }
        
        // Then
        XCTAssertTrue(playLimit.hasUnlimitedAccess)
        XCTAssertTrue(playLimit.canStartNewGame(on: now))
        XCTAssertTrue(playLimit.remainingPlays(on: now) == Int.max)
    }

    func testGivenUnlimitedSimulationWhenThemeGatingCallbackSyncsThemeManagerThenPremiumThemeSelectionSticks() throws {
        // Given
        let storeKit = makeStoreKitService()
        let themeConfig = ThemePlatformConfig.iPhone
        let manager = ThemeManager(
            configuration: themeConfig,
            userDefaults: userDefaults,
            hasPremiumAccess: storeKit.hasPremiumAccessForGating
        )
        storeKit.onPremiumAccessForGatingUpdated = { hasPremiumAccessForGating in
            manager.syncPremiumAccess(hasPremiumAccessForGating)
        }
        let pocketTheme = try XCTUnwrap(themeConfig.availableThemes.first { $0.id == .pocket })
        XCTAssertTrue(manager.currentTheme.id == .lcd)

        // When
        storeKit.debugPremiumSimulationMode = .unlimitedPlays
        manager.setTheme(pocketTheme)

        // Then
        XCTAssertTrue(manager.currentTheme.id == .pocket)
        XCTAssertTrue(userDefaults.string(forKey: "selectedThemeID") == "pocket")

        // When
        storeKit.debugPremiumSimulationMode = .freemium

        // Then
        XCTAssertTrue(manager.currentTheme.id == .lcd)
        XCTAssertTrue(manager.isThemeAvailable(pocketTheme) == false)
        XCTAssertTrue(userDefaults.string(forKey: "selectedThemeID") == "pocket")

        // When
        storeKit.debugPremiumSimulationMode = .unlimitedPlays

        // Then
        XCTAssertTrue(manager.currentTheme.id == .pocket)
    }
    
    // MARK: - Helpers
    
    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return try XCTUnwrap(calendar.date(from: components))
    }
}

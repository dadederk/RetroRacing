//
//  PremiumAccessIntegrationTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 10/02/2026.
//

import XCTest
@testable import RetroRacingShared

@MainActor
final class PremiumAccessIntegrationTests: XCTestCase {
    
    private var userDefaults: UserDefaults!
    private var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "PremiumAccessIntegrationTests")!
        userDefaults.removePersistentDomain(forName: "PremiumAccessIntegrationTests")
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }
    
    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "PremiumAccessIntegrationTests")
        userDefaults = nil
        calendar = nil
        super.tearDown()
    }
    
    func testGivenPremiumUserWithExhaustedLimitWhenCheckingAccessThenPlayLimitIsBypassed() {
        // Given
        let storeKit = StoreKitService(userDefaults: userDefaults)
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 5
        )
        storeKit.debugPremiumSimulationMode = .unlimitedPlays
        let now = date(year: 2026, month: 2, day: 10, hour: 15)
        for _ in 0..<5 {
            playLimit.recordGamePlayed(on: now)
        }
        XCTAssertFalse(playLimit.canStartNewGame(on: now))
        
        // When
        let hasPremiumAccess = storeKit.hasPremiumAccess
        
        // Then
        XCTAssertTrue(hasPremiumAccess)
        XCTAssertEqual(playLimit.remainingPlays(on: now), 0)
    }
    
    func testGivenFreeUserWhenPlayingFiveGamesThenSixthGameIsBlocked() {
        // Given
        let storeKit = StoreKitService(userDefaults: userDefaults)
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 5
        )
        storeKit.debugPremiumSimulationMode = .freemium
        let now = date(year: 2026, month: 2, day: 10, hour: 15)
        
        // When
        for i in 0..<5 {
            XCTAssertTrue(playLimit.canStartNewGame(on: now), "Game \(i+1) should be allowed")
            playLimit.recordGamePlayed(on: now)
        }
        
        // Then
        XCTAssertFalse(storeKit.hasPremiumAccess)
        XCTAssertFalse(playLimit.canStartNewGame(on: now))
        XCTAssertEqual(playLimit.remainingPlays(on: now), 0)
    }
    
    func testGivenFreeUserWithExhaustedLimitWhenSwitchingToUnlimitedSimulationThenUnlimitedAccessIsGranted() {
        // Given
        let storeKit = StoreKitService(userDefaults: userDefaults)
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 5
        )
        let now = date(year: 2026, month: 2, day: 10, hour: 15)
        storeKit.debugPremiumSimulationMode = .freemium
        XCTAssertFalse(storeKit.hasPremiumAccess)
        for _ in 0..<5 {
            playLimit.recordGamePlayed(on: now)
        }
        XCTAssertFalse(playLimit.canStartNewGame(on: now))
        
        // When
        storeKit.debugPremiumSimulationMode = .unlimitedPlays
        
        // Then
        XCTAssertTrue(storeKit.hasPremiumAccess)
        XCTAssertFalse(playLimit.canStartNewGame(on: now))
    }
    
    func testGivenUnlimitedSimulationWhenSwitchingToFreemiumThenPlayLimitsUseFreeTierState() {
        // Given
        let storeKit = StoreKitService(userDefaults: userDefaults)
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 5
        )
        let now = date(year: 2026, month: 2, day: 10, hour: 15)
        playLimit.unlockUnlimitedAccess()
        storeKit.debugPremiumSimulationMode = .unlimitedPlays
        XCTAssertTrue(storeKit.hasPremiumAccess)
        for _ in 0..<5 {
            playLimit.recordGamePlayed(on: now)
        }
        
        // When
        storeKit.debugPremiumSimulationMode = .freemium
        
        // Then
        XCTAssertFalse(storeKit.hasPremiumAccess)
        XCTAssertFalse(playLimit.hasUnlimitedAccess)
        XCTAssertTrue(playLimit.canStartNewGame(on: now))
        XCTAssertEqual(playLimit.remainingPlays(on: now), 5)
    }
    
    func testGivenPremiumUserWhenCheckingSettingsVisibilityThenPlayLimitSectionIsHidden() {
        // Given
        let storeKit = StoreKitService(userDefaults: userDefaults)
        storeKit.debugPremiumSimulationMode = .unlimitedPlays
        
        // When
        let shouldShowSection = !storeKit.hasPremiumAccess
        
        // Then
        XCTAssertTrue(storeKit.hasPremiumAccess)
        XCTAssertFalse(shouldShowSection)
    }
    
    func testGivenFreeUserWhenCheckingSettingsVisibilityThenPlayLimitSectionIsVisible() {
        // Given
        let storeKit = StoreKitService(userDefaults: userDefaults)
        storeKit.debugPremiumSimulationMode = .freemium
        
        // When
        let shouldShowSection = !storeKit.hasPremiumAccess
        
        // Then
        XCTAssertFalse(storeKit.hasPremiumAccess)
        XCTAssertTrue(shouldShowSection)
    }
    
    func testGivenUnlimitedAccessFlagWhenRecordingGamesThenCountingIsStopped() {
        // Given
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 5
        )
        let now = date(year: 2026, month: 2, day: 10, hour: 15)
        playLimit.unlockUnlimitedAccess()
        
        // When
        for _ in 0..<20 {
            playLimit.recordGamePlayed(on: now)
        }
        
        // Then
        XCTAssertTrue(playLimit.hasUnlimitedAccess)
        XCTAssertTrue(playLimit.canStartNewGame(on: now))
        XCTAssertEqual(playLimit.remainingPlays(on: now), Int.max)
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

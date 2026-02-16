//
//  DebugSimulationProductionIsolationTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 16/02/2026.
//

import XCTest
@testable import RetroRacingShared

/// Verifies that debug simulation features are properly isolated to DEBUG builds
/// and that production scenarios work correctly regardless of simulation state.
@MainActor
final class DebugSimulationProductionIsolationTests: XCTestCase {
    
    private var userDefaults: UserDefaults!
    private var calendar: Calendar!
    
    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "DebugSimulationProductionIsolationTests")!
        userDefaults.removePersistentDomain(forName: "DebugSimulationProductionIsolationTests")
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }
    
    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "DebugSimulationProductionIsolationTests")
        userDefaults = nil
        calendar = nil
        super.tearDown()
    }
    
    // MARK: - Production Mode Tests
    
    func testGivenProductionBuildWhenSettingSimulationModeThenAlwaysRevertsToProductionDefault() {
        // Given
        let service = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: false
        )
        
        // When - Attempt to set simulation modes
        service.debugPremiumSimulationMode = .unlimitedPlays
        let afterUnlimited = service.debugPremiumSimulationMode
        
        service.debugPremiumSimulationMode = .freemium
        let afterFreemium = service.debugPremiumSimulationMode
        
        // Then
        XCTAssertEqual(afterUnlimited, .productionDefault)
        XCTAssertEqual(afterFreemium, .productionDefault)
    }
    
    func testGivenProductionBuildWhenCheckingPremiumAccessThenAlwaysUsesRealEntitlements() {
        // Given
        let service = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: false
        )
        
        // When - Attempt to set simulation mode to unlimited
        service.debugPremiumSimulationMode = .unlimitedPlays
        let hasPremiumAfterUnlimited = service.hasPremiumAccess
        
        // When - Attempt to set simulation mode to freemium
        service.debugPremiumSimulationMode = .freemium
        let hasPremiumAfterFreemium = service.hasPremiumAccess
        
        // Then - Should always match real entitlements (empty in this test)
        let expectedPremium = !service.purchasedProductIDs.isEmpty
        XCTAssertEqual(hasPremiumAfterUnlimited, expectedPremium)
        XCTAssertEqual(hasPremiumAfterFreemium, expectedPremium)
    }
    
    func testGivenProductionBuildWhenSettingFreemiumSimulationThenPlayLimitDebugKeyRemainsUnset() {
        // Given
        let service = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: false
        )
        
        // When
        service.debugPremiumSimulationMode = .freemium
        
        // Then
        XCTAssertFalse(userDefaults.bool(forKey: StoreKitService.DebugStorageKeys.forceFreemiumPlayLimit))
        XCTAssertEqual(service.debugPremiumSimulationMode, .productionDefault)
    }
    
    func testGivenProductionBuildWithUnlimitedAccessWhenCheckingPlayLimitThenUsesRealUnlimitedAccess() {
        // Given
        let service = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: false
        )
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 5
        )
        let now = date(year: 2026, month: 2, day: 16, hour: 10)
        
        // When - Grant real unlimited access
        playLimit.unlockUnlimitedAccess()
        
        // Then - Should have unlimited access regardless of simulation attempts
        service.debugPremiumSimulationMode = .freemium
        XCTAssertTrue(playLimit.hasUnlimitedAccess)
        XCTAssertTrue(playLimit.canStartNewGame(on: now))
        XCTAssertEqual(playLimit.remainingPlays(on: now), Int.max)
    }
    
    // MARK: - Debug Mode Tests
    
    func testGivenDebugBuildWhenSettingUnlimitedSimulationThenHasPremiumAccessReturnsTrue() {
        // Given
        let service = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: true
        )
        
        // When
        service.debugPremiumSimulationMode = .unlimitedPlays
        
        // Then
        XCTAssertTrue(service.hasPremiumAccess)
        XCTAssertEqual(service.debugPremiumSimulationMode, .unlimitedPlays)
    }
    
    func testGivenDebugBuildWhenSettingFreemiumSimulationThenHasPremiumAccessReturnsFalse() {
        // Given
        let service = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: true
        )
        
        // When
        service.debugPremiumSimulationMode = .freemium
        
        // Then
        XCTAssertFalse(service.hasPremiumAccess)
        XCTAssertEqual(service.debugPremiumSimulationMode, .freemium)
    }
    
    func testGivenDebugBuildWhenSettingProductionDefaultThenUsesRealEntitlements() {
        // Given
        let service = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: true
        )
        
        // When
        service.debugPremiumSimulationMode = .productionDefault
        let hasPremium = service.hasPremiumAccess
        let expectedPremium = !service.purchasedProductIDs.isEmpty
        
        // Then
        XCTAssertEqual(hasPremium, expectedPremium)
        XCTAssertEqual(service.debugPremiumSimulationMode, .productionDefault)
    }
    
    // MARK: - Play Limit Integration Tests
    
    func testGivenDebugBuildWithFreemiumSimulationWhenUserHasRealUnlimitedAccessThenPlayLimitIsEnforced() {
        // Given
        let service = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: true
        )
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 5
        )
        let now = date(year: 2026, month: 2, day: 16, hour: 10)
        
        // When - User has real unlimited access but simulation forces freemium
        playLimit.unlockUnlimitedAccess()
        service.debugPremiumSimulationMode = .freemium
        
        // Then - Play limit should be enforced (freemium override takes precedence)
        XCTAssertFalse(playLimit.hasUnlimitedAccess)
        XCTAssertTrue(playLimit.canStartNewGame(on: now))
        XCTAssertEqual(playLimit.remainingPlays(on: now), 5)
    }
    
    func testGivenDebugBuildWithProductionDefaultWhenUserHasRealUnlimitedAccessThenUnlimitedPlayIsAvailable() {
        // Given
        let service = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: true
        )
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 5
        )
        let now = date(year: 2026, month: 2, day: 16, hour: 10)
        
        // When - User has real unlimited access and simulation is set to production default
        playLimit.unlockUnlimitedAccess()
        service.debugPremiumSimulationMode = .productionDefault
        
        // Then - Unlimited play should be available
        XCTAssertTrue(playLimit.hasUnlimitedAccess)
        XCTAssertTrue(playLimit.canStartNewGame(on: now))
        XCTAssertEqual(playLimit.remainingPlays(on: now), Int.max)
    }
    
    func testGivenProductionBuildWithFreemiumAttemptWhenUserHasRealUnlimitedAccessThenUnlimitedPlayIsAvailable() {
        // Given
        let service = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: false
        )
        let playLimit = UserDefaultsPlayLimitService(
            userDefaults: userDefaults,
            calendar: calendar,
            maxPlaysPerDay: 5
        )
        let now = date(year: 2026, month: 2, day: 16, hour: 10)
        
        // When - User has real unlimited access and we attempt to force freemium (should fail)
        playLimit.unlockUnlimitedAccess()
        service.debugPremiumSimulationMode = .freemium
        
        // Then - Unlimited play should still be available (production ignores simulation)
        XCTAssertTrue(playLimit.hasUnlimitedAccess)
        XCTAssertTrue(playLimit.canStartNewGame(on: now))
        XCTAssertEqual(playLimit.remainingPlays(on: now), Int.max)
        XCTAssertEqual(service.debugPremiumSimulationMode, .productionDefault)
    }
    
    // MARK: - Debug Key Synchronization Tests
    
    func testGivenDebugBuildWhenSwitchingBetweenModesTheDebugKeyIsSynchronized() {
        // Given
        let service = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: true
        )
        
        // When - Switch to freemium
        service.debugPremiumSimulationMode = .freemium
        let debugKeyAfterFreemium = userDefaults.bool(forKey: StoreKitService.DebugStorageKeys.forceFreemiumPlayLimit)
        
        // When - Switch to unlimited
        service.debugPremiumSimulationMode = .unlimitedPlays
        let debugKeyAfterUnlimited = userDefaults.bool(forKey: StoreKitService.DebugStorageKeys.forceFreemiumPlayLimit)
        
        // When - Switch to production default
        service.debugPremiumSimulationMode = .productionDefault
        let debugKeyAfterProduction = userDefaults.bool(forKey: StoreKitService.DebugStorageKeys.forceFreemiumPlayLimit)
        
        // Then
        XCTAssertTrue(debugKeyAfterFreemium)
        XCTAssertFalse(debugKeyAfterUnlimited)
        XCTAssertFalse(debugKeyAfterProduction)
    }
    
    func testGivenProductionBuildWhenAttemptingToSetFreemiumThenDebugKeyRemainsUnset() {
        // Given
        let service = StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: false
        )
        
        // When
        service.debugPremiumSimulationMode = .freemium
        
        // Then
        XCTAssertFalse(userDefaults.bool(forKey: StoreKitService.DebugStorageKeys.forceFreemiumPlayLimit))
    }
    
    // MARK: - Build Configuration Tests
    
    func testGivenBuildConfigurationWhenCheckingIsDebugThenReturnsExpectedValue() {
        // Given / When
        let isDebug = BuildConfiguration.isDebug
        
        // Then
        #if DEBUG
        XCTAssertTrue(isDebug)
        #else
        XCTAssertFalse(isDebug)
        #endif
    }
    
    func testGivenBuildConfigurationWhenCheckingShouldShowDebugFeaturesThenReturnsExpectedValue() {
        // Given / When
        let shouldShow = BuildConfiguration.shouldShowDebugFeatures
        
        // Then
        #if DEBUG
        XCTAssertTrue(shouldShow)
        #else
        XCTAssertFalse(shouldShow)
        #endif
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

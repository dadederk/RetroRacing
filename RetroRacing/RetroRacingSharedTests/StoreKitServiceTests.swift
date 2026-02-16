//
//  StoreKitServiceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 10/02/2026.
//

import XCTest
@testable import RetroRacingShared

@MainActor
final class StoreKitServiceTests: XCTestCase {
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "StoreKitServiceTests")!
        userDefaults.removePersistentDomain(forName: "StoreKitServiceTests")
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "StoreKitServiceTests")
        userDefaults = nil
        super.tearDown()
    }

    private func makeService() -> StoreKitService {
        StoreKitService(userDefaults: userDefaults)
    }
    
    func testGivenInitialStateWhenCheckingDefaultsThenSimulationModeIsProductionAndPremiumMatchesEntitlements() {
        // Given
        let service = makeService()
        
        // When
        let hasPremium = service.hasPremiumAccess
        let expectedPremium = !service.purchasedProductIDs.isEmpty
        
        // Then
        XCTAssertEqual(service.debugPremiumSimulationMode, .productionDefault)
        XCTAssertEqual(hasPremium, expectedPremium)
    }
    
    func testGivenUnlimitedSimulationModeWhenCheckingPremiumAccessThenReturnsTrue() {
        // Given
        let service = makeService()
        service.debugPremiumSimulationMode = .unlimitedPlays
        
        // When
        let hasPremium = service.hasPremiumAccess
        
        // Then
        XCTAssertTrue(hasPremium)
    }
    
    func testGivenFreemiumSimulationModeWhenCheckingPremiumAccessThenReturnsFalse() {
        // Given
        let service = makeService()
        service.debugPremiumSimulationMode = .freemium
        
        // When
        let hasPremium = service.hasPremiumAccess
        
        // Then
        XCTAssertFalse(hasPremium)
    }
    
    func testGivenUnlimitedSimulationModeWhenSwitchingToProductionThenPremiumAccessMatchesEntitlements() {
        // Given
        let service = makeService()
        service.debugPremiumSimulationMode = .unlimitedPlays
        XCTAssertTrue(service.hasPremiumAccess)
        
        // When
        service.debugPremiumSimulationMode = .productionDefault
        let expectedPremium = !service.purchasedProductIDs.isEmpty
        
        // Then
        XCTAssertEqual(service.debugPremiumSimulationMode, .productionDefault)
        XCTAssertEqual(service.hasPremiumAccess, expectedPremium)
    }
    
    func testGivenProductionSimulationModeWhenCheckingPremiumAccessThenPremiumMatchesEntitlements() {
        // Given
        let service = makeService()
        service.debugPremiumSimulationMode = .productionDefault
        
        // When
        let hasPremium = service.hasPremiumAccess
        let expectedPremium = !service.purchasedProductIDs.isEmpty
        
        // Then
        XCTAssertEqual(hasPremium, expectedPremium)
    }
    
    func testGivenProductIDEnumWhenAccessingRawValueThenReturnsCorrectBundleIdentifier() {
        // Given
        let productID = StoreKitService.ProductID.unlimitedPlays
        
        // When
        let rawValue = productID.rawValue
        
        // Then
        XCTAssertEqual(rawValue, "com.accessibilityUpTo11.RetroRacing.unlimitedPlays")
    }
    
    func testGivenProductIDEnumWhenCheckingAllCasesThenReturnsOnlyUnlimitedPlays() {
        // Given
        let allProducts = StoreKitService.ProductID.allCases
        
        // When
        let count = allProducts.count
        
        // Then
        XCTAssertEqual(count, 1)
        XCTAssertEqual(allProducts.first, .unlimitedPlays)
    }

    func testGivenSimulationModeEnumWhenCheckingAllCasesThenReturnsThreeModes() {
        // Given
        let allModes = StoreKitService.DebugPremiumSimulationMode.allCases

        // When
        let count = allModes.count

        // Then
        XCTAssertEqual(count, 3)
        XCTAssertEqual(allModes.first, .productionDefault)
        XCTAssertEqual(allModes.last, .freemium)
    }

    func testGivenFreemiumSimulationWhenSyncingPlayLimitOverrideThenDebugKeyIsTrue() {
        // Given
        let service = makeService()

        // When
        service.debugPremiumSimulationMode = .freemium

        // Then
        XCTAssertTrue(userDefaults.bool(forKey: StoreKitService.DebugStorageKeys.forceFreemiumPlayLimit))
    }

    func testGivenDefaultSimulationWhenSyncingPlayLimitOverrideThenDebugKeyIsFalse() {
        // Given
        let service = makeService()
        service.debugPremiumSimulationMode = .freemium

        // When
        service.debugPremiumSimulationMode = .productionDefault

        // Then
        XCTAssertFalse(userDefaults.bool(forKey: StoreKitService.DebugStorageKeys.forceFreemiumPlayLimit))
    }
}

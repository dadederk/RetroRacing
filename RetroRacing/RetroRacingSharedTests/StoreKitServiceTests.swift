//
//  StoreKitServiceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 10/02/2026.
//

import XCTest
import Foundation
@testable import RetroRacingShared

@MainActor
final class StoreKitServiceTests: XCTestCase {
    private let suiteName = "StoreKitServiceTests"
    private var storedUserDefaults: UserDefaults?

    private var userDefaults: UserDefaults {
        guard let storedUserDefaults else {
            XCTFail("Test UserDefaults accessed outside XCTest setup")
            return UserDefaults()
        }
        return storedUserDefaults
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

    private func makeService(isDebugSimulationEnabled: Bool = true) -> StoreKitService {
        StoreKitService(
            userDefaults: userDefaults,
            isDebugSimulationEnabled: isDebugSimulationEnabled,
            refreshEntitlementsOnInit: false
        )
    }
    
    func testGivenInitialStateWhenCheckingDefaultsThenSimulationModeIsProductionAndPremiumMatchesEntitlements() {
        // Given
        let service = makeService()
        
        // When
        let hasPremium = service.hasPremiumAccess
        let expectedPremium = !service.purchasedProductIDs.isEmpty
        
        // Then
        XCTAssertTrue(service.debugPremiumSimulationMode == .productionDefault)
        XCTAssertTrue(hasPremium == expectedPremium)
    }

    func testGivenCachedPremiumWhenDebugFreemiumGatingThenCacheDoesNotGrantAccess() {
        // Given
        userDefaults.set(true, forKey: StoreKitService.StorageKeys.cachedPremiumAccess)
        let service = makeService()

        // When
        service.debugPremiumSimulationMode = .freemium

        // Then
        XCTAssertTrue(service.hasPremiumAccessForGating == false)
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
        XCTAssertTrue(hasPremium == false)
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
        XCTAssertTrue(service.debugPremiumSimulationMode == .productionDefault)
        XCTAssertTrue(service.hasPremiumAccess == expectedPremium)
    }
    
    func testGivenProductionSimulationModeWhenCheckingPremiumAccessThenPremiumMatchesEntitlements() {
        // Given
        let service = makeService()
        service.debugPremiumSimulationMode = .productionDefault
        
        // When
        let hasPremium = service.hasPremiumAccess
        let expectedPremium = !service.purchasedProductIDs.isEmpty
        
        // Then
        XCTAssertTrue(hasPremium == expectedPremium)
    }
    
    func testGivenProductIDEnumWhenAccessingRawValueThenReturnsCorrectBundleIdentifier() {
        // Given
        let productID = StoreKitService.ProductID.unlimitedPlays
        
        // When
        let rawValue = productID.rawValue
        
        // Then
        XCTAssertTrue(rawValue == "com.accessibilityUpTo11.RetroRacing.unlimitedPlays")
    }
    
    func testGivenProductIDEnumWhenCheckingAllCasesThenReturnsOnlyUnlimitedPlays() {
        // Given
        let allProducts = StoreKitService.ProductID.allCases
        
        // When
        let count = allProducts.count
        
        // Then
        XCTAssertTrue(count == 1)
        XCTAssertTrue(allProducts.first == .unlimitedPlays)
    }

    func testGivenSimulationModeEnumWhenCheckingAllCasesThenReturnsThreeModes() {
        // Given
        let allModes = StoreKitService.DebugPremiumSimulationMode.allCases

        // When
        let count = allModes.count

        // Then
        XCTAssertTrue(count == 3)
        XCTAssertTrue(allModes.first == .productionDefault)
        XCTAssertTrue(allModes.last == .freemium)
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
        XCTAssertTrue(userDefaults.bool(forKey: StoreKitService.DebugStorageKeys.forceFreemiumPlayLimit) == false)
    }

    func testGivenSimulationDisabledWhenSettingFreemiumThenModeResetsToProductionAndDebugKeyIsFalse() {
        // Given
        let service = makeService(isDebugSimulationEnabled: false)

        // When
        service.debugPremiumSimulationMode = .freemium

        // Then
        XCTAssertTrue(service.debugPremiumSimulationMode == .productionDefault)
        XCTAssertTrue(userDefaults.bool(forKey: StoreKitService.DebugStorageKeys.forceFreemiumPlayLimit) == false)
        XCTAssertTrue(service.hasPremiumAccess == !service.purchasedProductIDs.isEmpty)
    }

    func testGivenSimulationDisabledWhenSettingUnlimitedThenPremiumStillMatchesEntitlements() {
        // Given
        let service = makeService(isDebugSimulationEnabled: false)

        // When
        service.debugPremiumSimulationMode = .unlimitedPlays

        // Then
        XCTAssertTrue(service.debugPremiumSimulationMode == .productionDefault)
        XCTAssertTrue(service.hasPremiumAccess == !service.purchasedProductIDs.isEmpty)
    }

    // MARK: - hasPurchased simulation tests

    func testGivenFreemiumSimulationModeWhenCheckingHasPurchasedForUnlimitedPlaysThenReturnsFalse() {
        // Given
        let service = makeService()
        service.debugPremiumSimulationMode = .freemium

        // When
        let result = service.hasPurchased(StoreKitService.ProductID.unlimitedPlays.rawValue)

        // Then
        XCTAssertTrue(result == false)
    }

    func testGivenUnlimitedSimulationModeWhenCheckingHasPurchasedForUnlimitedPlaysThenReturnsTrue() {
        // Given
        let service = makeService()
        service.debugPremiumSimulationMode = .unlimitedPlays

        // When
        let result = service.hasPurchased(StoreKitService.ProductID.unlimitedPlays.rawValue)

        // Then
        XCTAssertTrue(result)
    }

    func testGivenUnlimitedSimulationModeWhenCheckingHasPurchasedForUnknownProductThenReturnsFalse() {
        // Given
        let service = makeService()
        service.debugPremiumSimulationMode = .unlimitedPlays

        // When
        let result = service.hasPurchased("com.some.other.product")

        // Then
        XCTAssertTrue(result == false)
    }

    func testGivenProductionDefaultModeWithNoEntitlementsWhenCheckingHasPurchasedThenReturnsFalse() {
        // Given
        let service = makeService()
        service.debugPremiumSimulationMode = .productionDefault

        // When
        let result = service.hasPurchased(StoreKitService.ProductID.unlimitedPlays.rawValue)

        // Then – purchasedProductIDs is empty in the test environment (no real transactions)
        XCTAssertTrue(result == false)
    }

    func testGivenSimulationDisabledWhenCheckingHasPurchasedThenReturnsRealEntitlementState() {
        // Given
        let service = makeService(isDebugSimulationEnabled: false)

        // When
        let result = service.hasPurchased(StoreKitService.ProductID.unlimitedPlays.rawValue)

        // Then – simulation is off so result matches purchasedProductIDs (empty in test env)
        XCTAssertTrue(result == service.purchasedProductIDs.contains(StoreKitService.ProductID.unlimitedPlays.rawValue))
    }

    // MARK: - Premium cache / gating

    func testGivenPersistedPremiumCacheWhenCreatingServiceThenCachedPremiumAccessIsSeeded() {
        // Given
        userDefaults.set(true, forKey: StoreKitService.StorageKeys.cachedPremiumAccess)

        // When
        let service = makeService()

        // Then
        XCTAssertTrue(service.cachedPremiumAccess)
    }

    func testGivenCachedPremiumBeforeResolveWhenCheckingGatingThenPremiumAccessForGatingIsTrue() {
        // Given
        userDefaults.set(true, forKey: StoreKitService.StorageKeys.cachedPremiumAccess)
        let service = makeService()

        // When
        let hasPremiumForGating = service.hasPremiumAccessForGating
        let shouldShowFreeTier = service.shouldShowFreeTierAffordances

        // Then
        XCTAssertTrue(hasPremiumForGating)
        XCTAssertTrue(shouldShowFreeTier == false)
    }

    func testGivenNoEntitlementCheckYetWhenCheckingFreeTierAffordancesThenLocksAreWithheld() {
        // Given
        let service = makeService()

        // When
        let shouldShowFreeTier = service.shouldShowFreeTierAffordances

        // Then
        XCTAssertTrue(service.hasResolvedInitialEntitlements == false)
        XCTAssertTrue(shouldShowFreeTier == false)
    }

    func testGivenEntitlementsRefreshedWhenCheckingFreeTierAffordancesThenFollowsLiveAccess() async {
        // Given
        let service = makeService()

        // When
        await service.refreshPurchasedProducts()

        // Then
        XCTAssertTrue(service.hasResolvedInitialEntitlements)
        XCTAssertTrue(service.shouldShowFreeTierAffordances == !service.hasPremiumAccess)
    }

    func testGivenEntitlementsRefreshedWhenCheckingGatingThenFollowsLiveAccess() async {
        // Given
        userDefaults.set(true, forKey: StoreKitService.StorageKeys.cachedPremiumAccess)
        let service = makeService()

        // When
        await service.refreshPurchasedProducts()

        // Then
        XCTAssertTrue(service.hasPremiumAccessForGating == service.hasPremiumAccess)
    }

    func testGivenEntitlementsUpdatedCallbackWhenRefreshingThenReceivesRealEntitlementState() async {
        // Given
        let service = makeService()
        var receivedValues: [Bool] = []
        service.onEntitlementsUpdated = { receivedValues.append($0) }

        // When
        await service.refreshPurchasedProducts()

        // Then
        XCTAssertTrue(receivedValues == [!service.purchasedProductIDs.isEmpty])
    }

    func testGivenDebugSimulationModeChangesWhenObservingGatingThenReceivesEffectivePremiumAccess() {
        // Given
        let service = makeService()
        var receivedValues: [Bool] = []
        service.onPremiumAccessForGatingUpdated = { receivedValues.append($0) }

        // When
        service.debugPremiumSimulationMode = .unlimitedPlays
        service.debugPremiumSimulationMode = .freemium
        service.debugPremiumSimulationMode = .productionDefault

        // Then
        XCTAssertTrue(receivedValues == [true, false, false])
    }

    func testGivenUnlimitedSimulationWhenRefreshingThenPersistedCacheUsesRealEntitlements() async {
        // Given
        let service = makeService()
        service.debugPremiumSimulationMode = .unlimitedPlays

        // When
        await service.refreshPurchasedProducts()

        // Then
        XCTAssertTrue(userDefaults.bool(forKey: StoreKitService.StorageKeys.cachedPremiumAccess) == false)
    }
}

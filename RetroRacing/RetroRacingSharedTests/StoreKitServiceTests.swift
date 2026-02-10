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
    
    func testGivenInitialStateWhenDebugIsEnabledThenPremiumAccessIsGranted() {
        // Given
        let service = StoreKitService()
        
        // When
        let hasPremium = service.hasPremiumAccess
        
        // Then
        XCTAssertTrue(service.debugPremiumEnabled)
        XCTAssertTrue(hasPremium)
    }
    
    func testGivenDebugEnabledWhenCheckingPremiumAccessThenReturnsTrue() {
        // Given
        let service = StoreKitService()
        service.debugPremiumEnabled = true
        
        // When
        let hasPremium = service.hasPremiumAccess
        
        // Then
        XCTAssertTrue(hasPremium)
        XCTAssertTrue(service.purchasedProductIDs.isEmpty)
    }
    
    func testGivenDebugDisabledAndNoPurchasesWhenCheckingPremiumAccessThenReturnsFalse() {
        // Given
        let service = StoreKitService()
        service.debugPremiumEnabled = false
        
        // When
        let hasPremium = service.hasPremiumAccess
        
        // Then
        XCTAssertFalse(hasPremium)
        XCTAssertTrue(service.purchasedProductIDs.isEmpty)
    }
    
    func testGivenDebugEnabledWhenTogglingOffThenPremiumAccessIsDenied() {
        // Given
        let service = StoreKitService()
        XCTAssertTrue(service.debugPremiumEnabled)
        XCTAssertTrue(service.hasPremiumAccess)
        
        // When
        service.debugPremiumEnabled = false
        
        // Then
        XCTAssertFalse(service.debugPremiumEnabled)
        XCTAssertFalse(service.hasPremiumAccess)
    }
    
    func testGivenDebugEnabledWhenCheckingPremiumAccessThenDebugOverridesEmptyPurchases() {
        // Given
        let service = StoreKitService()
        service.debugPremiumEnabled = true
        
        // When
        let hasPremium = service.hasPremiumAccess
        
        // Then
        XCTAssertTrue(service.purchasedProductIDs.isEmpty)
        XCTAssertTrue(hasPremium)
    }
    
    func testGivenProductIDEnumWhenAccessingRawValueThenReturnsCorrectBundleIdentifier() {
        // Given
        let productID = StoreKitService.ProductID.unlimitedPlays
        
        // When
        let rawValue = productID.rawValue
        
        // Then
        XCTAssertEqual(rawValue, "com.retroRacing.unlimitedPlays")
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
}

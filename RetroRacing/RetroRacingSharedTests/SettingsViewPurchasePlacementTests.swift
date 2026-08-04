//
//  SettingsViewPurchasePlacementTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 03/08/2026.
//

import XCTest
@testable import RetroRacingShared

final class SettingsViewPurchasePlacementTests: XCTestCase {
    func testGivenUnlimitedAccessWhenOrderingSettingsThenPurchasesMoveToBottom() {
        // Given
        let hasPremiumAccessForGating = true

        // When
        let shouldPlaceAtBottom = SettingsView.shouldPlacePurchasesSectionAtBottom(
            hasPremiumAccessForGating: hasPremiumAccessForGating
        )

        // Then
        XCTAssertTrue(shouldPlaceAtBottom)
    }

    func testGivenNoUnlimitedAccessWhenOrderingSettingsThenPurchasesStayNearTop() {
        // Given
        let hasPremiumAccessForGating = false

        // When
        let shouldPlaceAtBottom = SettingsView.shouldPlacePurchasesSectionAtBottom(
            hasPremiumAccessForGating: hasPremiumAccessForGating
        )

        // Then
        XCTAssertFalse(shouldPlaceAtBottom)
    }
}

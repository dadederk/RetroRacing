//
//  AppIconCatalogTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 13/08/2026.
//

import XCTest
@testable import RetroRacingShared

final class AppIconCatalogTests: XCTestCase {
    func testGivenCatalogWhenReadingEntriesThenOrderAndCompatibilityDataAreStable() throws {
        XCTAssertEqual(AppIconCatalog.options.map(\.id), [
            .classic,
            .pocket,
            .lcd,
            .cartridge,
            .crt,
            .disc,
            .polygon,
            .retroCartridge,
            .retroVideoGame,
        ])
        XCTAssertEqual(Set(AppIconCatalog.options.map(\.id)).count, 9)
        XCTAssertEqual(Set(AppIconCatalog.alternateSystemIconNames).count, 8)
        XCTAssertEqual(AppIconCatalog.options.first?.systemIconName, nil)
        XCTAssertEqual(AppIconCatalog.options(in: .classic).count, 1)
        XCTAssertEqual(AppIconCatalog.options(in: .themes).count, 6)
        XCTAssertEqual(AppIconCatalog.options(in: .specialEditions).count, 2)

        XCTAssertEqual(
            AppIconCatalog.option(for: .retroCartridge)?.systemIconName,
            "RetroRapidGameCartridge"
        )
        XCTAssertEqual(
            AppIconCatalog.option(for: .retroVideoGame)?.systemIconName,
            "RetroRapidVideoGame"
        )
        XCTAssertEqual(AppIconCatalog.option(forSystemIconName: nil)?.id, .classic)
    }

    func testGivenEntitlementStatesWhenSelectingIconsThenExpectedActionsAreReturned() throws {
        let classic = try XCTUnwrap(AppIconCatalog.option(for: .classic))
        let pocket = try XCTUnwrap(AppIconCatalog.option(for: .pocket))

        XCTAssertEqual(action(for: classic, current: .classic), .none)
        XCTAssertEqual(action(for: classic, current: .pocket), .selectIcon)
        XCTAssertEqual(
            action(for: pocket, current: .classic, hasAccess: true, isResolved: false),
            .selectIcon
        )
        XCTAssertEqual(
            action(for: pocket, current: .classic, hasAccess: false, isResolved: false),
            .waitForEntitlement
        )
        XCTAssertEqual(
            action(for: pocket, current: .classic, hasAccess: false, isResolved: true),
            .presentPaywall
        )
        XCTAssertEqual(
            action(for: pocket, current: .pocket, hasAccess: false, isResolved: true),
            .none
        )
    }

    func testGivenDebugAndProductionStatesWhenResolvingFlagThenIsolationApplies() throws {
        let suiteName = "AppIconCatalogTests.featureFlag"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertTrue(DebugGameplayStorageKeys.areAlternateAppIconsEnabled(
            userDefaults: defaults,
            debugFeaturesAllowed: true
        ))

        defaults.set(false, forKey: DebugGameplayStorageKeys.alternateAppIconsEnabled)
        XCTAssertFalse(DebugGameplayStorageKeys.areAlternateAppIconsEnabled(
            userDefaults: defaults,
            debugFeaturesAllowed: true
        ))

        defaults.set(true, forKey: DebugGameplayStorageKeys.alternateAppIconsEnabled)
        XCTAssertFalse(DebugGameplayStorageKeys.areAlternateAppIconsEnabled(
            userDefaults: defaults,
            debugFeaturesAllowed: false
        ))
    }

    @MainActor
    func testGivenProductionFlagWhenCallerAttemptsToEnableThenItRemainsDisabled() throws {
        let suiteName = "AppIconCatalogTests.productionFeatureFlag"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: DebugGameplayStorageKeys.alternateAppIconsEnabled)
        let featureFlag = UserDefaultsAppIconFeatureFlag(
            userDefaults: defaults,
            isConfigurationAllowed: false
        )

        featureFlag.setEnabled(true)

        XCTAssertFalse(featureFlag.isEnabled)
    }

    private func action(
        for option: AppIconOption,
        current: AppIconID?,
        hasAccess: Bool = false,
        isResolved: Bool = true
    ) -> AppIconSelectionAction {
        AppIconSelectionPolicy.action(
            option: option,
            currentIconID: current,
            hasUnlimitedAccessForGating: hasAccess,
            hasResolvedInitialEntitlements: isResolved
        )
    }
}

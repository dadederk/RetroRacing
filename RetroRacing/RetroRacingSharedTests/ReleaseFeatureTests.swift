//
//  ReleaseFeatureTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 06/09/2026.
//

import XCTest
@testable import RetroRacingShared

@MainActor
final class ReleaseFeatureTests: XCTestCase {
    func testGivenFreshInstallWhenResolvingShippingCatalogsThenExpandedThemesUsePlatformAccessPolicy() throws {
        // Given
        for platform in [ThemeCatalogPlatform.iPhone, .iPad, .macOS, .watchOS] {
            let defaults = try makeDefaults()
            // When
            let store = ReleaseFeatureStore(platform: platform, userDefaults: defaults, allowsOverrides: true)
            let configuration = store.themeConfiguration
            // Then
            XCTAssertEqual(configuration.availableThemes.map(\.id), [.pocket, .lcd, .eightBit, .sixteenBit])
            switch platform {
            case .iPhone:
                XCTAssertEqual(configuration.availableThemes.filter(\.isPremium).map(\.id),
                               [.pocket, .eightBit, .sixteenBit])
                XCTAssertEqual(configuration.defaultThemeID, .lcd)
            case .iPad:
                XCTAssertEqual(configuration.availableThemes.filter(\.isPremium).map(\.id),
                               [.pocket, .lcd, .sixteenBit])
                XCTAssertEqual(configuration.defaultThemeID, .eightBit)
            case .macOS:
                XCTAssertEqual(configuration.availableThemes.filter(\.isPremium).map(\.id),
                               [.pocket, .lcd, .eightBit])
                XCTAssertEqual(configuration.defaultThemeID, .sixteenBit)
            case .watchOS:
                XCTAssertEqual(configuration.availableThemes.filter(\.isPremium).map(\.id), [])
                XCTAssertEqual(configuration.defaultThemeID, .pocket)
            default:
                XCTFail("Unexpected platform in shipping catalog test: \(platform)")
            }
            XCTAssertEqual(store.isEnabled(.sharePlay), platform != .watchOS)
        }
    }

    func testGivenShippingPocketWhenResolvingGalleryAccessThenFreeUsersSeeLockAndPaywall() throws {
        // Given
        for platform in [ThemeCatalogPlatform.iPhone, .iPad, .macOS] {
            let configuration = ThemePlatformConfig.configuration(for: platform, includesRetroThemes: false)
            let pocket = try XCTUnwrap(configuration.availableThemes.first { $0.id == .pocket })

            // When
            let action = ThemeGallerySelectionPolicy.action(
                previewID: pocket.id, currentThemeID: configuration.defaultThemeID,
                isThemePremium: pocket.isPremium, hasUnlimitedAccess: false,
                hasResolvedInitialEntitlements: true
            )

            // Then
            XCTAssertEqual(action, .presentPaywall)
            XCTAssertEqual(action.galleryOptionState, .locked)
            XCTAssertEqual(ThemeGallerySelectionPolicy.action(
                previewID: pocket.id, currentThemeID: configuration.defaultThemeID,
                isThemePremium: pocket.isPremium, hasUnlimitedAccess: true,
                hasResolvedInitialEntitlements: true
            ), .selectTheme)
        }
    }

    func testGivenSavedOverridesWhenLaunchingReleaseThenCommittedDefaultsWin() throws {
        // Given
        let defaults = try makeDefaults()
        for feature in ReleaseFeature.allCases { defaults.set("disabled", forKey: feature.storageKey) }
        // When
        let store = ReleaseFeatureStore(platform: .iPad, userDefaults: defaults, allowsOverrides: false)
        store.setOverride(.enabled, for: .retroThemes)
        store.resetOverrides()
        // Then
        XCTAssertEqual(store.themeConfiguration.availableThemes.map(\.id), [.pocket, .lcd, .eightBit, .sixteenBit])
        XCTAssertTrue(store.isEnabled(.sharePlay))
        XCTAssertEqual(defaults.string(forKey: ReleaseFeature.retroThemes.storageKey), "disabled")
    }

    func testGivenDebugOverridesWhenResetAndRelaunchedThenProductionPreviewIsRestored() throws {
        // Given
        let defaults = try makeDefaults()
        let store = ReleaseFeatureStore(platform: .iPhone, userDefaults: defaults, allowsOverrides: true)
        store.setOverride(.enabled, for: .retroThemes)
        store.setOverride(.disabled, for: .sharePlay)
        // When
        let restored = ReleaseFeatureStore(platform: .iPhone, userDefaults: defaults, allowsOverrides: true)
        // Then
        XCTAssertTrue(restored.isEnabled(.retroThemes))
        XCTAssertFalse(restored.isEnabled(.sharePlay))
        restored.resetOverrides()
        XCTAssertEqual(restored.themeConfiguration.availableThemes.map(\.id), [.pocket, .lcd, .eightBit, .sixteenBit])
        XCTAssertTrue(restored.isEnabled(.sharePlay))
        XCTAssertNil(defaults.object(forKey: ReleaseFeature.retroThemes.storageKey))
    }

    func testGivenSelectionWhenDebugOverrideHidesThemesThenPreferenceSurvivesAndRestores() throws {
        // Given
        let defaults = try makeDefaults()
        defaults.set(ThemeID.eightBit.rawValue, forKey: ThemeManager.selectedThemeKey)
        let store = ReleaseFeatureStore(platform: .iPhone, userDefaults: defaults, allowsOverrides: true)
        store.setOverride(.disabled, for: .retroThemes)
        let manager = ThemeManager(configuration: .iPhone, userDefaults: defaults,
                                   hasPremiumAccess: true, releaseFeatures: store)
        // When / Then
        XCTAssertEqual(manager.currentTheme.id, .lcd)
        XCTAssertEqual(manager.selectedThemeID, .eightBit)
        store.setOverride(.enabled, for: .retroThemes)
        manager.refreshReleaseFeatures()
        XCTAssertEqual(manager.currentTheme.id, .eightBit)
        manager.syncPremiumAccess(false)
        XCTAssertEqual(manager.currentTheme.id, .lcd)
        manager.syncPremiumAccess(true)
        XCTAssertEqual(manager.currentTheme.id, .eightBit)
        store.resetOverrides()
        manager.refreshReleaseFeatures()
        XCTAssertEqual(manager.currentTheme.id, .eightBit)
        XCTAssertEqual(defaults.string(forKey: ThemeManager.selectedThemeKey), ThemeID.eightBit.rawValue)
    }

    func testGivenHiddenOrForgedThemeWhenSelectingThenCatalogPolicyRejectsIt() throws {
        // Given
        let defaults = try makeDefaults()
        let manager = ThemeManager(
            configuration: .configuration(for: .iPhone, includesRetroThemes: false),
            userDefaults: defaults,
            hasPremiumAccess: true
        )
        // When
        manager.setTheme(EightBitTheme(isPremium: false))
        // Then
        XCTAssertEqual(manager.currentTheme.id, .lcd)
        XCTAssertFalse(manager.isThemeAvailable(EightBitTheme(isPremium: false)))
        let futureManager = ThemeManager(
            configuration: .configuration(for: .iPhone, includesRetroThemes: true),
            userDefaults: defaults, hasPremiumAccess: false
        )
        futureManager.setTheme(EightBitTheme(isPremium: false))
        XCTAssertEqual(futureManager.currentTheme.id, .lcd)
    }

    func testGivenCaptureWithDeveloperOverridesWhenResolvingThemesThenReleaseDefaultsAreUsed() throws {
        // Given
        let defaults = try makeDefaults()
        defaults.set("enabled", forKey: ReleaseFeature.retroThemes.storageKey)
        // When
        let capture = ReleaseFeatureStore(platform: .macOS, userDefaults: defaults, allowsOverrides: false)
        // Then
        XCTAssertEqual(capture.themeConfiguration.defaultThemeID, .sixteenBit)
        XCTAssertEqual(ThemePlatformConfig.screenshotCapture(platform: "mac").defaultThemeID, .sixteenBit)
    }

    func testGivenNoExplicitThemeWhenPreviewChangesThenDefaultChangesWithoutPersistingAChoice() throws {
        // Given
        let defaults = try makeDefaults()
        let store = ReleaseFeatureStore(platform: .iPad, userDefaults: defaults, allowsOverrides: true)
        store.setOverride(.disabled, for: .retroThemes)
        let manager = ThemeManager(configuration: .iPad, userDefaults: defaults,
                                   hasPremiumAccess: false, releaseFeatures: store)
        // When
        store.resetOverrides()
        manager.refreshReleaseFeatures()
        // Then
        XCTAssertEqual(manager.currentTheme.id, .eightBit)
        XCTAssertNil(defaults.object(forKey: ThemeManager.selectedThemeKey))
        store.setOverride(.disabled, for: .retroThemes)
        manager.refreshReleaseFeatures()
        XCTAssertEqual(manager.currentTheme.id, .lcd)
    }

    func testGivenRequiredPlatformThemesWhenReleaseIgnoresOptOutThenCatalogRetainsThem() throws {
        // Given / When / Then
        for platform in [ThemeCatalogPlatform.tvOS, .visionOS] {
            let defaults = try makeDefaults()
            defaults.set("disabled", forKey: ReleaseFeature.discTheme.storageKey)
            defaults.set("disabled", forKey: ReleaseFeature.polygonTheme.storageKey)
            let store = ReleaseFeatureStore(platform: platform, userDefaults: defaults, allowsOverrides: false)
            XCTAssertTrue(store.isEnabled(.discTheme))
            XCTAssertTrue(store.themeConfiguration.availableThemes.contains { $0.id == .thirtyTwoBit })
            XCTAssertEqual(store.isEnabled(.polygonTheme), platform == .visionOS)
        }
    }

    private func makeDefaults() throws -> UserDefaults {
        let name = "ReleaseFeatureTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }
}

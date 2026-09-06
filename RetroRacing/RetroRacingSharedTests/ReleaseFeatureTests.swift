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
    func testGivenFreshInstallWhenResolvingShippingCatalogsThenBothOriginalThemesAreFree() throws {
        // Given
        for platform in [ThemeCatalogPlatform.iPhone, .iPad, .macOS, .watchOS] {
            let defaults = try makeDefaults()
            // When
            let store = ReleaseFeatureStore(platform: platform, userDefaults: defaults, allowsOverrides: true)
            let configuration = store.themeConfiguration
            // Then
            XCTAssertEqual(configuration.availableThemes.map(\.id), [.pocket, .lcd])
            XCTAssertTrue(configuration.availableThemes.allSatisfy { !$0.isPremium })
            XCTAssertEqual(configuration.defaultThemeID, platform == .watchOS ? .pocket : .lcd)
            XCTAssertFalse(store.isEnabled(.alternateIcons))
            XCTAssertEqual(store.isEnabled(.sharePlay), platform != .watchOS)
        }
    }

    func testGivenSavedOverridesWhenLaunchingReleaseThenCommittedDefaultsWin() throws {
        // Given
        let defaults = try makeDefaults()
        for feature in ReleaseFeature.allCases { defaults.set("enabled", forKey: feature.storageKey) }
        defaults.set("disabled", forKey: ReleaseFeature.sharePlay.storageKey)
        // When
        let store = ReleaseFeatureStore(platform: .iPad, userDefaults: defaults, allowsOverrides: false)
        store.setOverride(.enabled, for: .retroThemes)
        store.resetOverrides()
        // Then
        XCTAssertEqual(store.themeConfiguration.availableThemes.map(\.id), [.pocket, .lcd])
        XCTAssertFalse(store.isEnabled(.alternateIcons))
        XCTAssertTrue(store.isEnabled(.sharePlay))
        XCTAssertEqual(defaults.string(forKey: ReleaseFeature.retroThemes.storageKey), "enabled")
    }

    func testGivenDebugOverridesWhenResetAndRelaunchedThenProductionPreviewIsRestored() throws {
        // Given
        let defaults = try makeDefaults()
        let store = ReleaseFeatureStore(platform: .iPhone, userDefaults: defaults, allowsOverrides: true)
        store.setOverride(.enabled, for: .retroThemes)
        store.setOverride(.enabled, for: .alternateIcons)
        store.setOverride(.disabled, for: .sharePlay)
        // When
        let restored = ReleaseFeatureStore(platform: .iPhone, userDefaults: defaults, allowsOverrides: true)
        // Then
        XCTAssertTrue(restored.isEnabled(.retroThemes))
        XCTAssertTrue(restored.isEnabled(.alternateIcons))
        XCTAssertFalse(restored.isEnabled(.sharePlay))
        restored.resetOverrides()
        XCTAssertEqual(restored.themeConfiguration.availableThemes.map(\.id), [.pocket, .lcd])
        XCTAssertFalse(restored.isEnabled(.alternateIcons))
        XCTAssertTrue(restored.isEnabled(.sharePlay))
        XCTAssertNil(defaults.object(forKey: ReleaseFeature.retroThemes.storageKey))
    }

    func testGivenFutureSelectionWhenFeatureIsHiddenThenPreferenceSurvivesAndRestores() throws {
        // Given
        let defaults = try makeDefaults()
        defaults.set(ThemeID.eightBit.rawValue, forKey: ThemeManager.selectedThemeKey)
        let store = ReleaseFeatureStore(platform: .iPhone, userDefaults: defaults, allowsOverrides: true)
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
        XCTAssertEqual(manager.currentTheme.id, .lcd)
        XCTAssertEqual(defaults.string(forKey: ThemeManager.selectedThemeKey), ThemeID.eightBit.rawValue)
    }

    func testGivenHiddenOrForgedThemeWhenSelectingThenCatalogPolicyRejectsIt() throws {
        // Given
        let defaults = try makeDefaults()
        let manager = ThemeManager(configuration: .iPhone, userDefaults: defaults, hasPremiumAccess: true)
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

    func testGivenIconPreviewWhenResetThenServiceHidesGalleryWithoutChangingInstalledIcon() throws {
        // Given
        let defaults = try makeDefaults()
        let store = ReleaseFeatureStore(platform: .iPhone, userDefaults: defaults, allowsOverrides: true)
        let changer = PreviewAppIconChanger(supportsAlternateIcons: true)
        let service = AppIconService(changer: changer, featureFlag: ReleaseAppIconFeatureFlag(features: store),
                                     isGalleryPlatformEnabled: true)
        let original = service.currentIconID
        // When
        store.setOverride(.enabled, for: .alternateIcons)
        service.refreshFeatureFlag()
        // Then
        XCTAssertTrue(service.isGalleryAvailable)
        store.resetOverrides()
        service.refreshFeatureFlag()
        XCTAssertFalse(service.isGalleryAvailable)
        XCTAssertEqual(service.currentIconID, original)
    }

    func testGivenCaptureWithDeveloperOverridesWhenResolvingThemesThenReleaseDefaultsAreUsed() throws {
        // Given
        let defaults = try makeDefaults()
        defaults.set("enabled", forKey: ReleaseFeature.retroThemes.storageKey)
        // When
        let capture = ReleaseFeatureStore(platform: .macOS, userDefaults: defaults, allowsOverrides: false)
        // Then
        XCTAssertEqual(capture.themeConfiguration.defaultThemeID, .lcd)
        XCTAssertEqual(ThemePlatformConfig.screenshotCapture(platform: "mac").defaultThemeID, .lcd)
    }

    func testGivenNoExplicitThemeWhenPreviewChangesThenDefaultChangesWithoutPersistingAChoice() throws {
        // Given
        let defaults = try makeDefaults()
        let store = ReleaseFeatureStore(platform: .iPad, userDefaults: defaults, allowsOverrides: true)
        let manager = ThemeManager(configuration: .iPad, userDefaults: defaults,
                                   hasPremiumAccess: false, releaseFeatures: store)
        // When
        store.setOverride(.enabled, for: .retroThemes)
        manager.refreshReleaseFeatures()
        // Then
        XCTAssertEqual(manager.currentTheme.id, .eightBit)
        XCTAssertNil(defaults.object(forKey: ThemeManager.selectedThemeKey))
        store.resetOverrides()
        manager.refreshReleaseFeatures()
        XCTAssertEqual(manager.currentTheme.id, .lcd)
    }

    private func makeDefaults() throws -> UserDefaults {
        let name = "ReleaseFeatureTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }
}

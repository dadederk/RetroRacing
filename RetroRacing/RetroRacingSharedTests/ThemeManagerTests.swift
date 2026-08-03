//
//  ThemeManagerTests.swift
//  RetroRacingSharedTests
//

import Foundation
import SwiftUI
import XCTest
@testable import RetroRacingShared

private struct StubTheme: GameTheme {
    let id: ThemeID
    let name: String
    let isPremium: Bool

    init(id: String = "stub", name: String = "Stub", isPremium: Bool = false) {
        self.id = ThemeID(rawValue: id)
        self.name = name
        self.isPremium = isPremium
    }

    func backgroundColor(for state: GameState) -> Color { .clear }
    func gridLineColor() -> Color { .gray }
    func gridCellColor() -> Color { .white }
    func playerCarColor() -> Color { .blue }
    func rivalCarColor() -> Color { .red }
    func crashColor() -> Color { .orange }
    func textColor() -> Color { .primary }
    func cellBorderWidth() -> CGFloat { 1 }
    func cornerRadius() -> CGFloat { 0 }
}

@MainActor
final class ThemeManagerTests: XCTestCase {
    func testGivenNoStoredSelectionWhenInitializingThenConfiguredDefaultIsSelected() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.initial")
        defer { clean(defaults) }
        let configuration = makeConfiguration(defaultID: "a")

        // When
        let manager = ThemeManager(
            configuration: configuration,
            userDefaults: defaults,
            hasPremiumAccess: false
        )

        // Then
        XCTAssertTrue(manager.currentTheme.id == ThemeID(rawValue: "a"))
        XCTAssertTrue(manager.selectedThemeID == ThemeID(rawValue: "a"))
    }

    func testGivenPlatformThemeCatalogsWhenInspectingDefaultsThenAccessMatchesPlatformRules() {
        // Given
        let platforms: [ThemePlatformConfig] = [.iPhone, .iPad, .macOS, .tvOS, .watchOS]

        // When
        let themeCounts = platforms.map(\.availableThemes.count)

        // Then
        XCTAssertTrue(themeCounts.allSatisfy { $0 == 4 })
        assertThemeCatalog(
            .iPhone,
            defaultThemeID: .lcd,
            premiumThemeIDs: [.pocket, .eightBit, .sixteenBit]
        )
        assertThemeCatalog(
            .iPad,
            defaultThemeID: .eightBit,
            premiumThemeIDs: [.pocket, .lcd, .sixteenBit]
        )
        assertThemeCatalog(
            .macOS,
            defaultThemeID: .sixteenBit,
            premiumThemeIDs: [.pocket, .lcd, .eightBit]
        )
        assertThemeCatalog(
            .tvOS,
            defaultThemeID: .sixteenBit,
            premiumThemeIDs: [.pocket, .lcd, .eightBit]
        )
        assertThemeCatalog(
            .watchOS,
            defaultThemeID: .pocket,
            premiumThemeIDs: []
        )
    }

    func testGivenScreenshotCapturePlatformWhenResolvingCatalogThenExpectedEraIsDefault() {
        // Given
        let platforms = ["iphone", "ipad", "mac", "watch"]

        // When
        let defaults = platforms.map { ThemePlatformConfig.screenshotCapture(platform: $0).defaultThemeID }

        // Then
        XCTAssertTrue(defaults == [.lcd, .eightBit, .sixteenBit, .pocket])
        XCTAssertTrue(ThemePlatformConfig.screenshotCapture(platform: "iphone").defaultThemeID == .lcd)
        XCTAssertTrue(ThemePlatformConfig.screenshotCapture(platform: "ipad").defaultThemeID == .eightBit)
        XCTAssertTrue(ThemePlatformConfig.screenshotCapture(platform: "mac").defaultThemeID == .sixteenBit)
        XCTAssertTrue(ThemePlatformConfig.screenshotCapture(platform: "watch").defaultThemeID == .pocket)
    }

    func testGivenDuplicateCatalogIDsWhenConfiguringThenOrderIsUniqueAndDefaultIsPresent() {
        // Given
        let duplicate = StubTheme(id: "a", name: "Duplicate")

        // When
        let configuration = ThemePlatformConfig(
            defaultTheme: StubTheme(id: "fallback"),
            availableThemes: [StubTheme(id: "a"), duplicate, StubTheme(id: "b")]
        )

        // Then
        XCTAssertTrue(configuration.availableThemes.map(\.id) == [
            ThemeID(rawValue: "a"),
            ThemeID(rawValue: "b"),
            ThemeID(rawValue: "fallback"),
        ])
        XCTAssertTrue(configuration.defaultThemeID == ThemeID(rawValue: "fallback"))
    }

    func testGivenStoredPremiumSelectionWithoutAccessWhenInitializingThenSelectionIsPreserved() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.lockedStoredPremium")
        defaults.set("premium", forKey: "selectedThemeID")
        defer { clean(defaults) }
        let configuration = makeConfiguration(defaultID: "free", includesPremium: true)

        // When
        let manager = ThemeManager(
            configuration: configuration,
            userDefaults: defaults,
            hasPremiumAccess: false
        )

        // Then
        XCTAssertTrue(manager.currentTheme.id == ThemeID(rawValue: "free"))
        XCTAssertTrue(manager.selectedThemeID == ThemeID(rawValue: "premium"))
        XCTAssertTrue(defaults.string(forKey: "selectedThemeID") == "premium")
    }

    func testGivenStoredPremiumSelectionWhenAccessChangesThenThemeRevokesAndRestores() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.restorePremiumSelection")
        defaults.set("premium", forKey: "selectedThemeID")
        defer { clean(defaults) }
        let configuration = makeConfiguration(defaultID: "free", includesPremium: true)
        let manager = ThemeManager(
            configuration: configuration,
            userDefaults: defaults,
            hasPremiumAccess: true
        )
        XCTAssertTrue(manager.currentTheme.id == ThemeID(rawValue: "premium"))

        // When
        manager.syncPremiumAccess(false)

        // Then
        XCTAssertTrue(manager.currentTheme.id == ThemeID(rawValue: "free"))
        XCTAssertTrue(manager.selectedThemeID == ThemeID(rawValue: "premium"))

        // When
        manager.syncPremiumAccess(true)

        // Then
        XCTAssertTrue(manager.currentTheme.id == ThemeID(rawValue: "premium"))
        XCTAssertTrue(defaults.string(forKey: "selectedThemeID") == "premium")
    }

    func testGivenThemeSelectionWhenSettingThemeThenTypedSelectionAndRawStorageAreUpdated() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.setTheme")
        defer { clean(defaults) }
        let configuration = makeConfiguration(defaultID: "a")
        let manager = ThemeManager(
            configuration: configuration,
            userDefaults: defaults,
            hasPremiumAccess: false
        )
        let secondTheme = try XCTUnwrap(configuration.availableThemes.first {
            $0.id == ThemeID(rawValue: "b")
        })

        // When
        manager.setTheme(secondTheme)

        // Then
        XCTAssertTrue(manager.currentTheme.id == ThemeID(rawValue: "b"))
        XCTAssertTrue(manager.selectedThemeID == ThemeID(rawValue: "b"))
        XCTAssertTrue(defaults.string(forKey: "selectedThemeID") == "b")
    }

    func testGivenPremiumThemeWhenAccessIsAbsentThenSelectionIsRejected() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.premium")
        defer { clean(defaults) }
        let configuration = makeConfiguration(defaultID: "free", includesPremium: true)
        let manager = ThemeManager(
            configuration: configuration,
            userDefaults: defaults,
            hasPremiumAccess: false
        )
        let premium = try XCTUnwrap(configuration.availableThemes.first { $0.isPremium })

        // When
        manager.setTheme(premium)

        // Then
        XCTAssertTrue(manager.currentTheme.id == ThemeID(rawValue: "free"))
        XCTAssertTrue(manager.isThemeAvailable(premium) == false)
    }

    func testGivenLegacyUnlockStorageWhenInitializingThenLegacyKeyIsRemoved() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.legacyUnlock")
        defaults.set(["premium"], forKey: "unlockedThemes")
        defer { clean(defaults) }

        // When
        _ = ThemeManager(
            configuration: makeConfiguration(defaultID: "free", includesPremium: true),
            userDefaults: defaults,
            hasPremiumAccess: false
        )

        // Then
        XCTAssertTrue(defaults.object(forKey: "unlockedThemes") == nil)
    }

    func testGivenInvalidStoredIDWhenInitializingThenDefaultReplacesIt() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.invalidStoredID")
        defaults.set("missing", forKey: "selectedThemeID")
        defer { clean(defaults) }

        // When
        let manager = ThemeManager(
            configuration: makeConfiguration(defaultID: "free"),
            userDefaults: defaults,
            hasPremiumAccess: false
        )

        // Then
        XCTAssertTrue(manager.currentTheme.id == ThemeID(rawValue: "free"))
        XCTAssertTrue(manager.selectedThemeID == ThemeID(rawValue: "free"))
        XCTAssertTrue(defaults.string(forKey: "selectedThemeID") == "free")
    }

    private func makeConfiguration(
        defaultID: String,
        includesPremium: Bool = false
    ) -> ThemePlatformConfig {
        var themes: [any GameTheme] = [
            StubTheme(id: defaultID),
            StubTheme(id: defaultID == "a" ? "b" : "other"),
        ]
        if includesPremium {
            themes.append(StubTheme(id: "premium", isPremium: true))
        }
        return ThemePlatformConfig(
            defaultTheme: StubTheme(id: defaultID),
            availableThemes: themes
        )
    }

    private func assertThemeCatalog(
        _ configuration: ThemePlatformConfig,
        defaultThemeID: ThemeID,
        premiumThemeIDs: Set<ThemeID>
    ) {
        XCTAssertTrue(configuration.defaultThemeID == defaultThemeID)
        XCTAssertTrue(configuration.availableThemes.map(\.id) == [
            .pocket,
            .lcd,
            .eightBit,
            .sixteenBit,
        ])
        XCTAssertTrue(Set(configuration.availableThemes.filter(\.isPremium).map(\.id)) == premiumThemeIDs)
    }

    private func cleanDefaults(named name: String) throws -> UserDefaults {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        clean(defaults)
        return defaults
    }

    private func clean(_ defaults: UserDefaults) {
        defaults.removeObject(forKey: "selectedThemeID")
        defaults.removeObject(forKey: "unlockedThemes")
    }
}

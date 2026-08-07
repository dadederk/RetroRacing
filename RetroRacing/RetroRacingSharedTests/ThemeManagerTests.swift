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
        let establishedCatalogs: [ThemePlatformConfig] = [.iPhone, .iPad, .macOS, .watchOS]

        // When
        let establishedThemeCounts = establishedCatalogs.map(\.availableThemes.count)

        // Then
        XCTAssertTrue(establishedThemeCounts.allSatisfy { $0 == 4 })
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
            defaultThemeID: .thirtyTwoBit,
            premiumThemeIDs: [.pocket, .lcd, .eightBit, .sixteenBit],
            expectedThemeIDs: [.pocket, .lcd, .eightBit, .sixteenBit, .thirtyTwoBit]
        )
        assertThemeCatalog(
            .watchOS,
            defaultThemeID: .pocket,
            premiumThemeIDs: []
        )
        assertThemeCatalog(
            .visionOS,
            defaultThemeID: .sixtyFourBit,
            premiumThemeIDs: [.pocket, .lcd, .eightBit, .sixteenBit, .thirtyTwoBit],
            expectedThemeIDs: [.pocket, .lcd, .eightBit, .sixteenBit, .thirtyTwoBit, .sixtyFourBit]
        )
    }

    func testGivenExperimentalThemesWhenBuildingCatalogsThenDebugOnlyThemesAreFreeAndDefaultsRemainStable() {
        let experiments = ExperimentalThemeConfiguration(
            isThirtyTwoBitEnabled: true,
            isSixtyFourBitEnabled: true
        )

        assertThemeCatalog(
            .configuration(for: .iPhone, experimentalThemes: experiments),
            defaultThemeID: .lcd,
            premiumThemeIDs: [.pocket, .eightBit, .sixteenBit],
            expectedThemeIDs: [.pocket, .lcd, .eightBit, .sixteenBit, .thirtyTwoBit, .sixtyFourBit]
        )
        assertThemeCatalog(
            .configuration(for: .tvOS, experimentalThemes: experiments),
            defaultThemeID: .thirtyTwoBit,
            premiumThemeIDs: [.pocket, .lcd, .eightBit, .sixteenBit],
            expectedThemeIDs: [.pocket, .lcd, .eightBit, .sixteenBit, .thirtyTwoBit, .sixtyFourBit]
        )
        assertThemeCatalog(
            .configuration(for: .visionOS, experimentalThemes: experiments),
            defaultThemeID: .sixtyFourBit,
            premiumThemeIDs: [.pocket, .lcd, .eightBit, .sixteenBit, .thirtyTwoBit],
            expectedThemeIDs: [.pocket, .lcd, .eightBit, .sixteenBit, .thirtyTwoBit, .sixtyFourBit]
        )
    }

    func testGivenPlatformWhenInspectingExperimentalToggleVisibilityThenDefaultThemesStayHidden() {
        XCTAssertFalse(ThemeCatalogPlatform.tvOS.showsExperimentalToggle(for: .thirtyTwoBit))
        XCTAssertTrue(ThemeCatalogPlatform.tvOS.showsExperimentalToggle(for: .sixtyFourBit))
        XCTAssertFalse(ThemeCatalogPlatform.visionOS.showsExperimentalToggle(for: .thirtyTwoBit))
        XCTAssertFalse(ThemeCatalogPlatform.visionOS.showsExperimentalToggle(for: .sixtyFourBit))
        XCTAssertTrue(ThemeCatalogPlatform.iPhone.showsExperimentalToggle(for: .thirtyTwoBit))
        XCTAssertTrue(ThemeCatalogPlatform.iPhone.showsExperimentalToggle(for: .sixtyFourBit))
    }

    func testGivenVisionOSCatalogWhenPremiumAccessIsGrantedThenEveryThemeCanBeSelected() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.visionPremiumCatalog")
        defer { clean(defaults) }
        let manager = ThemeManager(
            configuration: .visionOS,
            userDefaults: defaults,
            hasPremiumAccess: false
        )
        let themeIDs = manager.availableThemes.map(\.id)

        XCTAssertEqual(manager.currentTheme.id, .sixtyFourBit)
        XCTAssertEqual(
            manager.availableThemes.filter(manager.isThemeAvailable).map(\.id),
            [.sixtyFourBit]
        )

        // When
        manager.syncPremiumAccess(true)

        // Then
        XCTAssertEqual(themeIDs, [
            .pocket,
            .lcd,
            .eightBit,
            .sixteenBit,
            .thirtyTwoBit,
            .sixtyFourBit,
        ])
        for theme in manager.availableThemes {
            XCTAssertTrue(manager.isThemeAvailable(theme))
            manager.setTheme(theme)
            XCTAssertEqual(manager.currentTheme.id, theme.id)
        }
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
        XCTAssertTrue(ThemePlatformConfig.screenshotCapture(platform: "tv").defaultThemeID == .thirtyTwoBit)
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

    func testGivenTvOSThemeManagerWhenSixtyFourBitIsEnabledThenItJoinsTheSelectableCatalog() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.experimentalTvOS")
        defaults.set(ThemeID.thirtyTwoBit.rawValue, forKey: ThemeManager.selectedThemeKey)
        defer { clean(defaults) }
        let manager = ThemeManager(
            configuration: .tvOS,
            userDefaults: defaults,
            hasPremiumAccess: false
        )

        // When
        manager.applyExperimentalThemes(ExperimentalThemeConfiguration(
            isThirtyTwoBitEnabled: false,
            isSixtyFourBitEnabled: true
        ))

        // Then
        XCTAssertEqual(manager.currentTheme.id, .thirtyTwoBit)
        XCTAssertEqual(manager.selectedThemeID, .thirtyTwoBit)
        XCTAssertEqual(manager.availableThemes.map(\.id), [
            .pocket,
            .lcd,
            .eightBit,
            .sixteenBit,
            .thirtyTwoBit,
            .sixtyFourBit,
        ])
        XCTAssertEqual(defaults.string(forKey: "selectedThemeID"), ThemeID.thirtyTwoBit.rawValue)
    }

    func testGivenExperimentalThemeSelectedWhenItIsDisabledThenPlatformDefaultIsRestored() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.stableTvOS")
        defer { clean(defaults) }
        let manager = ThemeManager(
            configuration: ThemePlatformConfig.configuration(
                for: .iPhone,
                experimentalThemes: ExperimentalThemeConfiguration(
                    isThirtyTwoBitEnabled: true,
                    isSixtyFourBitEnabled: false
                )
            ),
            userDefaults: defaults,
            hasPremiumAccess: false
        )
        let experimentalTheme = try XCTUnwrap(
            manager.availableThemes.first { $0.id == .thirtyTwoBit }
        )
        manager.setTheme(experimentalTheme)

        // When
        manager.applyExperimentalThemes(.disabled)

        // Then
        XCTAssertEqual(manager.currentTheme.id, .lcd)
        XCTAssertEqual(manager.selectedThemeID, .lcd)
        XCTAssertFalse(manager.availableThemes.contains { $0.id == .thirtyTwoBit })
        XCTAssertEqual(defaults.string(forKey: "selectedThemeID"), ThemeID.lcd.rawValue)
    }

    func testGivenLocalThemeOptOutsWhenDebugFeaturesAreDisallowedThenPlatformDefaultsWin() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.experimentalFlagIsolation")
        defaults.set(false, forKey: DebugGameplayStorageKeys.experimentalThirtyTwoBitThemeEnabled)
        defaults.set(false, forKey: DebugGameplayStorageKeys.experimentalSixtyFourBitThemeEnabled)
        defer { clean(defaults) }

        // When / Then
        XCTAssertTrue(
            DebugGameplayStorageKeys.isExperimentalThirtyTwoBitThemeEnabled(
                userDefaults: defaults,
                debugFeaturesAllowed: false,
                platform: .tvOS
            )
        )
        XCTAssertFalse(
            DebugGameplayStorageKeys.isExperimentalThirtyTwoBitThemeEnabled(
                userDefaults: defaults,
                debugFeaturesAllowed: true,
                platform: .tvOS
            )
        )
        XCTAssertTrue(
            DebugGameplayStorageKeys.isExperimentalSixtyFourBitThemeEnabled(
                userDefaults: defaults,
                debugFeaturesAllowed: false,
                platform: .visionOS
            )
        )
        XCTAssertFalse(
            DebugGameplayStorageKeys.isExperimentalSixtyFourBitThemeEnabled(
                userDefaults: defaults,
                debugFeaturesAllowed: true,
                platform: .visionOS
            )
        )
    }

    func testGivenNoExperimentalThemeFlagsWhenDebugFeaturesAreAllowedThenOnlyPlatformDefaultsAreOn() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.experimentalFlagDefault")
        defer { clean(defaults) }

        // When
        let isEnabled = DebugGameplayStorageKeys.isExperimentalThirtyTwoBitThemeEnabled(
            userDefaults: defaults,
            debugFeaturesAllowed: true,
            platform: .tvOS
        )
        let isSixtyFourBitEnabled = DebugGameplayStorageKeys.isExperimentalSixtyFourBitThemeEnabled(
            userDefaults: defaults,
            debugFeaturesAllowed: true,
            platform: .visionOS
        )
        let isThirtyTwoBitEnabledOnIPhone = DebugGameplayStorageKeys.isExperimentalThirtyTwoBitThemeEnabled(
            userDefaults: defaults,
            debugFeaturesAllowed: true,
            platform: .iPhone
        )
        let isSixtyFourBitEnabledOnIPhone = DebugGameplayStorageKeys.isExperimentalSixtyFourBitThemeEnabled(
            userDefaults: defaults,
            debugFeaturesAllowed: true,
            platform: .iPhone
        )

        // Then
        XCTAssertTrue(isEnabled)
        XCTAssertTrue(isSixtyFourBitEnabled)
        XCTAssertFalse(isThirtyTwoBitEnabledOnIPhone)
        XCTAssertFalse(isSixtyFourBitEnabledOnIPhone)
    }

    func testGivenExperimentalThemeFlagsDisabledWhenDebugFeaturesAreAllowedThenFlagsRemainOff() throws {
        // Given
        let defaults = try cleanDefaults(named: "ThemeManagerTests.experimentalFlagDisabled")
        defaults.set(false, forKey: DebugGameplayStorageKeys.experimentalThirtyTwoBitThemeEnabled)
        defaults.set(false, forKey: DebugGameplayStorageKeys.experimentalSixtyFourBitThemeEnabled)
        defer { clean(defaults) }

        // When
        let isEnabled = DebugGameplayStorageKeys.isExperimentalThirtyTwoBitThemeEnabled(
            userDefaults: defaults,
            debugFeaturesAllowed: true,
            platform: .tvOS
        )
        let isSixtyFourBitEnabled = DebugGameplayStorageKeys.isExperimentalSixtyFourBitThemeEnabled(
            userDefaults: defaults,
            debugFeaturesAllowed: true,
            platform: .visionOS
        )

        // Then
        XCTAssertFalse(isEnabled)
        XCTAssertFalse(isSixtyFourBitEnabled)
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
        premiumThemeIDs: Set<ThemeID>,
        expectedThemeIDs: [ThemeID] = [.pocket, .lcd, .eightBit, .sixteenBit]
    ) {
        XCTAssertTrue(configuration.defaultThemeID == defaultThemeID)
        XCTAssertTrue(configuration.availableThemes.map(\.id) == expectedThemeIDs)
        XCTAssertTrue(Set(configuration.availableThemes.filter(\.isPremium).map(\.id)) == premiumThemeIDs)
    }

    private func cleanDefaults(named name: String) throws -> UserDefaults {
        let isolatedName = "\(name).\(ProcessInfo.processInfo.processIdentifier)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: isolatedName))
        clean(defaults)
        return defaults
    }

    private func clean(_ defaults: UserDefaults) {
        defaults.removeObject(forKey: "selectedThemeID")
        defaults.removeObject(forKey: "unlockedThemes")
        defaults.removeObject(forKey: DebugGameplayStorageKeys.experimentalThirtyTwoBitThemeEnabled)
        defaults.removeObject(forKey: DebugGameplayStorageKeys.experimentalSixtyFourBitThemeEnabled)
    }
}

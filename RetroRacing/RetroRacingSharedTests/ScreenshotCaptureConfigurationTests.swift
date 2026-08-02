//
//  ScreenshotCaptureConfigurationTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 23/07/2026.
//

import XCTest
import SwiftUI
import SpriteKit
@testable import RetroRacingShared

final class ScreenshotCaptureConfigurationTests: XCTestCase {
    func testGivenCaptureEnvironmentKeysWhenComparedToAutomationPlanThenTheyMatch() {
        // Keep in sync with Scripts/ScreenshotCapturePlan and UITest ScreenshotCaptureHelper constants.
        XCTAssertEqual(ScreenshotCaptureIdentifiers.captureEnabledKey, "RETRORAPID_SCREENSHOT_CAPTURE")
        XCTAssertEqual(ScreenshotCaptureIdentifiers.slideIndexKey, "RETRORAPID_SCREENSHOT_SLIDE")
        XCTAssertEqual(ScreenshotCaptureIdentifiers.stagingDirectoryKey, "RETRORAPID_SCREENSHOT_STAGING")
        XCTAssertEqual(ScreenshotCaptureIdentifiers.fileExtensionKey, "RETRORAPID_SCREENSHOT_FILE_EXTENSION")
        XCTAssertEqual(ScreenshotCaptureIdentifiers.platformKey, "RETRORAPID_SCREENSHOT_PLATFORM")
        XCTAssertEqual(ScreenshotCaptureIdentifiers.appearanceKey, "RETRORAPID_SCREENSHOT_APPEARANCE")
        XCTAssertEqual(ScreenshotCaptureIdentifiers.readinessIdentifier(slideIndex: 3), "screenshot-ready-slide-3")
    }

    func testGivenAppStoreLocalesWhenMappingToInAppLanguageThenUsesExpectedIdentifiers() {
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.inAppLanguageIdentifier(for: "de-DE"), "de")
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.inAppLanguageIdentifier(for: "en-US"), "en")
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.inAppLanguageIdentifier(for: "en-GB"), "en-GB")
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.inAppLanguageIdentifier(for: "es-MX"), "es")
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.inAppLanguageIdentifier(for: "ja"), "ja")
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.inAppLanguageIdentifier(for: "pt-BR"), "pt-BR")
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.inAppLanguageIdentifier(for: "pt-PT"), "pt-PT")
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.inAppLanguageIdentifier(for: "zh-Hant"), "zh-Hant")
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.inAppLanguageIdentifier(for: "zh-Hans"), "zh-Hans")
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.inAppLanguageIdentifier(for: "fr-CA"), "fr-CA")
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.inAppLanguageIdentifier(for: "fr-FR"), "fr")
    }

    func testGivenLanguageListWhenParsingCaptureLocaleThenStripsParentheses() {
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.parseLanguageList("(de)"), ["de"])
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.parseLanguageList("(en-GB)"), ["en-GB"])
        XCTAssertEqual(ScreenshotCaptureLocaleCatalog.normalizedLocaleIdentifier("nl_NL"), "nl-NL")
    }

    func testGivenCaptureLanguageArgumentsWhenBuildingLocaleThenUsesRegionIdentifier() {
        let german = ScreenshotCaptureLocaleCatalog.locale(
            languageList: "(de)",
            localeIdentifier: "de_DE"
        )
        let dutch = ScreenshotCaptureLocaleCatalog.locale(
            languageList: "(nl)",
            localeIdentifier: "nl_NL"
        )
        XCTAssertEqual(german?.language.languageCode?.identifier, "de")
        XCTAssertEqual(dutch?.language.languageCode?.identifier, "nl")
        XCTAssertTrue(german?.identifier.contains("DE") == true || german?.identifier.contains("de") == true)
        XCTAssertTrue(dutch?.identifier.contains("NL") == true || dutch?.identifier.contains("nl") == true)
    }

    func testGivenCaptureLocaleWhenAppliedThenLanguageDefaultsAreVolatileOnly() throws {
        let suiteName = "ScreenshotCaptureLocaleCatalogTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            userDefaults.removeVolatileDomain(forName: UserDefaults.argumentDomain)
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        ScreenshotCaptureLocaleCatalog.applyCaptureLocale(
            languageList: "(fr)",
            localeIdentifier: "fr_FR",
            userDefaults: userDefaults
        )

        let argumentDomain = userDefaults.volatileDomain(forName: UserDefaults.argumentDomain)
        XCTAssertEqual(argumentDomain["AppleLanguages"] as? [String], ["fr"])
        XCTAssertEqual(argumentDomain["AppleLocale"] as? String, "fr-FR")
        XCTAssertNil(userDefaults.persistentDomain(forName: suiteName)?["AppleLanguages"])
        XCTAssertNil(userDefaults.persistentDomain(forName: suiteName)?["AppleLocale"])
    }

    func testGivenLegacyPersistedCaptureLocaleWhenCaptureIsInactiveThenCleanupRemovesIt() throws {
        #if DEBUG
        let suiteName = "ScreenshotCaptureLocaleCatalogTests.\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        userDefaults.set(["fr"], forKey: "AppleLanguages")
        userDefaults.set("fr-FR", forKey: "AppleLocale")

        ScreenshotCaptureLocaleCatalog.removePersistedCaptureLocaleIfNeeded(
            userDefaults: userDefaults,
            isCaptureModeEnabled: false,
            hasLaunchLocaleArgument: false
        )

        XCTAssertNil(userDefaults.persistentDomain(forName: suiteName)?["AppleLanguages"])
        XCTAssertNil(userDefaults.persistentDomain(forName: suiteName)?["AppleLocale"])
        #endif
    }

    func testGivenScreenshotAppearanceWhenReadingDefaultThenIsLight() {
        XCTAssertEqual(ScreenshotCaptureAppearance.default, .light)
        XCTAssertEqual(ScreenshotCaptureAppearance.light.colorScheme, .light)
        XCTAssertEqual(ScreenshotCaptureAppearance.dark.colorScheme, .dark)
    }

    func testGivenMacLandscapeWindowConfigurationWhenReadingSizeThenMatchesScreenshotStudioBaseCapture() {
        XCTAssertEqual(ScreenshotCaptureWindowConfiguration.macLandscapeContentSize.width, 1012)
        XCTAssertEqual(ScreenshotCaptureWindowConfiguration.macLandscapeContentSize.height, 784)
    }

    func testGivenSlideFixturesWhenReadingRoutesThenMatchesStoryboard() {
        XCTAssertEqual(ScreenshotSlideFixture.hookGameplay.route, .gameplay)
        XCTAssertEqual(ScreenshotSlideFixture.fixture(for: 2)?.route, .gameOver)
        XCTAssertEqual(ScreenshotSlideFixture.fixture(for: 3)?.route, .settings(.accessibility))
        XCTAssertEqual(ScreenshotSlideFixture.fixture(for: 4)?.usesSharePlayWaitingOverlay, true)
        XCTAssertEqual(ScreenshotSlideFixture.fixture(for: 4, platform: "mac")?.route, .gameplay)
        XCTAssertEqual(ScreenshotSlideFixture.fixture(for: 5)?.route, .gameplay)
        XCTAssertEqual(ScreenshotSlideFixture.fixture(for: 6)?.route, .settings(.customize))
        XCTAssertTrue(ScreenshotSlideFixture.pocketGameplay.usesPocketTheme)
        XCTAssertTrue(ScreenshotSlideFixture.accessibilitySettings.presentsSettingsSheet)
        XCTAssertTrue(ScreenshotSlideFixture.gameOver.presentsGameOverSheet)
        XCTAssertEqual(ScreenshotSlideFixture.fixture(for: 8)?.route, .achievementUnlock)
        XCTAssertEqual(ScreenshotSlideFixture.fixture(for: 9)?.route, .menu)
        XCTAssertEqual(ScreenshotFixtureCatalog.slideCount(for: "iphone"), 10)
        XCTAssertEqual(ScreenshotFixtureCatalog.slideCount(for: "mac"), 9)
        XCTAssertEqual(
            ScreenshotSlideFixture.accessibilitySettings.gameplayBackgroundLayout.score,
            GameScreenshotLayout.hookGameplay.score
        )
        XCTAssertEqual(
            ScreenshotSlideFixture.gameOver.gameplayBackgroundLayout.score,
            ScreenshotFixtureCatalog.gameOverRunScore
        )
        XCTAssertEqual(
            ScreenshotSlideFixture.gameOver.gameplayBackgroundLayout.score,
            GameScreenshotLayout.gameOverBackground.score
        )
    }

    func testGivenWatchSlideFixturesWhenReadingRoutesThenMatchesStoryboard() {
        XCTAssertEqual(WatchScreenshotSlideFixture.hookGameplay.route, .gameplay)
        XCTAssertEqual(WatchScreenshotSlideFixture.menu.route, .menu)
        XCTAssertEqual(WatchScreenshotSlideFixture.actionGameplay.route, .gameplay)
        XCTAssertEqual(WatchScreenshotSlideFixture.settings.route, .settings)
        XCTAssertEqual(WatchScreenshotSlideFixture.hookGameplay.layout?.score, GameScreenshotLayout.hookGameplay.score)
        XCTAssertEqual(WatchScreenshotSlideFixture.actionGameplay.layout?.score, GameScreenshotLayout.actionGameplay.score)
        XCTAssertNil(WatchScreenshotSlideFixture.menu.layout)
        XCTAssertTrue(WatchScreenshotSlideFixture.pocketGameplay.usesPocketTheme)
        XCTAssertTrue(WatchScreenshotSlideFixture.settings.presentsSettingsSheet)
        XCTAssertEqual(WatchScreenshotSlideFixture.slideCount, 5)
    }

    func testGivenScreenshotCapturePreferencesWhenReadingGameplayDefaultsThenBigCarsStayOff() {
        XCTAssertFalse(ScreenshotCapturePreferences.gameplayBigCarsEnabled)
    }

    func testGivenFixtureCatalogWhenReadingGameOverValuesThenMatchesScreenshotStory() {
        XCTAssertEqual(ScreenshotFixtureCatalog.gameOverRunScore, 274)
        XCTAssertEqual(ScreenshotFixtureCatalog.gameOverPreviousBestScore, 251)
        XCTAssertEqual(ScreenshotFixtureCatalog.rivalFriendDisplayName, "John Appleseed")
        XCTAssertEqual(ScreenshotFixtureCatalog.rivalFriendAheadSummary.score, 285)
    }

    func testGivenActionLayoutWhenReadingGridThenShowsCrashInPlayerRowWithoutPlayerCar() {
        let layout = GameScreenshotLayout.actionGameplay
        XCTAssertEqual(layout.gridState.grid[2][2], GridState.CellState.Car)
        XCTAssertEqual(layout.gridState.grid[4], [.Empty, .Empty, .Crash])
        XCTAssertTrue(layout.speedIncreaseImminent)
        XCTAssertEqual(layout.safetyMarkerRows, [1, 2])
    }

    func testGivenActionLayoutWhenApplyingToSceneThenRendersFinishLine() {
        let loader = PlatformFactories.makeImageLoader()
        let scene = GameScene.scene(
            size: CGSize(width: 300, height: 300),
            difficulty: .rapid,
            theme: LCDTheme(),
            imageLoader: loader
        )
        scene.applyScreenshotLayout(.actionGameplay)

        let lapMarkers = scene.lineOverlayNodes.filter { $0.name == "lap_marker_line" }
        XCTAssertEqual(lapMarkers.count, 1)
    }

    func testGivenActionLayoutWhenApplyingToSceneThenCrashSpriteIsFullyOpaque() {
        let loader = PlatformFactories.makeImageLoader()
        let scene = GameScene.scene(
            size: CGSize(width: 300, height: 300),
            difficulty: .rapid,
            theme: LCDTheme(),
            imageLoader: loader
        )
        scene.applyScreenshotLayout(.actionGameplay)

        let crashSprites = scene.spritesForGivenState.filter { $0.name == "crash" }
        XCTAssertEqual(crashSprites.count, 1)
        XCTAssertEqual(crashSprites[0].alpha, 1.0)
        XCTAssertFalse(crashSprites[0].hasActions())
    }

    func testGivenFriendMarkerLayoutWhenReadingMilestonesThenUsesJohnAppleseed() {
        let layout = GameScreenshotLayout.friendMarkerGameplay()
        XCTAssertEqual(layout.upcomingMilestones.first?.displayName, "John Appleseed")
        XCTAssertEqual(
            layout.upcomingMilestones.first?.targetScore,
            ScreenshotFixtureCatalog.friendMarkerTargetScore
        )
        XCTAssertNotNil(ScreenshotFixtureAssets.johnAppleseedAvatarPNGData)
    }

    func testGivenFriendMarkerLayoutWhenResolvingMarkerPositionThenTargetsCenterCarOneRowAbovePlayer() throws {
        let loader = PlatformFactories.makeImageLoader()
        let scene = GameScene.scene(
            size: CGSize(width: 300, height: 300),
            difficulty: .rapid,
            theme: LCDTheme(),
            imageLoader: loader
        )
        scene.applyScreenshotLayout(GameScreenshotLayout.friendMarkerGameplay())

        let position = try XCTUnwrap(
            scene.upcomingMilestoneCarPosition(
                targetScore: ScreenshotFixtureCatalog.friendMarkerTargetScore,
                currentScore: ScreenshotFixtureCatalog.friendMarkerCurrentScore
            )
        )
        XCTAssertEqual(position.row, 3)
        XCTAssertEqual(position.column, 1)

        let marker = scene.children.first(where: { $0.name == "friend_milestone_badge" })
        XCTAssertNotNil(marker)
    }

    func testApplyScreenshotLayoutBeforeScenePresentationBuildsGridWithoutCrashing() {
        let loader = PlatformFactories.makeImageLoader()
        let scene = GameScene.scene(
            size: CGSize(width: 300, height: 300),
            difficulty: .rapid,
            theme: LCDTheme(),
            imageLoader: loader
        )

        scene.applyScreenshotLayout(.hookGameplay)

        XCTAssertEqual(scene.gameState.score, ScreenshotFixtureCatalog.hookGameplayScore)
        XCTAssertEqual(scene.gameState.lives, 3)
        XCTAssertTrue(scene.gameState.isPaused)
    }

    func testGivenBigCarsEnabledWhenReApplyingCapturePreferencesThenBigCarsTurnOff() {
        let loader = PlatformFactories.makeImageLoader()
        let scene = GameScene.scene(
            size: CGSize(width: 300, height: 300),
            difficulty: .rapid,
            theme: LCDTheme(),
            imageLoader: loader
        )
        scene.setBigRivalCarsEnabled(true)
        scene.applyScreenshotLayout(.hookGameplay)
        scene.setBigRivalCarsEnabled(ScreenshotCapturePreferences.gameplayBigCarsEnabled)

        XCTAssertFalse(scene.bigRivalCarsEnabled)
    }
}

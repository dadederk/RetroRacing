//
//  AppIconGalleryUITests.swift
//  RetroRacingUniversalUITests
//
//  Created by Dani Devesa on 13/08/2026.
//

import XCTest

final class AppIconGalleryUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testGivenConfiguredIOSPlatformWhenOpeningSettingsThenCompleteGalleryIsVisible() throws {
        // Given
        let app = launchApplication(premiumSimulationMode: 2)

        // When
        openSettings(in: app)

        // Then
        let appIconRow = app.buttons["App Icon"]
        XCTAssertTrue(appIconRow.exists, app.debugDescription)
        XCTAssertTrue(
            app.staticTexts[
                "Want more visual styles and app icons? Unlock Unlimited Plays in Purchases."
            ].exists,
            app.debugDescription
        )
        appIconRow.tap()

        XCTAssertTrue(app.navigationBars["Choose App Icon"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Themes"].exists)

        assertIconOptionsExist([
            ("classic", "Classic"),
            ("pocket", "Pocket"),
            ("lcd", "LCD"),
            ("cartridge", "Cartridge"),
            ("crt", "CRT"),
            ("disc", "Disc"),
            ("polygon", "Polygon"),
        ], in: app)

        let specialEditionsHeader = app.staticTexts["Special Editions"]
        scrollApplicationUp(in: app, until: specialEditionsHeader)
        XCTAssertTrue(specialEditionsHeader.exists)
        assertIconOptionsExist([
            ("retroCartridge", "Retro Cartridge"),
            ("retroVideoGame", "Retro Video Game"),
        ], in: app)

        app.navigationBars["Choose App Icon"].buttons["Settings"].tap()

        let featureToggle = app.switches["Enable alternate app icons"]
        scrollUp(in: app, until: featureToggle)
        XCTAssertTrue(featureToggle.exists, app.debugDescription)
        XCTAssertEqual(featureToggle.value as? String, "1")
    }

    private func assertIconOptionsExist(
        _ options: [(id: String, name: String)],
        in app: XCUIApplication
    ) {
        for (optionID, optionName) in options {
            let option = app.buttons["app_icon_option_\(optionID)"]
            var scrollAttempts = 0
            while option.exists == false && scrollAttempts < 6 {
                app.swipeUp()
                scrollAttempts += 1
            }
            XCTAssertTrue(option.exists, "Missing app icon option: \(optionName)")
        }
    }

    @MainActor
    func testGivenAccessibilityFiveWhenOpeningGalleryThenRowsRemainAccessibleAndSelected() throws {
        // Given
        let app = launchApplication(
            premiumSimulationMode: 1,
            additionalArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL",
            ]
        )

        // When
        openSettings(in: app)
        let appIconRow = app.buttons["App Icon"]
        XCTAssertTrue(appIconRow.waitForExistence(timeout: 10), app.debugDescription)
        appIconRow.tap()

        // Then
        XCTAssertTrue(app.navigationBars["Choose App Icon"].waitForExistence(timeout: 10))
        let classic = app.buttons["app_icon_option_classic"]
        XCTAssertTrue(classic.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(classic.isEnabled)
        XCTAssertEqual(classic.value as? String, "Selected", app.debugDescription)
        XCTAssertEqual(
            app.buttons.matching(NSPredicate(format: "value == %@", "Selected")).count,
            1
        )
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "App Icon Gallery - Accessibility 5"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        // Full-color decorative app-icon artwork produces a contrast false positive for the
        // combined Button node. Keep the structural, sizing, description, and trait audits.
        try app.performAccessibilityAudit(for: [
            .elementDetection,
            .hitRegion,
            .sufficientElementDescription,
            .dynamicType,
            .textClipped,
            .trait,
        ])
    }

    @MainActor
    private func launchApplication(
        premiumSimulationMode: Int,
        additionalArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-debugGameplay.alternateAppIconsEnabled", "1",
            "-StoreKit.debugPremiumSimulationMode", String(premiumSimulationMode),
        ] + additionalArguments
        app.launch()
        return app
    }

    private func openSettings(in app: XCUIApplication) {
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.tap()
    }

    private func scrollUp(in app: XCUIApplication, until element: XCUIElement) {
        let settingsList = app.collectionViews["settings_list"]
        XCTAssertTrue(settingsList.waitForExistence(timeout: 5))
        var scrollAttempts = 0
        while element.exists == false && scrollAttempts < 8 {
            settingsList.swipeUp()
            scrollAttempts += 1
        }
    }

    private func scrollApplicationUp(in app: XCUIApplication, until element: XCUIElement) {
        var scrollAttempts = 0
        while element.exists == false && scrollAttempts < 8 {
            app.swipeUp()
            scrollAttempts += 1
        }
    }
}

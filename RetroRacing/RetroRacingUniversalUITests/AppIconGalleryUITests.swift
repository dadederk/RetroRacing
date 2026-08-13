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
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-debugGameplay.alternateAppIconsEnabled", "1",
        ]

        // When
        app.launch()

        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.tap()

        // Then
        let appIconRow = app.buttons["App Icon"]
        XCTAssertTrue(appIconRow.exists, app.debugDescription)
        appIconRow.tap()

        XCTAssertTrue(app.navigationBars["Choose App Icon"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Themes"].exists)

        for optionName in [
            "Classic",
            "Pocket",
            "LCD",
            "Cartridge",
            "CRT",
            "Disc",
            "Polygon",
            "Retro Cartridge",
            "Retro Video Game",
        ] {
            let option = app.buttons[optionName]
            var scrollAttempts = 0
            while option.exists == false && scrollAttempts < 6 {
                app.swipeUp()
                scrollAttempts += 1
            }
            XCTAssertTrue(option.exists, "Missing app icon option: \(optionName)")
        }

        XCTAssertTrue(app.staticTexts["Special Editions"].exists)

        app.navigationBars["Choose App Icon"].buttons["Settings"].tap()

        let featureToggle = app.switches["Enable alternate app icons"]
        scrollUp(in: app, until: featureToggle)
        XCTAssertTrue(featureToggle.exists, app.debugDescription)
        XCTAssertEqual(featureToggle.value as? String, "1")
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
}

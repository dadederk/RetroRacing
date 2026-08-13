//
//  FontSettingsUITests.swift
//  RetroRacingUniversalUITests
//
//  Created by Dani Devesa on 13/08/2026.
//

import XCTest

final class FontSettingsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEveryFontCanBeSelectedAndFinalSelectionPersists() throws {
        let app = launchApplication()
        openFontSettings(in: app)

        for identifier in [
            "font_selection_custom",
            "font_selection_system",
            "font_selection_systemMonospaced",
            "font_selection_openDyslexic",
            "font_selection_atkinsonHyperlegible",
            "font_selection_lexend",
        ] {
            let row = app.buttons[identifier]
            scroll(in: app, until: row)
            XCTAssertTrue(row.isEnabled, "Expected bundled font row to be selectable: \(identifier)")
            row.tap()
            XCTAssertEqual(row.value as? String, "Selected")
        }

        app.terminate()
        app.launch()
        openFontSettings(in: app)

        let persistedRow = app.buttons["font_selection_lexend"]
        scroll(in: app, until: persistedRow)
        XCTAssertEqual(persistedRow.value as? String, "Selected")
    }

    @MainActor
    func testFontSettingsAtAccessibilityFivePassesAccessibilityAudit() throws {
        let app = launchApplication(
            additionalArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL",
            ]
        )
        openFontSettings(in: app)

        let list = app.collectionViews["font_selection_list"]
        XCTAssertTrue(list.waitForExistence(timeout: 10), app.debugDescription)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Font Settings - Accessibility 5"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        try app.performAccessibilityAudit()
    }

    @MainActor
    private func launchApplication(additionalArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
        ] + additionalArguments
        app.launch()
        return app
    }

    @MainActor
    private func openFontSettings(in app: XCUIApplication) {
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10), app.debugDescription)
        settingsButton.tap()

        let fontSettingsRow = app.buttons["settings_font_selection"]
        scroll(in: app, until: fontSettingsRow)
        fontSettingsRow.tap()

        XCTAssertTrue(app.navigationBars["Font"].waitForExistence(timeout: 10), app.debugDescription)
    }

    private func scroll(in app: XCUIApplication, until element: XCUIElement) {
        var attempts = 0
        while element.exists == false && attempts < 12 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(element.exists, app.debugDescription)
    }
}

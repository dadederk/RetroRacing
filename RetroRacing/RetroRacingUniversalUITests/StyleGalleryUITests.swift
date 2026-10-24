//
//  StyleGalleryUITests.swift
//  RetroRacingUniversalUITests
//
//  Created by Dani Devesa on 04/09/2026.
//

import XCTest
import RetroRacingShared

final class StyleGalleryUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testGivenUnlimitedAccessWhenOpeningSettingsThenGalleryIsTheOnlyStyleSelector() {
        let app = launchApplication(premiumSimulationMode: 1)
        openSettings(in: app)

        let styles = app.buttons["Styles"]
        XCTAssertTrue(styles.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertEqual(styles.value as? String, "LCD")
        XCTAssertFalse(app.buttons["Style"].exists)

        styles.tap()

        XCTAssertTrue(app.navigationBars["Styles"].waitForExistence(timeout: 10))
        let lcd = app.buttons["theme_style_option_lcd"]
        let pocket = app.buttons["theme_style_option_pocket"]
        XCTAssertTrue(lcd.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(pocket.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertEqual(lcd.value as? String, "Selected")
        XCTAssertEqual(pocket.value as? String, "Available")

        pocket.tap()

        waitForSelectedValue(on: pocket)
        XCTAssertEqual(
            app.buttons.matching(NSPredicate(format: "value == %@", "Selected")).count,
            1
        )
    }

    @MainActor
    func testGivenShippingIOSPlatformWhenOpeningSettingsThenReleasedCatalogIsVisible() {
        let app = launchApplication(premiumSimulationMode: 2)
        openSettings(in: app)

        let styles = app.buttons["Styles"]
        XCTAssertTrue(styles.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertEqual(styles.value as? String, "LCD")
        styles.tap()

        XCTAssertTrue(app.navigationBars["Styles"].waitForExistence(timeout: 10))
        let lcd = app.buttons["theme_style_option_lcd"]
        let pocket = app.buttons["theme_style_option_pocket"]
        XCTAssertTrue(lcd.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(pocket.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertEqual(lcd.value as? String, "Selected")
        XCTAssertEqual(pocket.value as? String, "Requires Unlimited Plays")

        let cartridge = app.buttons["theme_style_option_8bit"]
        let crt = app.buttons["theme_style_option_16bit"]
        scrollApplicationUp(in: app, until: crt)
        XCTAssertTrue(cartridge.exists, app.debugDescription)
        XCTAssertTrue(crt.exists, app.debugDescription)
        XCTAssertEqual(cartridge.value as? String, "Requires Unlimited Plays")
        XCTAssertEqual(crt.value as? String, "Requires Unlimited Plays")
        XCTAssertFalse(app.buttons["theme_style_option_32bit"].exists)
        XCTAssertFalse(app.buttons["theme_style_option_64bit"].exists)
    }

    @MainActor
    func testGivenFreeAccessWhenSelectingLockedStyleThenVoluntaryPaywallIsPresented() {
        let app = launchApplication(premiumSimulationMode: 2)
        openSettings(in: app)

        let styles = app.buttons["Styles"]
        XCTAssertTrue(styles.waitForExistence(timeout: 10), app.debugDescription)
        styles.tap()
        XCTAssertTrue(app.navigationBars["Styles"].waitForExistence(timeout: 10))

        let pocket = app.buttons["theme_style_option_pocket"]
        XCTAssertTrue(pocket.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(pocket.isEnabled)
        XCTAssertEqual(pocket.value as? String, "Requires Unlimited Plays")

        pocket.tap()

        XCTAssertTrue(app.navigationBars["Go Unlimited"].waitForExistence(timeout: 10))
    }

    @MainActor
    private func launchApplication(premiumSimulationMode: Int) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            UITestLaunchOption.enabled.rawValue,
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-selectedThemeID", "lcd",
            "-releasePreview.retroThemes", "releaseDefault",
            "-releasePreview.discTheme", "releaseDefault",
            "-releasePreview.polygonTheme", "releaseDefault",
            "-StoreKit.debugPremiumSimulationMode", String(premiumSimulationMode),
        ]
        app.launch()
        return app
    }

    private func openSettings(in app: XCUIApplication) {
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.tap()
    }

    private func waitForSelectedValue(on option: XCUIElement) {
        let selected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Selected"),
            object: option
        )
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 10), .completed)
    }

    private func scrollApplicationUp(in app: XCUIApplication, until element: XCUIElement) {
        var scrollAttempts = 0
        while element.exists == false && scrollAttempts < 8 {
            let gallery = app.collectionViews.firstMatch
            if gallery.exists {
                gallery.swipeUp()
            } else {
                app.swipeUp()
            }
            scrollAttempts += 1
        }
    }
}

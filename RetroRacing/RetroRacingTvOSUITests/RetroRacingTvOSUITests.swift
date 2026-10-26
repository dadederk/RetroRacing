//
//  RetroRacingTvOSUITests.swift
//  RetroRacingTvOSUITests
//
//  Created by Dani Devesa on 05/08/2026.
//

import XCTest

final class RetroRacingTvOSUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testGivenFreshLaunchWhenUsingRemoteCommandsThenCoreGameLoopCompletes() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments += ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let playButton = app.buttons["Play"]
        let tutorialButton = app.buttons["Tutorial"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForFocus(playButton))
        XCTAssertTrue(tutorialButton.exists)

        // When
        select(playButton)

        // Then
        XCTAssertTrue(
            tutorialButton.waitForNonExistence(timeout: 5),
            "Expected the menu to disappear after starting a game"
        )
        XCTAssertFalse(app.buttons["Pause"].exists)
        XCTAssertFalse(app.buttons["Menu"].exists)

        // When
        XCUIRemote.shared.press(.left)
        XCUIRemote.shared.press(.right)
        XCUIRemote.shared.press(.playPause)
        XCUIRemote.shared.press(.playPause)
        XCUIRemote.shared.press(.menu)

        // Then
        let exitAlert = app.alerts["Finish this game?"]
        XCTAssertTrue(exitAlert.waitForExistence(timeout: 5))

        // When
        select(exitAlert.buttons["Keep Playing"].firstMatch)

        // Then
        XCTAssertTrue(
            exitAlert.waitForNonExistence(timeout: 5),
            "Expected Keep Playing to dismiss the exit confirmation"
        )

        // When
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(
            exitAlert.waitForExistence(timeout: 5),
            "Expected Menu to remain responsive after Keep Playing"
        )
        select(exitAlert.buttons["Finish Game"].firstMatch)

        // Then
        XCTAssertTrue(playButton.waitForExistence(timeout: 10))
    }

    @MainActor
    func testGivenMenuWhenMovingBetweenPrimaryAndUtilityActionsThenFocusUsesVerticalNavigation() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments += ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let playButton = app.buttons["Play"]
        let tutorialButton = app.buttons["Tutorial"]
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 10))
        XCTAssertTrue(tutorialButton.waitForExistence(timeout: 5))
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForFocus(playButton))

        // When moving up from Play.
        XCUIRemote.shared.press(.up)

        // Then Tutorial is focused.
        XCTAssertTrue(tutorialButton.hasFocus)

        // When moving down from Tutorial.
        XCUIRemote.shared.press(.down)

        // Then Play is focused.
        XCTAssertTrue(playButton.hasFocus)

        // When moving to Settings and then down.
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.right)
        XCTAssertTrue(settingsButton.hasFocus)
        XCUIRemote.shared.press(.down)

        // Then Play is focused again.
        XCTAssertTrue(playButton.hasFocus)
    }

    @MainActor
    func testGivenMenuWhenNavigatingHelpAndSettingsThenRemoteBackRestoresMenuFocus() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments += [
            "--ui-testing",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-AppleInterfaceStyle", "Dark",
        ]
        app.launch()
        let playButton = app.buttons["Play"]
        let title = app.staticTexts["RetroRapid!"]
        let tutorialButton = app.buttons["Tutorial"]
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 10))
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertTrue(tutorialButton.waitForExistence(timeout: 5))
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(tutorialButton.frame.width, tutorialButton.frame.height)
        XCTAssertGreaterThan(settingsButton.frame.width, settingsButton.frame.height)
        XCTAssertLessThanOrEqual(tutorialButton.frame.maxY, title.frame.minY)
        XCTAssertLessThanOrEqual(settingsButton.frame.maxY, title.frame.minY)
        XCTAssertFalse(tutorialButton.frame.intersects(title.frame))
        XCTAssertFalse(settingsButton.frame.intersects(title.frame))

        // When
        select(tutorialButton)

        // Then
        XCTAssertTrue(app.staticTexts["Tutorial"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Done"].exists)

        // When
        XCUIRemote.shared.press(.menu)

        // Then
        XCTAssertTrue(tutorialButton.waitForExistence(timeout: 5))
        XCTAssertTrue(tutorialButton.hasFocus)

        // When
        select(settingsButton)

        // Then
        let settingsSidebar = app.descendants(matching: .any)["tv_settings_sidebar"]
        let gameCategory = app.descendants(matching: .any)["tv_settings_category_game"]
        let themeCategory = app.descendants(matching: .any)["tv_settings_category_theme"]
        let accessibilityCategory = app.descendants(matching: .any)["tv_settings_category_accessibility"]
        let aboutCategory = app.descendants(matching: .any)["tv_settings_category_about"]
        XCTAssertTrue(settingsSidebar.waitForExistence(timeout: 5))
        XCTAssertTrue(gameCategory.waitForExistence(timeout: 5))
        XCTAssertTrue(themeCategory.waitForExistence(timeout: 5))
        XCTAssertTrue(accessibilityCategory.waitForExistence(timeout: 5))
        XCTAssertTrue(aboutCategory.waitForExistence(timeout: 5))
        XCTAssertTrue(gameCategory.hasFocus)
        XCTAssertFalse(app.buttons["Done"].exists)

        // The Game category exposes working, contrast-safe speed choices in dark appearance.
        let cruiseOption = app.buttons["settings_speed_option_cruise"]
        let fastOption = app.buttons["settings_speed_option_fast"]
        let rapidOption = app.buttons["settings_speed_option_rapid"]
        let fontSelection = app.buttons["settings_font_selection"]
        XCTAssertTrue(cruiseOption.waitForExistence(timeout: 5))
        XCTAssertTrue(fastOption.exists)
        XCTAssertTrue(rapidOption.exists)
        XCTAssertTrue(fontSelection.exists)
        XCTAssertTrue(app.staticTexts["Fast"].exists)
        XCTAssertTrue(app.staticTexts["Rapid"].exists)
        XCUIRemote.shared.press(.right)
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(fastOption.isSelected)
        XCTAssertFalse(cruiseOption.isSelected)

        // When selecting another category from the sidebar.
        XCUIRemote.shared.press(.left)
        focusVertically(on: themeCategory)
        XCUIRemote.shared.press(.select)

        // Then the detail column shows the selected category's gallery.
        XCTAssertTrue(app.buttons["theme_style_option_pocket"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Styles"].exists)

        // Accessibility contains the tvOS parity controls and warning preview.
        focusVertically(on: accessibilityCategory)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(
            app.descendants(matching: .any)["Big Cars"].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.descendants(matching: .any)["Announce friend overtakes"].exists)
        XCTAssertTrue(app.staticTexts["Speed increase warning feedback"].exists)
        XCTAssertTrue(app.buttons["Preview warning"].exists)

        // About exposes the App Store rating entry point without invoking it in tests.
        focusVertically(on: aboutCategory)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["Rate RetroRapid!"].waitForExistence(timeout: 5))

        // When Settings is already showing the selected category page.
        XCUIRemote.shared.press(.menu)

        // Then
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        XCTAssertTrue(settingsButton.hasFocus)

        // When the menu is already at its root, Back must not reveal the unstarted game.
        XCUIRemote.shared.press(.menu)

        // Then
        XCTAssertTrue(playButton.waitForExistence(timeout: 5))
        XCTAssertTrue(settingsButton.exists)
    }

    @MainActor
    private func select(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let remote = XCUIRemote.shared
        let directions: [XCUIRemote.Button] = [.right, .down, .left, .up]

        for direction in directions where !element.hasFocus {
            for _ in 0..<6 where !element.hasFocus {
                remote.press(direction)
            }
        }

        XCTAssertTrue(element.hasFocus, "Expected element to receive focus", file: file, line: line)
        remote.press(.select)
    }

    @MainActor
    private func waitForFocus(_ element: XCUIElement, timeout: TimeInterval = 3) -> Bool {
        let focusExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { candidate, _ in
                (candidate as? XCUIElement)?.hasFocus == true
            },
            object: element
        )
        return XCTWaiter.wait(for: [focusExpectation], timeout: timeout) == .completed
    }

    @MainActor
    private func focusVertically(
        on element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let remote = XCUIRemote.shared

        for _ in 0..<8 where !element.hasFocus {
            remote.press(.up)
        }
        for _ in 0..<8 where !element.hasFocus {
            remote.press(.down)
        }

        XCTAssertTrue(element.hasFocus, "Expected element to receive focus", file: file, line: line)
    }

}

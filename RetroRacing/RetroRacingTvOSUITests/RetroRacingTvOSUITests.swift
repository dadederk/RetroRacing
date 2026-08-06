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
        XCTAssertTrue(playButton.waitForExistence(timeout: 10))
        XCTAssertTrue(playButton.hasFocus)
        XCTAssertTrue(app.buttons["Tutorial"].exists)

        // When
        select(playButton)

        // Then
        XCTAssertFalse(app.buttons["Pause"].exists)
        XCTAssertFalse(app.buttons["Tutorial"].exists)
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
        XCTAssertTrue(playButton.hasFocus)

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
        app.launchArguments += ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let playButton = app.buttons["Play"]
        let title = app.staticTexts["RetroRapid!"]
        let tutorialButton = app.buttons["Tutorial"]
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 10))
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertTrue(tutorialButton.waitForExistence(timeout: 5))
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(tutorialButton.frame.minX, app.frame.midX)
        XCTAssertGreaterThan(settingsButton.frame.minX, app.frame.midX)
        XCTAssertGreaterThan(tutorialButton.frame.width, tutorialButton.frame.height)
        XCTAssertGreaterThan(settingsButton.frame.width, settingsButton.frame.height)
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
        let settingsTabs = app.tabBars["Menu"]
        let speedCategory = settingsTabs.buttons["Speed"]
        let themeCategory = settingsTabs.buttons["Theme"]
        XCTAssertTrue(speedCategory.waitForExistence(timeout: 5))
        XCTAssertTrue(themeCategory.waitForExistence(timeout: 5))
        XCTAssertTrue(speedCategory.hasFocus)
        XCTAssertFalse(app.buttons["Done"].exists)

        // When moving focus to another category without selecting it.
        XCUIRemote.shared.press(.right)

        // Then the focused tab becomes the active category and embeds its gallery.
        XCTAssertTrue(themeCategory.hasFocus)
        XCTAssertTrue(
            app.descendants(matching: .any)["tv_settings_category_content_theme"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.buttons["Style Gallery"].exists)

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
}

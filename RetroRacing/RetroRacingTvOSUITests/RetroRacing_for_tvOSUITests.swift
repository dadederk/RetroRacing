//
//  RetroRacing_for_tvOSUITests.swift
//  RetroRacingTvOSUITests
//
//  Created by Dani Devesa on 05/08/2026.
//

import XCTest

final class RetroRacingForTvOSUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testGivenAppLaunchWhenMenuAppearsThenPlayIsAvailable() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments += ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]

        // When
        app.launch()

        // Then
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Tutorial"].exists)
    }
}

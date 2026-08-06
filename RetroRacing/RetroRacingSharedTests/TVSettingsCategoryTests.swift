//
//  TVSettingsCategoryTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 06/08/2026.
//

import XCTest
@testable import RetroRacingShared

final class TVSettingsCategoryTests: XCTestCase {
    func testGivenReleaseLayoutWhenReadingCategoriesThenDebugIsExcluded() {
        let categories = TVSettingsCategory.visibleCategories(showsDebug: false)

        XCTAssertEqual(
            categories,
            [.speed, .theme, .sound, .accessibility, .controls, .purchases, .about]
        )
    }

    func testGivenDebugLayoutWhenReadingCategoriesThenDebugIsLast() {
        let categories = TVSettingsCategory.visibleCategories(showsDebug: true)

        XCTAssertEqual(categories.last, .debug)
        XCTAssertEqual(categories.count, 8)
    }
}

//
//  MenuViewStyleTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 2026-08-04.
//

import SwiftUI
import XCTest
@testable import RetroRacingShared

final class MenuViewStyleTests: XCTestCase {
    func testGivenUniversalStyleWhenHeightIsRegularThenUsesDefaultTopPadding() {
        // Given
        let style = MenuViewStyle.universal

        // When
        let topPadding = style.titleTopPadding(verticalSizeClass: .regular)

        // Then
        XCTAssertEqual(topPadding, 64)
    }

    func testGivenUniversalStyleWhenHeightIsCompactThenRemovesTopPadding() {
        // Given
        let style = MenuViewStyle.universal

        // When
        let topPadding = style.titleTopPadding(verticalSizeClass: .compact)

        // Then
        XCTAssertEqual(topPadding, 0)
    }

    func testGivenStyleWithoutCompactOverrideWhenHeightIsCompactThenTitleUsesDefaultPadding() {
        // Given
        let style = MenuViewStyle.tvOS

        // When
        let topPadding = style.titleTopPadding(verticalSizeClass: .compact)

        // Then
        XCTAssertEqual(topPadding, style.titleTopPadding)
    }
}

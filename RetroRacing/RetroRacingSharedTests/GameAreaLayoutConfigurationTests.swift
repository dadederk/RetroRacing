//
//  GameAreaLayoutConfigurationTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 04/08/2026.
//

import SwiftUI
import XCTest
@testable import RetroRacingShared

final class GameAreaLayoutConfigurationTests: XCTestCase {
    func testGivenCompactLandscapeExpansionWhenCalculatingSideThenAppliesEdgePadding() {
        // Given
        let configuration = GameAreaLayoutConfiguration.resolve(
            layoutKind: .compactLandscape,
            expandsIntoTopSafeArea: true
        )

        // When
        let side = configuration.side(for: CGSize(width: 393, height: 393))

        // Then
        XCTAssertEqual(side, 377)
    }

    func testGivenCompactLandscapeWithoutExpansionWhenCalculatingSideThenUsesFullAvailableSide() {
        // Given
        let configuration = GameAreaLayoutConfiguration.resolve(
            layoutKind: .compactLandscape,
            expandsIntoTopSafeArea: false
        )

        // When
        let side = configuration.side(for: CGSize(width: 393, height: 393))

        // Then
        XCTAssertEqual(side, 393)
    }

    func testGivenPortraitExpansionFlagWhenResolvingConfigurationThenUsesStandardSizing() {
        // When
        let configuration = GameAreaLayoutConfiguration.resolve(
            layoutKind: .portrait,
            expandsIntoTopSafeArea: true
        )

        // Then
        XCTAssertEqual(configuration, .standard)
    }

    func testGivenTinyAvailableSizeWhenCalculatingExpandedSideThenDoesNotReturnNegativeValue() {
        // Given
        let configuration = GameAreaLayoutConfiguration.resolve(
            layoutKind: .compactLandscape,
            expandsIntoTopSafeArea: true
        )

        // When
        let side = configuration.side(for: CGSize(width: 10, height: 10))

        // Then
        XCTAssertEqual(side, 0)
    }

    func testGivenSafeAreaInsetsWhenTopInsetIsZeroThenZeroIsPreserved() {
        // Given
        let insets = GameLayoutSafeAreaInsets(top: 0)

        // Then
        XCTAssertEqual(insets.top, 0)
    }

    func testGivenSafeAreaInsetsWhenTopInsetIsProvidedThenValueIsPreserved() {
        // Given
        let insets = GameLayoutSafeAreaInsets(top: 60)

        // Then
        XCTAssertEqual(insets.top, 60)
    }
}

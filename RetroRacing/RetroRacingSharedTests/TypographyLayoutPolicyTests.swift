//
//  TypographyLayoutPolicyTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 13/08/2026.
//

import SwiftUI
import XCTest
@testable import RetroRacingShared

final class TypographyLayoutPolicyTests: XCTestCase {
    func testMenuContentAlwaysSupportsScrolling() {
        XCTAssertTrue(MenuLayoutPolicy.isScrollingEnabled)
    }

    func testMenuUtilityActionsReflowVerticallyAtAccessibilitySizes() {
        XCTAssertFalse(MenuLayoutPolicy.usesVerticalUtilityActions(for: .xxxLarge))
        XCTAssertTrue(MenuLayoutPolicy.usesVerticalUtilityActions(for: .accessibility1))
        XCTAssertTrue(MenuLayoutPolicy.usesVerticalUtilityActions(for: .accessibility5))
    }

    func testGivenBottomActionBarWhenTextSizeIncreasesThenActionsStopScalingAtXXXLarge() {
        // Given
        let expectedMaximumSize = DynamicTypeSize.xxxLarge

        // When
        let maximumSize = BottomActionBarLayoutPolicy.maximumActionDynamicTypeSize

        // Then
        XCTAssertEqual(maximumSize, expectedMaximumSize)
    }

    func testAudioCueGridCollapsesToOneColumnAtAccessibilitySizes() {
        XCTAssertEqual(AudioCueTutorialLayoutPolicy.gridColumnCount(for: .large), 3)
        XCTAssertEqual(AudioCueTutorialLayoutPolicy.gridColumnCount(for: .accessibility1), 1)
        XCTAssertEqual(AudioCueTutorialLayoutPolicy.gridColumnCount(for: .accessibility5), 1)
    }
}

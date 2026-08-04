//
//  GameHUDStatusViewTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 2026-08-02.
//

import Foundation
import SwiftUI
import XCTest
@testable import RetroRacingShared

final class GameHUDStatusViewTests: XCTestCase {
    func testGivenLivesValuesWhenResolvingHelmetsThenTheyAreConsumedFromLeftToRight() {
        // Given
        let cases: [(lives: Int, expected: [Bool])] = [
            (3, [false, false, false]),
            (2, [true, false, false]),
            (1, [true, true, false]),
            (0, [true, true, true]),
            (4, [false, false, false]),
            (-1, [true, true, true]),
        ]

        // When / Then
        for testCase in cases {
            let consumedStates = (0..<GameState.initialLives).map {
                GameLivesStatusView.isConsumed($0, lives: testCase.lives)
            }
            XCTAssertEqual(consumedStates, testCase.expected)
        }
    }

    func testGivenVisibleHelmetHeightWhenCalculatingCanvasThenSafetyInsetIsCompensated() {
        // Given
        let requestedVisibleHeight: CGFloat = 20

        // When
        let canvasHeight = GameLivesStatusView.canvasHeight(
            forVisibleHeight: requestedVisibleHeight
        )

        #if os(watchOS)
        let renderedVisibleHeight = canvasHeight * 53 / 55
        #else
        let renderedVisibleHeight = canvasHeight * 210 / 222
        #endif

        // Then
        XCTAssertEqual(renderedVisibleHeight, requestedVisibleHeight, accuracy: 0.001)
    }

    func testGivenHelmetCanvasHeightsWhenCalculatingConsumedOutlineThenOffsetIsClamped() {
        // Given
        let canvasHeights: [CGFloat] = [10, 40, 100]

        // When
        let offsets = canvasHeights.map {
            GameLivesStatusView.consumedOutlineOffset(forCanvasHeight: $0)
        }

        // Then
        XCTAssertEqual(offsets[0], 0.75, accuracy: 0.001)
        XCTAssertEqual(offsets[1], 1.4, accuracy: 0.001)
        XCTAssertEqual(offsets[2], 2, accuracy: 0.001)
    }

    func testGivenRegularHorizontalCompactHeightLandscapeWhenResolvingLayoutThenControlsUseSideRails() {
        // Given
        let containerSize = CGSize(width: 852, height: 393)

        // When
        let layout = GameLayoutKind.resolve(
            containerSize: containerSize,
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        )

        // Then
        XCTAssertEqual(layout, .compactLandscape)
    }

    func testGivenCompactHorizontalCompactHeightLandscapeWhenResolvingLayoutThenControlsUseSideRails() {
        // Given
        let containerSize = CGSize(width: 667, height: 375)

        // When
        let layout = GameLayoutKind.resolve(
            containerSize: containerSize,
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        )

        // Then
        XCTAssertEqual(layout, .compactLandscape)
    }

    func testGivenRegularLandscapeWithRegularHeightWhenResolvingLayoutThenUsesWidePlayLayout() {
        // Given
        let containerSize = CGSize(width: 1366, height: 1024)

        // When
        let layout = GameLayoutKind.resolve(
            containerSize: containerSize,
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        )

        // Then
        XCTAssertEqual(layout, .regularWidthWidePlay)
    }
}

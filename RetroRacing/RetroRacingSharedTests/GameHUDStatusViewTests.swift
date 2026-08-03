//
//  GameHUDStatusViewTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 2026-08-02.
//

import Foundation
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
}

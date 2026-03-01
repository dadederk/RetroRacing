//
//  MacTrackpadSwipeInterpreterTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 24/02/2026.
//

import XCTest
@testable import RetroRacingShared

final class MacTrackpadSwipeInterpreterTests: XCTestCase {
    func testGivenHorizontalDeltaAboveThresholdWhenInterpretingThenReturnsLeftMove() {
        // Given
        var interpreter = MacTrackpadSwipeInterpreter(
            horizontalThreshold: 10,
            phaselessResetInterval: 0.2
        )

        // When
        let action = interpreter.interpret(
            deltaX: -18,
            deltaY: 2,
            phase: .changed,
            isDirectionInvertedFromDevice: false,
            timestamp: 1.0
        )

        // Then
        XCTAssertEqual(action, .moveLeft)
    }

    func testGivenGestureAlreadyTriggeredWhenReceivingMoreHorizontalDeltasThenReturnsNilUntilGestureEnds() {
        // Given
        var interpreter = MacTrackpadSwipeInterpreter(
            horizontalThreshold: 10,
            phaselessResetInterval: 0.2
        )
        _ = interpreter.interpret(
            deltaX: 16,
            deltaY: 1,
            phase: .began,
            isDirectionInvertedFromDevice: false,
            timestamp: 1.0
        )

        // When
        let secondActionInSameGesture = interpreter.interpret(
            deltaX: 20,
            deltaY: 1,
            phase: .changed,
            isDirectionInvertedFromDevice: false,
            timestamp: 1.05
        )
        _ = interpreter.interpret(
            deltaX: 0,
            deltaY: 0,
            phase: .ended,
            isDirectionInvertedFromDevice: false,
            timestamp: 1.1
        )
        let actionAfterGestureReset = interpreter.interpret(
            deltaX: 18,
            deltaY: 1,
            phase: .changed,
            isDirectionInvertedFromDevice: false,
            timestamp: 1.2
        )

        // Then
        XCTAssertNil(secondActionInSameGesture)
        XCTAssertEqual(actionAfterGestureReset, .moveRight)
    }

    func testGivenVerticalDominantDeltaWhenInterpretingThenReturnsNil() {
        // Given
        var interpreter = MacTrackpadSwipeInterpreter(
            horizontalThreshold: 10,
            phaselessResetInterval: 0.2
        )

        // When
        let action = interpreter.interpret(
            deltaX: -12,
            deltaY: 20,
            phase: .changed,
            isDirectionInvertedFromDevice: false,
            timestamp: 1.0
        )

        // Then
        XCTAssertNil(action)
    }

    func testGivenDirectionInvertedFromDeviceWhenInterpretingThenPhysicalSwipeDirectionIsPreserved() {
        // Given
        var interpreter = MacTrackpadSwipeInterpreter(
            horizontalThreshold: 10,
            phaselessResetInterval: 0.2
        )

        // When
        let action = interpreter.interpret(
            deltaX: 14,
            deltaY: 1,
            phase: .changed,
            isDirectionInvertedFromDevice: true,
            timestamp: 1.0
        )

        // Then
        XCTAssertEqual(action, .moveLeft)
    }

    func testGivenPhaselessEventsWhenCooldownElapsesThenInterpreterAllowsNewSwipe() {
        // Given
        var interpreter = MacTrackpadSwipeInterpreter(
            horizontalThreshold: 10,
            phaselessResetInterval: 0.2
        )
        _ = interpreter.interpret(
            deltaX: -16,
            deltaY: 1,
            phase: .none,
            isDirectionInvertedFromDevice: false,
            timestamp: 1.0
        )

        // When
        let actionBeforeCooldown = interpreter.interpret(
            deltaX: -16,
            deltaY: 1,
            phase: .none,
            isDirectionInvertedFromDevice: false,
            timestamp: 1.05
        )
        let actionAfterCooldown = interpreter.interpret(
            deltaX: -16,
            deltaY: 1,
            phase: .none,
            isDirectionInvertedFromDevice: false,
            timestamp: 1.3
        )

        // Then
        XCTAssertNil(actionBeforeCooldown)
        XCTAssertEqual(actionAfterCooldown, .moveLeft)
    }
}

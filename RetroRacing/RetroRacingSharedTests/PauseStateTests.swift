//
//  PauseStateTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 2026-03-27.
//

import XCTest
@testable import RetroRacingShared

final class PauseStateTests: XCTestCase {
    func testGivenSceneAndUserArePausedWhenCheckingExplicitUserPauseThenItIsTrue() {
        // Given
        let pauseState = PauseState(scenePaused: true, isUserPaused: true)

        // When
        let isExplicitUserPauseActive = pauseState.isExplicitUserPauseActive

        // Then
        XCTAssertTrue(isExplicitUserPauseActive)
    }

    func testGivenSceneIsImplicitlyPausedWhenCheckingExplicitUserPauseThenItIsFalse() {
        // Given
        let pauseState = PauseState(scenePaused: true, isUserPaused: false)

        // When
        let isExplicitUserPauseActive = pauseState.isExplicitUserPauseActive

        // Then
        XCTAssertFalse(isExplicitUserPauseActive)
    }

    func testGivenSceneIsRunningWhenCheckingExplicitUserPauseThenItIsFalse() {
        // Given
        let pauseState = PauseState(scenePaused: false, isUserPaused: true)

        // When
        let isExplicitUserPauseActive = pauseState.isExplicitUserPauseActive

        // Then
        XCTAssertFalse(isExplicitUserPauseActive)
    }

    func testGivenSmallHingeFluctuationsWhenObservingAnglesThenMovementIsNotDetected() {
        // Given
        var detector = HingeMotionDetector()

        // When
        let first = detector.observe(angleDegrees: 90, at: 0)
        let second = detector.observe(angleDegrees: 90.8, at: 0.1)
        let third = detector.observe(angleDegrees: 91.5, at: 0.2)

        // Then
        XCTAssertFalse(first || second || third)
        XCTAssertFalse(detector.isMoving)
    }

    func testGivenAccumulatedHingeChangeWhenThresholdIsReachedThenMovementIsDetected() {
        // Given
        var detector = HingeMotionDetector()
        detector.observe(angleDegrees: 90, at: 0)
        detector.observe(angleDegrees: 95, at: 0.1)

        // When
        let detected = detector.observe(angleDegrees: 100.1, at: 0.2)

        // Then
        XCTAssertTrue(detected)
        XCTAssertTrue(detector.isMoving)
        detector.settle()
        XCTAssertFalse(detector.isMoving)
    }

    func testGivenLessThanTenDegreesOfTravelWhenObservingDirectionalUpdatesThenItDoesNotPause() {
        // Given
        var detector = HingeMotionDetector()
        detector.observe(angleDegrees: 90, at: 0)

        // When
        detector.observe(angleDegrees: 95, at: 0.1)
        let detected = detector.observe(angleDegrees: 99.9, at: 0.2)

        // Then
        XCTAssertFalse(detected)
        XCTAssertFalse(detector.isMoving)
    }

    func testGivenHingeBecomesUnavailableWhenObservingNextAngleThenItOnlySetsBaseline() {
        // Given
        var detector = HingeMotionDetector()
        detector.observe(angleDegrees: 90, at: 0)
        detector.observe(angleDegrees: 95, at: 0.1)
        detector.observe(angleDegrees: 101, at: 0.2)

        // When
        detector.observe(angleDegrees: nil, at: 0.3)
        let detected = detector.observe(angleDegrees: 120, at: 0.4)

        // Then
        XCTAssertFalse(detected)
        XCTAssertFalse(detector.isMoving)
    }

    func testGivenSingleAngleSpikeWhenReadingReturnsThenMovementIsNotDetected() {
        // Given
        var detector = HingeMotionDetector()
        detector.observe(angleDegrees: 90, at: 0)

        // When
        let spike = detector.observe(angleDegrees: 102, at: 0.1)
        let recovery = detector.observe(angleDegrees: 90, at: 0.2)

        // Then
        XCTAssertFalse(spike || recovery)
        XCTAssertFalse(detector.isMoving)
    }

    func testGivenSlowDirectionalDriftWhenOutsideMovementWindowThenMovementIsNotDetected() {
        // Given
        var detector = HingeMotionDetector()
        detector.observe(angleDegrees: 90, at: 0)

        // When
        detector.observe(angleDegrees: 96, at: 0.1)
        let detected = detector.observe(angleDegrees: 102, at: 1.0)

        // Then
        XCTAssertFalse(detected)
        XCTAssertFalse(detector.isMoving)
    }
}

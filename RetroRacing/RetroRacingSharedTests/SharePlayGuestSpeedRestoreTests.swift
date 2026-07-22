//
//  SharePlayGuestSpeedRestoreTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 22/07/2026.
//

import XCTest
@testable import RetroRacingShared

final class SharePlayGuestSpeedRestoreTests: XCTestCase {

    func testGivenNoCaptureWhenConsumeRestoreValueThenReturnsNil() {
        // Given
        var restore = SharePlayGuestSpeedRestore()

        // When
        let value = restore.consumeRestoreValue()

        // Then
        XCTAssertNil(value)
        XCTAssertFalse(restore.hasCapturedValue)
    }

    func testGivenCaptureIfNeededWhenCalledThenHasCapturedValueBecomesTrue() {
        // Given
        var restore = SharePlayGuestSpeedRestore()

        // When
        restore.captureIfNeeded(currentDifficulty: .cruise)

        // Then
        XCTAssertTrue(restore.hasCapturedValue)
    }

    func testGivenAlreadyCapturedWhenCaptureIfNeededCalledAgainThenOriginalValueIsPreserved() {
        // Given
        var restore = SharePlayGuestSpeedRestore()
        restore.captureIfNeeded(currentDifficulty: .cruise)

        // When
        restore.captureIfNeeded(currentDifficulty: .rapid)
        let value = restore.consumeRestoreValue()

        // Then
        XCTAssertEqual(value, .cruise)
    }

    func testGivenCapturedValueWhenConsumeRestoreValueThenReturnsOriginalDifficultyAndClearsCapture() {
        // Given
        var restore = SharePlayGuestSpeedRestore()
        restore.captureIfNeeded(currentDifficulty: .fast)

        // When
        let value = restore.consumeRestoreValue()

        // Then
        XCTAssertEqual(value, .fast)
        XCTAssertFalse(restore.hasCapturedValue)
    }

    func testGivenAlreadyConsumedWhenConsumeRestoreValueCalledAgainThenReturnsNil() {
        // Given
        var restore = SharePlayGuestSpeedRestore()
        restore.captureIfNeeded(currentDifficulty: .fast)
        _ = restore.consumeRestoreValue()

        // When
        let secondValue = restore.consumeRestoreValue()

        // Then
        XCTAssertNil(secondValue)
    }

    func testGivenAbortedSessionWhenConsumeRestoreValueThenRestoresOriginalDifficultySameAsNormalFinish() {
        // Given: capture happens once when the guest adopts the host's speed, regardless of
        // how the session later ends (normal finish or abort/disconnect).
        var restore = SharePlayGuestSpeedRestore()
        restore.captureIfNeeded(currentDifficulty: .cruise)

        // When
        let value = restore.consumeRestoreValue()

        // Then
        XCTAssertEqual(value, .cruise)
    }
}

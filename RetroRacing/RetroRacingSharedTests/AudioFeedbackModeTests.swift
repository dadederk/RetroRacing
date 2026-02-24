//
//  AudioFeedbackModeTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 19/02/2026.
//

import XCTest
@testable import RetroRacingShared

final class AudioFeedbackModeTests: XCTestCase {
    func testGivenDisplayOrderWhenReadingModesThenLanePulsesIsPrioritizedAfterRetro() {
        // Given / When
        let order = AudioFeedbackMode.displayOrder

        // Then
        XCTAssertEqual(order, [.retro, .cueLanePulses, .cueArpeggio, .cueChord])
    }

    func testGivenRetroModeWhenCheckingTutorialSupportThenSupportIsDisabled() {
        // Given

        // When
        let supportsTutorial = AudioFeedbackMode.retro.supportsAudioCueTutorial

        // Then
        XCTAssertFalse(supportsTutorial)
    }

    func testGivenCueModeWhenCheckingTutorialSupportThenSupportIsEnabled() {
        // Given

        // When
        let supportsTutorial = AudioFeedbackMode.cueArpeggio.supportsAudioCueTutorial

        // Then
        XCTAssertTrue(supportsTutorial)
    }
}

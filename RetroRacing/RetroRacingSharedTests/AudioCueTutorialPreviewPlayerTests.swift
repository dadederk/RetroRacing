//
//  AudioCueTutorialPreviewPlayerTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 19/02/2026.
//

import XCTest
@testable import RetroRacingShared

@MainActor
final class AudioCueTutorialPreviewPlayerTests: XCTestCase {
    func testGivenLaneModePreviewWhenPlayingThenTickCueUsesRequestedMode() {
        // Given
        let laneCuePlayer = MockTutorialLaneCuePlayer()
        let sut = AudioCueTutorialPreviewPlayer(laneCuePlayer: laneCuePlayer)
        let safeColumns: Set<CueColumn> = [.left, .middle]

        // When
        sut.playLaneModePreview(.cueLanePulses, safeColumns: safeColumns)

        // Then
        XCTAssertEqual(laneCuePlayer.lastTickMode, .cueLanePulses)
        XCTAssertEqual(laneCuePlayer.lastTickSafeColumns, safeColumns)
    }

    func testGivenMoveStylePreviewWhenPlayingSafeAndFailThenMoveCueUsesStyleAndSafety() {
        // Given
        let laneCuePlayer = MockTutorialLaneCuePlayer()
        let sut = AudioCueTutorialPreviewPlayer(laneCuePlayer: laneCuePlayer)

        // When
        sut.playMoveStylePreview(column: .middle, isSafe: true, style: .laneConfirmationAndSafety)
        sut.playMoveStylePreview(column: .right, isSafe: false, style: .laneConfirmationAndSafety)

        // Then
        XCTAssertEqual(laneCuePlayer.moveCalls.count, 2)
        XCTAssertEqual(laneCuePlayer.moveCalls.first?.column, .middle)
        XCTAssertEqual(laneCuePlayer.moveCalls.first?.style, .laneConfirmationAndSafety)
        XCTAssertEqual(laneCuePlayer.moveCalls.first?.isSafe, true)
        XCTAssertEqual(laneCuePlayer.moveCalls.last?.column, .right)
        XCTAssertEqual(laneCuePlayer.moveCalls.last?.style, .laneConfirmationAndSafety)
        XCTAssertEqual(laneCuePlayer.moveCalls.last?.isSafe, false)
    }

    func testGivenPreviewPlayerWhenStoppingThenLaneCueStopIsRequested() {
        // Given
        let laneCuePlayer = MockTutorialLaneCuePlayer()
        let sut = AudioCueTutorialPreviewPlayer(laneCuePlayer: laneCuePlayer)

        // When
        sut.stopAll()

        // Then
        XCTAssertEqual(laneCuePlayer.stopAllCalls.count, 1)
    }

    func testGivenSpeedWarningSoundWhenPlayingThenArpeggioTickUsesAllLanes() {
        // Given
        let laneCuePlayer = MockTutorialLaneCuePlayer()
        let sut = AudioCueTutorialPreviewPlayer(laneCuePlayer: laneCuePlayer)

        // When
        sut.playSpeedWarningSound(volume: 0.65)

        // Then
        XCTAssertEqual(laneCuePlayer.lastSetVolume, 0.65, accuracy: 0.0001)
        XCTAssertEqual(laneCuePlayer.lastTickMode, .cueArpeggio)
        XCTAssertEqual(laneCuePlayer.lastTickSafeColumns, Set(CueColumn.allCases))
    }
}

private final class MockTutorialLaneCuePlayer: LaneCuePlayer {
    private(set) var lastTickSafeColumns: Set<CueColumn> = []
    private(set) var lastTickMode: AudioFeedbackMode?
    private(set) var lastSetVolume: Double?
    private(set) var moveCalls: [(column: CueColumn, style: LaneMoveCueStyle, isSafe: Bool)] = []
    private(set) var stopAllCalls: [TimeInterval] = []

    func playTickCue(safeColumns: Set<CueColumn>, mode: AudioFeedbackMode) {
        lastTickSafeColumns = safeColumns
        lastTickMode = mode
    }

    func playMoveCue(column: CueColumn, isSafe: Bool, mode: AudioFeedbackMode, style: LaneMoveCueStyle) {
        moveCalls.append((column: column, style: style, isSafe: isSafe))
    }

    func setVolume(_ volume: Double) {
        lastSetVolume = volume
    }

    func stopAll(fadeDuration: TimeInterval) {
        stopAllCalls.append(fadeDuration)
    }
}

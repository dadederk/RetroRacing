import XCTest
import AVFoundation
@testable import RetroRacingShared

final class GeneratedSFXRecipeTests: XCTestCase {
    func testGivenFailRepeatCountReducedWhenReadingRecipeThenDurationGetsShorter() {
        // Given
        let baseline = GeneratedSFXProfile(
            failTailRepeatCount: GeneratedSFXProfile.baselineFailTailRepeatCount
        )
        let shorter = GeneratedSFXProfile(
            failTailRepeatCount: GeneratedSFXProfile.baselineFailTailRepeatCount - 1
        )

        // When
        let baselineDuration = baseline.fail.duration
        let shorterDuration = shorter.fail.duration

        // Then
        XCTAssertLessThan(shorterDuration, baselineDuration)
    }

    func testGivenProfileWhenReadingFailTailPatternThenRepeatCountMatchesConfiguredValue() {
        // Given
        let configuredRepeatCount = 2
        let profile = GeneratedSFXProfile(failTailRepeatCount: configuredRepeatCount)

        // When
        let tailPattern = profile.fail.tailPattern

        // Then
        XCTAssertEqual(tailPattern?.repeatCount, configuredRepeatCount)
        XCTAssertEqual(
            tailPattern?.expandedSegments.count,
            (tailPattern?.motif.count ?? 0) * configuredRepeatCount
        )
    }

    func testGivenDefaultRecipesWhenRenderingBuffersThenStartBipAndCountdownBuffersAreNonEmpty() {
        // Given
        let profile = GeneratedSFXProfile.defaultProfile
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)

        // When
        let startBuffer = format.flatMap { GeneratedSFXRenderer.makeBuffer(recipe: profile.start, format: $0) }
        let bipBuffer = format.flatMap { GeneratedSFXRenderer.makeBuffer(recipe: profile.bip, format: $0) }
        let countdownBuffer = format.flatMap {
            GeneratedSFXRenderer.makeBuffer(recipe: profile.sharePlayCountdownLow, format: $0)
        }
        let goBuffer = format.flatMap {
            GeneratedSFXRenderer.makeBuffer(recipe: profile.sharePlayCountdownGo, format: $0)
        }

        // Then
        XCTAssertNotNil(startBuffer)
        XCTAssertNotNil(bipBuffer)
        XCTAssertNotNil(countdownBuffer)
        XCTAssertNotNil(goBuffer)
        XCTAssertGreaterThan(startBuffer?.frameLength ?? 0, 0)
        XCTAssertGreaterThan(bipBuffer?.frameLength ?? 0, 0)
        XCTAssertGreaterThan(countdownBuffer?.frameLength ?? 0, 0)
        XCTAssertGreaterThan(goBuffer?.frameLength ?? 0, 0)
    }

    func testGivenDefaultRecipesWhenMigratedToArcadeAudioKitThenDurationsAndFrameCountsArePreserved() throws {
        // Given
        let profile = GeneratedSFXProfile.defaultProfile
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1))

        // When
        let startBuffer = try XCTUnwrap(GeneratedSFXRenderer.makeBuffer(recipe: profile.start, format: format))
        let bipBuffer = try XCTUnwrap(GeneratedSFXRenderer.makeBuffer(recipe: profile.bip, format: format))
        let failBuffer = try XCTUnwrap(GeneratedSFXRenderer.makeBuffer(recipe: profile.fail, format: format))

        // Then
        XCTAssertEqual(profile.start.duration, 0.35, accuracy: 0.0001)
        XCTAssertEqual(profile.bip.duration, 0.078, accuracy: 0.0001)
        XCTAssertEqual(profile.fail.duration, 1.88, accuracy: 0.0001)
        XCTAssertEqual(startBuffer.frameLength, 15_435)
        XCTAssertEqual(bipBuffer.frameLength, 3_440)
        XCTAssertEqual(failBuffer.frameLength, 82_908)
    }

    func testGivenSharePlayCountdownRecipesWhenReadingDurationsThenGoCueIsLongerThanStepBeeps() throws {
        // Given
        let profile = GeneratedSFXProfile.defaultProfile
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1))

        // When
        let lowBuffer = try XCTUnwrap(
            GeneratedSFXRenderer.makeBuffer(recipe: profile.sharePlayCountdownLow, format: format)
        )
        let midBuffer = try XCTUnwrap(
            GeneratedSFXRenderer.makeBuffer(recipe: profile.sharePlayCountdownMid, format: format)
        )
        let highBuffer = try XCTUnwrap(
            GeneratedSFXRenderer.makeBuffer(recipe: profile.sharePlayCountdownHigh, format: format)
        )
        let goBuffer = try XCTUnwrap(
            GeneratedSFXRenderer.makeBuffer(recipe: profile.sharePlayCountdownGo, format: format)
        )

        // Then
        XCTAssertEqual(profile.sharePlayCountdownLow.duration, 0.1, accuracy: 0.0001)
        XCTAssertEqual(profile.sharePlayCountdownMid.duration, 0.1, accuracy: 0.0001)
        XCTAssertEqual(profile.sharePlayCountdownHigh.duration, 0.1, accuracy: 0.0001)
        XCTAssertEqual(profile.sharePlayCountdownGo.duration, 0.42, accuracy: 0.0001)
        XCTAssertEqual(lowBuffer.frameLength, 4_410)
        XCTAssertEqual(midBuffer.frameLength, 4_410)
        XCTAssertEqual(highBuffer.frameLength, 4_410)
        XCTAssertEqual(goBuffer.frameLength, 18_522)
    }

    func testGivenSharePlayCountdownCueSchedulerWhenDisplayValuesRepeatThenEachStepPlaysOnce() {
        // Given
        var scheduler = SharePlayCountdownCueScheduler()

        // When / Then
        XCTAssertEqual(scheduler.cue(for: 3), .sharePlayCountdownLow)
        XCTAssertNil(scheduler.cue(for: 3))
        XCTAssertEqual(scheduler.cue(for: 2), .sharePlayCountdownMid)
        XCTAssertNil(scheduler.cue(for: 2))
        XCTAssertEqual(scheduler.cue(for: 1), .sharePlayCountdownHigh)
        XCTAssertNil(scheduler.cue(for: 1))

        scheduler.reset()
        XCTAssertEqual(scheduler.cue(for: 3), .sharePlayCountdownLow)
    }
}

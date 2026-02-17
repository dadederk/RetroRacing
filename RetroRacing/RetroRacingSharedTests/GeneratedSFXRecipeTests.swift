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

    func testGivenDefaultRecipesWhenRenderingBuffersThenStartAndBipBuffersAreNonEmpty() {
        // Given
        let profile = GeneratedSFXProfile.defaultProfile
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)

        // When
        let startBuffer = format.flatMap { GeneratedSFXRenderer.makeBuffer(recipe: profile.start, format: $0) }
        let bipBuffer = format.flatMap { GeneratedSFXRenderer.makeBuffer(recipe: profile.bip, format: $0) }

        // Then
        XCTAssertNotNil(startBuffer)
        XCTAssertNotNil(bipBuffer)
        XCTAssertGreaterThan(startBuffer?.frameLength ?? 0, 0)
        XCTAssertGreaterThan(bipBuffer?.frameLength ?? 0, 0)
    }
}

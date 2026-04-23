import XCTest
@testable import RetroRacingShared

@MainActor
final class GeneratedSoundEffectPlayerTests: XCTestCase {
    func testGivenGeneratedPlayerWhenPlayingEachEffectThenCompletionFiresOnce() async {
        // Given
        let sut = AVGeneratedSoundEffectPlayer()

        // When
        for effect in SoundEffect.allCases {
            let completionCalled = expectation(description: "completion called for \(effect.rawValue)")
            var callCount = 0
            sut.play(effect) {
                callCount += 1
                completionCalled.fulfill()
            }

            // Then
            await fulfillment(of: [completionCalled], timeout: 3.0)
            XCTAssertEqual(callCount, 1)
        }
    }

    func testGivenOutOfRangeVolumesWhenSettingVolumeThenValueIsClamped() {
        // Given
        let sut = AVGeneratedSoundEffectPlayer()

        // When
        sut.setVolume(2.0)
        let highClamp = sut._testCurrentVolume
        sut.setVolume(-0.5)
        let lowClamp = sut._testCurrentVolume

        // Then
        XCTAssertEqual(highClamp, 1.0, accuracy: 0.001)
        XCTAssertEqual(lowClamp, 0.0, accuracy: 0.001)
    }

    func testGivenPlayingEffectWhenStoppingImmediatelyThenPlaybackStops() async {
        // Given
        let sut = AVGeneratedSoundEffectPlayer()
        sut.play(.fail, completion: nil)

        // When
        sut.stopAll(fadeDuration: 0)
        try? await Task.sleep(for: .milliseconds(30))

        // Then
        XCTAssertFalse(sut._testIsPlaying(effect: .fail))
    }

    func testGivenPlayingEffectWhenStoppingWithFadeThenPlaybackStopsAfterFade() async {
        // Given
        let sut = AVGeneratedSoundEffectPlayer()
        sut.play(.fail, completion: nil)

        // When
        sut.stopAll(fadeDuration: 0.08)
        try? await Task.sleep(for: .milliseconds(180))

        // Then
        XCTAssertFalse(sut._testIsPlaying(effect: .fail))
    }

    func testGivenEngineStartFailureWhenPlayingWithCompletionThenCompletionStillFiresOnce() async {
        // Given
        let sut = AVGeneratedSoundEffectPlayer()
        sut._testForceStartEngineFailure = true
        let completionCalled = expectation(description: "completion called")
        var callCount = 0

        // When
        sut.play(.start) {
            callCount += 1
            completionCalled.fulfill()
        }

        // Then
        await fulfillment(of: [completionCalled], timeout: 1.0)
        XCTAssertEqual(callCount, 1)
        XCTAssertGreaterThan(sut._testPlaybackSkippedCount, 0)
        XCTAssertGreaterThan(sut._testEngineRestartFailureCount, 0)
    }

    func testGivenGraphMarkedDirtyWhenPlayingThenGraphRebuildIsAttemptedAndCompletionStillFires() async {
        // Given
        let sut = AVGeneratedSoundEffectPlayer()
        sut._testMarkGraphDirty()
        let completionCalled = expectation(description: "completion called after rebuild")
        var callCount = 0

        // When
        sut.play(.bip) {
            callCount += 1
            completionCalled.fulfill()
        }

        // Then
        await fulfillment(of: [completionCalled], timeout: 1.5)
        XCTAssertEqual(callCount, 1)
        XCTAssertGreaterThan(sut._testGraphRebuildCount, 0)
        XCTAssertGreaterThan(sut._testEngineRestartAttemptCount, 0)
    }
}

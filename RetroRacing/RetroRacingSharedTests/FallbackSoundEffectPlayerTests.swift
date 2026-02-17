import XCTest
@testable import RetroRacingShared

final class FallbackSoundEffectPlayerTests: XCTestCase {
    func testGivenPrimaryCanPlayWhenPlayingEffectThenFallbackIsNotUsed() {
        // Given
        let primary = MockGeneratedPrimarySoundEffectPlayer()
        primary.playableEffects = Set(SoundEffect.allCases)
        let fallback = MockSoundEffectPlayerForFallback()
        let sut = FallbackSoundEffectPlayer(primary: primary, fallback: fallback)

        // When
        sut.play(.bip, completion: nil)

        // Then
        XCTAssertEqual(primary.playedEffects, [.bip])
        XCTAssertTrue(fallback.playedEffects.isEmpty)
    }

    func testGivenPrimaryCannotPlayWhenPlayingEffectThenFallbackIsUsed() {
        // Given
        let primary = MockGeneratedPrimarySoundEffectPlayer()
        primary.playableEffects = [.start]
        let fallback = MockSoundEffectPlayerForFallback()
        let sut = FallbackSoundEffectPlayer(primary: primary, fallback: fallback)

        // When
        sut.play(.fail, completion: nil)

        // Then
        XCTAssertTrue(primary.playedEffects.isEmpty)
        XCTAssertEqual(fallback.playedEffects, [.fail])
    }

    func testGivenPrimaryCannotPlayWhenFallbackCompletesThenCompletionFiresExactlyOnce() {
        // Given
        let primary = MockGeneratedPrimarySoundEffectPlayer()
        primary.playableEffects = []
        let fallback = MockSoundEffectPlayerForFallback()
        let sut = FallbackSoundEffectPlayer(primary: primary, fallback: fallback)
        var completionCallCount = 0

        // When
        sut.play(.fail) {
            completionCallCount += 1
        }

        // Then
        XCTAssertEqual(fallback.playedEffects, [.fail])
        XCTAssertEqual(completionCallCount, 1)
    }
}

private final class MockGeneratedPrimarySoundEffectPlayer: GeneratedSFXAvailabilityProviding {
    var playableEffects = Set<SoundEffect>()
    private(set) var playedEffects: [SoundEffect] = []
    private(set) var stopAllCalls: [TimeInterval] = []
    private(set) var lastVolume: Double?

    func canPlay(_ effect: SoundEffect) -> Bool {
        playableEffects.contains(effect)
    }

    func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        playedEffects.append(effect)
        completion?()
    }

    func stopAll(fadeDuration: TimeInterval) {
        stopAllCalls.append(fadeDuration)
    }

    func setVolume(_ volume: Double) {
        lastVolume = volume
    }
}

private final class MockSoundEffectPlayerForFallback: SoundEffectPlayer {
    private(set) var playedEffects: [SoundEffect] = []
    private(set) var stopAllCalls: [TimeInterval] = []
    private(set) var lastVolume: Double?

    func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        playedEffects.append(effect)
        completion?()
    }

    func stopAll(fadeDuration: TimeInterval) {
        stopAllCalls.append(fadeDuration)
    }

    func setVolume(_ volume: Double) {
        lastVolume = volume
    }
}

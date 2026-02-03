import XCTest
@testable import RetroRacingShared

final class SoundEffectPlayerTests: XCTestCase {
    func testPlayStoresCompletionAndCallsOnFinish() async {
        let player = MockAudioPlayer()
        let sut = AVSoundEffectPlayer(testPlayers: [.bip: player])

        let completionCalled = expectation(description: "completion called")
        sut.play(.bip) {
            completionCalled.fulfill()
        }

        // Simulate delegate callback via test hook.
        _ = await sut._testComplete(effect: .bip)

        await fulfillment(of: [completionCalled], timeout: 1.0)
    }

    func testStopAllStopsActivePlayers() async {
        let player = MockAudioPlayer()
        player.isPlaying = true
        let sut = AVSoundEffectPlayer(testPlayers: [.fail: player])

        sut.stopAll(fadeDuration: 0)

        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertFalse(player.isPlaying)
    }

    func testSetVolumeClampsValue() async {
        let player = MockAudioPlayer()
        let sut = AVSoundEffectPlayer(testPlayers: [.start: player])

        sut.setVolume(2.5)
        try? await Task.sleep(for: .milliseconds(20))
        XCTAssertEqual(player.volume, 1.0, accuracy: 0.001)
    }
}

// MARK: - Mocks

final class MockAudioPlayer: NSObject, AudioPlayer {
    var isPlaying: Bool = false
    var volume: Float = 0.5
    var currentTime: TimeInterval = 0
    weak var delegate: AVAudioPlayerDelegate?
    var objectID: ObjectIdentifier { ObjectIdentifier(self) }

    func prepareToPlay() {}

    func play() {
        isPlaying = true
    }

    func stop() {
        isPlaying = false
    }
}

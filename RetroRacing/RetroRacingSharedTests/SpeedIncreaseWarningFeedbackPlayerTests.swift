import XCTest
@testable import RetroRacingShared

@MainActor
final class SpeedIncreaseWarningFeedbackPlayerTests: XCTestCase {
    func testGivenAnnouncementModeWhenPlayingThenPosterReceivesHighPriorityAnnouncement() {
        // Given
        let poster = AnnouncementPosterSpy()
        let haptics = HapticControllerSpy()
        var soundPlayCount = 0
        let sut = SpeedIncreaseWarningFeedbackPlayer(
            announcementPoster: poster,
            hapticController: haptics,
            playWarningSound: { soundPlayCount += 1 },
            announcementTextProvider: { "Speed increasing" }
        )

        // When
        sut.play(mode: .announcement)

        // Then
        XCTAssertEqual(poster.calls.count, 1)
        XCTAssertEqual(poster.calls.first?.announcement, "Speed increasing")
        XCTAssertEqual(poster.calls.first?.priority, .high)
        XCTAssertEqual(haptics.warningCalls, 0)
        XCTAssertEqual(soundPlayCount, 0)
    }

    func testGivenWarningHapticModeWhenPlayingThenWarningHapticIsTriggered() {
        // Given
        let poster = AnnouncementPosterSpy()
        let haptics = HapticControllerSpy()
        var soundPlayCount = 0
        let sut = SpeedIncreaseWarningFeedbackPlayer(
            announcementPoster: poster,
            hapticController: haptics,
            playWarningSound: { soundPlayCount += 1 },
            announcementTextProvider: { "Speed increasing" }
        )

        // When
        sut.play(mode: .warningHaptic)

        // Then
        XCTAssertEqual(haptics.warningCalls, 1)
        XCTAssertTrue(poster.calls.isEmpty)
        XCTAssertEqual(soundPlayCount, 0)
    }

    func testGivenWarningSoundModeWhenPlayingThenWarningSoundClosureIsInvoked() {
        // Given
        let poster = AnnouncementPosterSpy()
        let haptics = HapticControllerSpy()
        var soundPlayCount = 0
        let sut = SpeedIncreaseWarningFeedbackPlayer(
            announcementPoster: poster,
            hapticController: haptics,
            playWarningSound: { soundPlayCount += 1 },
            announcementTextProvider: { "Speed increasing" }
        )

        // When
        sut.play(mode: .warningSound)

        // Then
        XCTAssertEqual(soundPlayCount, 1)
        XCTAssertTrue(poster.calls.isEmpty)
        XCTAssertEqual(haptics.warningCalls, 0)
    }

    func testGivenNoneModeWhenPlayingThenNoFeedbackIsTriggered() {
        // Given
        let poster = AnnouncementPosterSpy()
        let haptics = HapticControllerSpy()
        var soundPlayCount = 0
        let sut = SpeedIncreaseWarningFeedbackPlayer(
            announcementPoster: poster,
            hapticController: haptics,
            playWarningSound: { soundPlayCount += 1 },
            announcementTextProvider: { "Speed increasing" }
        )

        // When
        sut.play(mode: .none)

        // Then
        XCTAssertTrue(poster.calls.isEmpty)
        XCTAssertEqual(haptics.warningCalls, 0)
        XCTAssertEqual(soundPlayCount, 0)
    }
}

@MainActor
private final class AnnouncementPosterSpy: AccessibilityAnnouncementPosting {
    private(set) var calls: [(announcement: String, priority: AccessibilityAnnouncementPriority)] = []

    func postAnnouncement(_ announcement: String, priority: AccessibilityAnnouncementPriority) {
        calls.append((announcement, priority))
    }
}

private final class HapticControllerSpy: HapticFeedbackController {
    private(set) var warningCalls = 0

    func triggerCrashHaptic() {}
    func triggerGridUpdateHaptic() {}
    func triggerMoveHaptic() {}
    func triggerSuccessHaptic() {}
    func triggerWarningHaptic() { warningCalls += 1 }
}

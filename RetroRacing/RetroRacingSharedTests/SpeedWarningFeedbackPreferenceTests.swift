import XCTest
@testable import RetroRacingShared

final class SpeedWarningFeedbackPreferenceTests: XCTestCase {
    private static let suiteName = "test.SpeedWarningFeedbackPreferenceTests"
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: Self.suiteName)!
        userDefaults.removePersistentDomain(forName: Self.suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: Self.suiteName)
        userDefaults = nil
        super.tearDown()
    }

    func testGivenNoUserOverrideWhenVoiceOverIsOffThenCurrentSelectionIsNone() {
        // Given

        // When
        let selectedMode = SpeedWarningFeedbackPreference.currentSelection(
            from: userDefaults,
            supportsHaptics: true,
            isVoiceOverRunning: false
        )

        // Then
        XCTAssertEqual(selectedMode, .none)
    }

    func testGivenNoUserOverrideWhenVoiceOverIsOnAndHapticsSupportedThenCurrentSelectionIsHaptic() {
        // Given

        // When
        let selectedMode = SpeedWarningFeedbackPreference.currentSelection(
            from: userDefaults,
            supportsHaptics: true,
            isVoiceOverRunning: true
        )

        // Then
        XCTAssertEqual(selectedMode, .warningHaptic)
    }

    func testGivenNoUserOverrideWhenVoiceOverIsOnAndHapticsUnsupportedThenCurrentSelectionIsAnnouncement() {
        // Given

        // When
        let selectedMode = SpeedWarningFeedbackPreference.currentSelection(
            from: userDefaults,
            supportsHaptics: false,
            isVoiceOverRunning: true
        )

        // Then
        XCTAssertEqual(selectedMode, .announcement)
    }

    func testGivenUserOverrideWhenResolvingCurrentSelectionThenUserOverrideWins() {
        // Given
        SpeedWarningFeedbackPreference.setUserOverride(.warningSound, in: userDefaults)

        // When
        let selectedMode = SpeedWarningFeedbackPreference.currentSelection(
            from: userDefaults,
            supportsHaptics: true,
            isVoiceOverRunning: false
        )

        // Then
        XCTAssertEqual(selectedMode, .warningSound)
    }

    func testGivenHapticOverrideWhenHapticsUnsupportedThenSelectionNormalizesToAnnouncement() {
        // Given
        SpeedWarningFeedbackPreference.setUserOverride(.warningHaptic, in: userDefaults)

        // When
        let selectedMode = SpeedWarningFeedbackPreference.currentSelection(
            from: userDefaults,
            supportsHaptics: false,
            isVoiceOverRunning: false
        )

        // Then
        XCTAssertEqual(selectedMode, .announcement)
    }
}

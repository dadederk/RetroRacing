import XCTest
@testable import RetroRacingShared

@MainActor
final class SettingsPreferencesStoreTests: XCTestCase {
    private static let suiteName = "test.SettingsPreferencesStoreTests"
    private var userDefaults: UserDefaults!
    private var isVoiceOverRunning = false

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: Self.suiteName)!
        userDefaults.removePersistentDomain(forName: Self.suiteName)
        isVoiceOverRunning = false
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: Self.suiteName)
        userDefaults = nil
        super.tearDown()
    }

    func testGivenRetroAudioModeWhenCheckingTutorialVisibilityThenAudioCueTutorialIsHidden() {
        // Given
        var conditionalDefault = ConditionalDefault<AudioFeedbackMode>()
        conditionalDefault.setUserOverride(.retro)
        conditionalDefault.save(to: userDefaults, key: AudioFeedbackMode.conditionalDefaultStorageKey)
        let store = makeStore()

        // When
        store.loadIfNeeded()

        // Then
        XCTAssertFalse(store.shouldShowAudioCueTutorial)
    }

    func testGivenCueAudioModeWhenCheckingTutorialVisibilityThenAudioCueTutorialIsVisible() {
        // Given
        var conditionalDefault = ConditionalDefault<AudioFeedbackMode>()
        conditionalDefault.setUserOverride(.cueLanePulses)
        conditionalDefault.save(to: userDefaults, key: AudioFeedbackMode.conditionalDefaultStorageKey)
        let store = makeStore()

        // When
        store.loadIfNeeded()

        // Then
        XCTAssertTrue(store.shouldShowAudioCueTutorial)
    }

    func testGivenAnnouncementModeAndVoiceOverOffWhenCheckingPreviewEnablementThenPreviewIsDisabled() {
        // Given
        SpeedWarningFeedbackPreference.setUserOverride(.announcement, in: userDefaults)
        let store = makeStore()

        // When
        store.loadIfNeeded()

        // Then
        XCTAssertFalse(store.shouldEnableSpeedWarningPreview)
    }

    func testGivenAnnouncementModeAndVoiceOverOnWhenCheckingPreviewEnablementThenPreviewIsEnabled() {
        // Given
        isVoiceOverRunning = true
        SpeedWarningFeedbackPreference.setUserOverride(.announcement, in: userDefaults)
        let store = makeStore()

        // When
        store.loadIfNeeded()

        // Then
        XCTAssertTrue(store.shouldEnableSpeedWarningPreview)
    }

    func testGivenNoneModeWhenCheckingPreviewEnablementThenPreviewIsDisabled() {
        // Given
        SpeedWarningFeedbackPreference.setUserOverride(.none, in: userDefaults)
        let store = makeStore()

        // When
        store.loadIfNeeded()

        // Then
        XCTAssertFalse(store.shouldEnableSpeedWarningPreview)
    }

    func testGivenLaneCueStyleWhenSwitchingAudioModesThenLaneCueStyleIsPreserved() {
        // Given
        let store = makeStore()
        store.loadIfNeeded()
        store.setLaneMoveCueStyle(.laneConfirmationAndSafety)

        // When
        store.setAudioFeedbackMode(.retro)
        store.setAudioFeedbackMode(.cueArpeggio)

        // Then
        XCTAssertEqual(store.selectedLaneMoveCueStyle, .laneConfirmationAndSafety)
    }

    func testGivenSelectedAndConfiguredValuesWhenResolvingTutorialApplyStateThenConfiguredLabelIsReturned() {
        // Given

        // When
        let label = TutorialApplyStateResolver.applyButtonLabel(
            selectedName: "Lane confirmation",
            isConfigured: TutorialApplyStateResolver.isConfigured(
                selectedValue: LaneMoveCueStyle.laneConfirmation,
                configuredValue: LaneMoveCueStyle.laneConfirmation
            )
        )

        // Then
        XCTAssertEqual(
            label,
            GameLocalizedStrings.format("tutorial_configured %@", "Lane confirmation")
        )
    }

    private func makeStore() -> SettingsPreferencesStore {
        SettingsPreferencesStore(
            userDefaults: userDefaults,
            supportsHaptics: true,
            isVoiceOverRunningProvider: { [unowned self] in
                isVoiceOverRunning
            }
        )
    }
}

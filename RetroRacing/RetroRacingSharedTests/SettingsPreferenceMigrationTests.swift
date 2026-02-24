import XCTest
@testable import RetroRacingShared

final class SettingsPreferenceMigrationTests: XCTestCase {
    private static let suiteName = "test.SettingsPreferenceMigrationTests"
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

    func testGivenAnnouncementsEnabledWhenRunningMigrationThenSpeedWarningModeBecomesAnnouncement() {
        // Given
        userDefaults.set(true, forKey: InGameAnnouncementsPreference.storageKey)

        // When
        SettingsPreferenceMigration.runIfNeeded(userDefaults: userDefaults, supportsHaptics: true)

        // Then
        XCTAssertEqual(SpeedWarningFeedbackMode.currentSelection(from: userDefaults), .announcement)
    }

    func testGivenAnnouncementsDisabledAndHapticsSupportedWhenRunningMigrationThenSpeedWarningModeBecomesNone() {
        // Given
        userDefaults.set(false, forKey: InGameAnnouncementsPreference.storageKey)

        // When
        SettingsPreferenceMigration.runIfNeeded(userDefaults: userDefaults, supportsHaptics: true)

        // Then
        XCTAssertEqual(SpeedWarningFeedbackMode.currentSelection(from: userDefaults), .none)
    }

    func testGivenAnnouncementsDisabledAndHapticsUnsupportedWhenRunningMigrationThenSpeedWarningModeBecomesNone() {
        // Given
        userDefaults.set(false, forKey: InGameAnnouncementsPreference.storageKey)

        // When
        SettingsPreferenceMigration.runIfNeeded(userDefaults: userDefaults, supportsHaptics: false)

        // Then
        XCTAssertEqual(SpeedWarningFeedbackMode.currentSelection(from: userDefaults), .none)
    }

    func testGivenLegacyVolumeWhenRunningMigrationThenConditionalVolumePreservesExistingValue() {
        // Given
        userDefaults.set(0.35, forKey: SoundPreferences.volumeKey)

        // When
        SettingsPreferenceMigration.runIfNeeded(userDefaults: userDefaults, supportsHaptics: false)

        // Then
        XCTAssertEqual(SoundEffectsVolumePreference.currentSelection(from: userDefaults), 0.35, accuracy: 0.0001)
    }

    func testGivenConditionalVolumeAlreadyStoredWhenRunningMigrationThenStoredOverrideIsPreserved() {
        // Given
        var conditionalDefault = ConditionalDefault<SoundEffectsVolumeSetting>()
        conditionalDefault.setUserOverride(SoundEffectsVolumeSetting(value: 0.9))
        conditionalDefault.save(to: userDefaults, key: SoundEffectsVolumeSetting.conditionalDefaultStorageKey)
        userDefaults.set(0.2, forKey: SoundPreferences.volumeKey)

        // When
        SettingsPreferenceMigration.runIfNeeded(userDefaults: userDefaults, supportsHaptics: false)

        // Then
        XCTAssertEqual(SoundEffectsVolumePreference.currentSelection(from: userDefaults), 0.9, accuracy: 0.0001)
    }

    func testGivenConditionalSpeedModeAlreadyStoredWhenRunningMigrationThenStoredOverrideIsPreserved() {
        // Given
        var conditionalDefault = ConditionalDefault<SpeedWarningFeedbackMode>()
        conditionalDefault.setUserOverride(.announcement)
        conditionalDefault.save(to: userDefaults, key: SpeedWarningFeedbackMode.conditionalDefaultStorageKey)
        userDefaults.set(false, forKey: InGameAnnouncementsPreference.storageKey)

        // When
        SettingsPreferenceMigration.runIfNeeded(userDefaults: userDefaults, supportsHaptics: true)

        // Then
        XCTAssertEqual(SpeedWarningFeedbackMode.currentSelection(from: userDefaults), .announcement)
    }

    func testGivenVoiceOverStateWhenResolvingSfxSystemDefaultThenExpectedVolumeIsReturned() {
        // Given / When / Then
        XCTAssertEqual(SoundEffectsVolumeSetting.systemDefaultValue(isVoiceOverRunning: true), 1.0, accuracy: 0.0001)
        XCTAssertEqual(
            SoundEffectsVolumeSetting.systemDefaultValue(isVoiceOverRunning: false),
            SoundPreferences.defaultVolume,
            accuracy: 0.0001
        )
    }

    func testGivenHapticsUnsupportedWhenListingLaneMoveCueStylesThenHapticsOptionIsHidden() {
        // Given / When
        let styles = LaneMoveCueStyle.availableStyles(supportsHaptics: false)

        // Then
        XCTAssertFalse(styles.contains(.haptics))
        XCTAssertEqual(styles, [.laneConfirmation, .safetyOnly, .laneConfirmationAndSafety])
    }

    func testGivenHapticsUnsupportedWhenListingSpeedWarningModesThenHapticOptionIsHidden() {
        // Given / When
        let modes = SpeedWarningFeedbackMode.availableModes(supportsHaptics: false)

        // Then
        XCTAssertEqual(modes, [.announcement, .warningSound, .none])
    }

    func testGivenHapticsSupportedWhenListingSpeedWarningModesThenAllModesAreAvailable() {
        // Given / When
        let modes = SpeedWarningFeedbackMode.availableModes(supportsHaptics: true)

        // Then
        XCTAssertEqual(modes, [.announcement, .warningHaptic, .warningSound, .none])
    }
}

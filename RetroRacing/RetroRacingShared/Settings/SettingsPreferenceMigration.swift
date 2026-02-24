import Foundation

/// One-time migrations from legacy settings keys to conditional-default storage.
public enum SettingsPreferenceMigration {
    private static let migrationVersionKey = "settingsPreferenceMigration_v1_completed"

    public static func runIfNeeded(userDefaults: UserDefaults, supportsHaptics: Bool) {
        guard userDefaults.bool(forKey: migrationVersionKey) == false else { return }
        _ = supportsHaptics
        migrateSpeedWarningFeedbackModeIfNeeded(userDefaults: userDefaults)
        migrateSoundEffectsVolumeIfNeeded(userDefaults: userDefaults)
        userDefaults.set(true, forKey: migrationVersionKey)
    }

    private static func migrateSpeedWarningFeedbackModeIfNeeded(userDefaults: UserDefaults) {
        guard userDefaults.data(forKey: SpeedWarningFeedbackMode.conditionalDefaultStorageKey) == nil else { return }
        guard userDefaults.object(forKey: InGameAnnouncementsPreference.storageKey) != nil else { return }

        let announcementsEnabled = userDefaults.bool(forKey: InGameAnnouncementsPreference.storageKey)
        let mappedMode: SpeedWarningFeedbackMode = announcementsEnabled
            ? .announcement
            : .none

        var conditionalDefault = ConditionalDefault<SpeedWarningFeedbackMode>()
        conditionalDefault.setUserOverride(mappedMode)
        conditionalDefault.save(
            to: userDefaults,
            key: SpeedWarningFeedbackMode.conditionalDefaultStorageKey
        )
    }

    private static func migrateSoundEffectsVolumeIfNeeded(userDefaults: UserDefaults) {
        guard userDefaults.data(forKey: SoundEffectsVolumeSetting.conditionalDefaultStorageKey) == nil else { return }
        guard userDefaults.object(forKey: SoundPreferences.volumeKey) != nil else { return }

        let legacyVolume = userDefaults.double(forKey: SoundPreferences.volumeKey)
        SoundEffectsVolumePreference.setUserOverride(legacyVolume, in: userDefaults)
    }
}

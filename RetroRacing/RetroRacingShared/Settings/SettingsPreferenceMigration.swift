import Foundation

/// One-time migrations from legacy settings keys to conditional-default storage.
public enum SettingsPreferenceMigration {
    private static let migrationVersionKey = "settingsPreferenceMigration_v2_completed"

    public static func runIfNeeded(userDefaults: UserDefaults, supportsHaptics _: Bool) {
        guard userDefaults.bool(forKey: migrationVersionKey) == false else { return }
        migrateSpeedWarningFeedbackModeIfNeeded(userDefaults: userDefaults)
        migrateSoundEffectsVolumeIfNeeded(userDefaults: userDefaults)
        migrateAudioFeedbackModeIfNeeded(userDefaults: userDefaults)
        userDefaults.set(true, forKey: migrationVersionKey)
    }

    private static func migrateSpeedWarningFeedbackModeIfNeeded(userDefaults: UserDefaults) {
        guard userDefaults.data(forKey: SpeedWarningFeedbackMode.conditionalDefaultStorageKey) == nil else { return }
        guard userDefaults.object(forKey: InGameAnnouncementsPreference.storageKey) != nil else { return }

        let announcementsEnabled = userDefaults.bool(forKey: InGameAnnouncementsPreference.storageKey)
        guard announcementsEnabled == false else {
            // Keep the migrated state on system default when legacy announcements were enabled.
            // This preserves the VoiceOver-adaptive default and keeps VoiceOver-off users silent.
            return
        }

        SpeedWarningFeedbackPreference.setUserOverride(.none, in: userDefaults)
    }

    private static func migrateSoundEffectsVolumeIfNeeded(userDefaults: UserDefaults) {
        guard userDefaults.data(forKey: SoundEffectsVolumeSetting.conditionalDefaultStorageKey) == nil else { return }
        guard userDefaults.object(forKey: SoundPreferences.volumeKey) != nil else { return }

        let legacyVolume = userDefaults.double(forKey: SoundPreferences.volumeKey)
        SoundEffectsVolumePreference.setUserOverride(legacyVolume, in: userDefaults)
    }

    private static func migrateAudioFeedbackModeIfNeeded(userDefaults: UserDefaults) {
        guard userDefaults.data(forKey: AudioFeedbackMode.conditionalDefaultStorageKey) == nil else { return }
        guard let rawValue = userDefaults.string(forKey: AudioFeedbackMode.storageKey),
              let mode = AudioFeedbackMode(rawValue: rawValue) else { return }

        var conditionalDefault = ConditionalDefault<AudioFeedbackMode>()
        conditionalDefault.setUserOverride(mode)
        conditionalDefault.save(
            to: userDefaults,
            key: AudioFeedbackMode.conditionalDefaultStorageKey
        )
    }
}

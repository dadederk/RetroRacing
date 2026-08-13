import Foundation

/// One-time migrations from legacy settings keys to conditional-default storage.
public enum SettingsPreferenceMigration {
    private static let conditionalDefaultsMigrationVersionKey = "settingsPreferenceMigration_v2_completed"
    private static let simplifiedGridMigrationVersionKey = "settingsPreferenceMigration_v3_completed"

    private enum LegacyRoadVisualStyle {
        static let storageKey = "roadVisualStyle"
        static let simplifiedGridRawValue = "simplifiedGrid"
    }

    public static func runIfNeeded(userDefaults: UserDefaults, supportsHaptics _: Bool) {
        if userDefaults.bool(forKey: conditionalDefaultsMigrationVersionKey) == false {
            migrateSpeedWarningFeedbackModeIfNeeded(userDefaults: userDefaults)
            migrateSoundEffectsVolumeIfNeeded(userDefaults: userDefaults)
            migrateAudioFeedbackModeIfNeeded(userDefaults: userDefaults)
            userDefaults.set(true, forKey: conditionalDefaultsMigrationVersionKey)
        }

        if userDefaults.bool(forKey: simplifiedGridMigrationVersionKey) == false {
            migrateSimplifiedGridIfNeeded(userDefaults: userDefaults)
            userDefaults.set(true, forKey: simplifiedGridMigrationVersionKey)
        }
    }

    private static func migrateSimplifiedGridIfNeeded(userDefaults: UserDefaults) {
        defer { userDefaults.removeObject(forKey: LegacyRoadVisualStyle.storageKey) }

        guard userDefaults.string(forKey: LegacyRoadVisualStyle.storageKey)
            == LegacyRoadVisualStyle.simplifiedGridRawValue,
              userDefaults.data(forKey: BigCarsSetting.conditionalDefaultStorageKey) == nil else {
            return
        }

        var conditionalDefault = ConditionalDefault<BigCarsSetting>()
        conditionalDefault.setUserOverride(BigCarsSetting(isEnabled: true))
        conditionalDefault.save(
            to: userDefaults,
            key: BigCarsSetting.conditionalDefaultStorageKey
        )
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

import Foundation

/// Conditional-default wrapper value for SFX volume preferences.
public struct SoundEffectsVolumeSetting: Codable, Equatable, Sendable {
    public static let conditionalDefaultStorageKey = "sfxVolume_conditionalDefault"

    public let value: Double

    public init(value: Double) {
        self.value = Self.clamp(value)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0.0), 1.0)
    }
}

extension SoundEffectsVolumeSetting: ConditionalDefaultValue {
    static func systemDefaultValue(isVoiceOverRunning: Bool) -> Double {
        isVoiceOverRunning ? 1.0 : SoundPreferences.defaultVolume
    }

    public static var systemDefault: SoundEffectsVolumeSetting {
        SoundEffectsVolumeSetting(
            value: systemDefaultValue(isVoiceOverRunning: VoiceOverStatus.isVoiceOverRunning)
        )
    }
}

public enum SoundEffectsVolumePreference {
    public static func currentSelection(from userDefaults: UserDefaults) -> Double {
        let conditionalDefault = ConditionalDefault<SoundEffectsVolumeSetting>.load(
            from: userDefaults,
            key: SoundEffectsVolumeSetting.conditionalDefaultStorageKey
        )
        return conditionalDefault.effectiveValue.value
    }

    public static func setUserOverride(_ value: Double, in userDefaults: UserDefaults) {
        var conditionalDefault = ConditionalDefault<SoundEffectsVolumeSetting>.load(
            from: userDefaults,
            key: SoundEffectsVolumeSetting.conditionalDefaultStorageKey
        )
        conditionalDefault.setUserOverride(SoundEffectsVolumeSetting(value: value))
        conditionalDefault.save(
            to: userDefaults,
            key: SoundEffectsVolumeSetting.conditionalDefaultStorageKey
        )
    }
}

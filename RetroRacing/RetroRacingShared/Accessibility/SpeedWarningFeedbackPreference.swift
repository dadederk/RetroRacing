import Foundation

public enum SpeedWarningFeedbackPreference {
    public static func systemDefault(
        isVoiceOverRunning: Bool,
        supportsHaptics: Bool
    ) -> SpeedWarningFeedbackMode {
        guard isVoiceOverRunning else { return .none }
        return supportsHaptics ? .warningHaptic : .announcement
    }

    public static func currentSelection(
        from userDefaults: UserDefaults,
        supportsHaptics: Bool,
        isVoiceOverRunning: Bool
    ) -> SpeedWarningFeedbackMode {
        let conditionalDefault = ConditionalDefault<SpeedWarningFeedbackMode>.load(
            from: userDefaults,
            key: SpeedWarningFeedbackMode.conditionalDefaultStorageKey
        )
        return currentSelection(
            from: conditionalDefault,
            supportsHaptics: supportsHaptics,
            isVoiceOverRunning: isVoiceOverRunning
        )
    }

    public static func currentSelection(
        from conditionalDefault: ConditionalDefault<SpeedWarningFeedbackMode>,
        supportsHaptics: Bool,
        isVoiceOverRunning: Bool
    ) -> SpeedWarningFeedbackMode {
        if let userOverride = conditionalDefault.userOverride {
            return normalize(userOverride, supportsHaptics: supportsHaptics)
        }
        return systemDefault(
            isVoiceOverRunning: isVoiceOverRunning,
            supportsHaptics: supportsHaptics
        )
    }

    public static func setUserOverride(
        _ mode: SpeedWarningFeedbackMode,
        in userDefaults: UserDefaults
    ) {
        var conditionalDefault = ConditionalDefault<SpeedWarningFeedbackMode>.load(
            from: userDefaults,
            key: SpeedWarningFeedbackMode.conditionalDefaultStorageKey
        )
        conditionalDefault.setUserOverride(mode)
        conditionalDefault.save(
            to: userDefaults,
            key: SpeedWarningFeedbackMode.conditionalDefaultStorageKey
        )
    }

    public static func normalize(
        _ mode: SpeedWarningFeedbackMode,
        supportsHaptics: Bool
    ) -> SpeedWarningFeedbackMode {
        guard supportsHaptics == false, mode == .warningHaptic else { return mode }
        return .announcement
    }
}

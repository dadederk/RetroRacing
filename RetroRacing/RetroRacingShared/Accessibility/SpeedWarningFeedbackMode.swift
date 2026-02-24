import Foundation

/// How upcoming speed increases should be communicated during gameplay.
public enum SpeedWarningFeedbackMode: String, CaseIterable, Codable, Sendable {
    case announcement
    case warningHaptic
    case warningSound
    case none

    public static let conditionalDefaultStorageKey = "speedWarningFeedbackMode_conditionalDefault"
    public static let defaultMode: SpeedWarningFeedbackMode = .announcement

    public static var systemDefault: SpeedWarningFeedbackMode {
        .announcement
    }

    public var localizedNameKey: String {
        switch self {
        case .announcement:
            return "settings_speed_warning_feedback_announcement"
        case .warningHaptic:
            return "settings_speed_warning_feedback_warning_haptic"
        case .warningSound:
            return "settings_speed_warning_feedback_warning_sound"
        case .none:
            return "settings_speed_warning_feedback_none"
        }
    }

    public static func availableModes(supportsHaptics: Bool) -> [SpeedWarningFeedbackMode] {
        if supportsHaptics {
            return [.announcement, .warningHaptic, .warningSound, .none]
        }
        return [.announcement, .warningSound, .none]
    }

    public static func currentSelection(from userDefaults: UserDefaults) -> SpeedWarningFeedbackMode {
        let conditionalDefault = ConditionalDefault<SpeedWarningFeedbackMode>.load(
            from: userDefaults,
            key: conditionalDefaultStorageKey
        )
        return conditionalDefault.effectiveValue
    }
}

extension SpeedWarningFeedbackMode: ConditionalDefaultValue {}

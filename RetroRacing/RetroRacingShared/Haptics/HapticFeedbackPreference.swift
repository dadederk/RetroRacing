import Foundation

/// UserDefaults key for the haptic feedback toggle. Default is true when key is missing.
/// Whether the device supports haptics is determined by the app layer (configuration injection); use that to hide the setting when false.
public enum HapticFeedbackPreference {
    public static let storageKey = "hapticFeedbackEnabled"
}

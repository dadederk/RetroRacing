import Foundation
import RetroRacingShared
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
/// iOS implementation: failure haptic on crash, light impact on grid update. Respects UserDefaults hapticFeedbackEnabled.
public final class UIKitHapticFeedbackController: HapticFeedbackController, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        notificationGenerator.prepare()
        impactGenerator.prepare()
    }

    public func triggerCrashHaptic() {
        guard userDefaults.object(forKey: HapticFeedbackPreference.storageKey) == nil
            || userDefaults.bool(forKey: HapticFeedbackPreference.storageKey) else { return }
        notificationGenerator.notificationOccurred(.error)
    }

    public func triggerGridUpdateHaptic() {
        guard userDefaults.object(forKey: HapticFeedbackPreference.storageKey) == nil
            || userDefaults.bool(forKey: HapticFeedbackPreference.storageKey) else { return }
        impactGenerator.impactOccurred()
    }
}
#else
/// No-op for macOS and other platforms without UIKit.
public final class UIKitHapticFeedbackController: HapticFeedbackController, @unchecked Sendable {
    public init(userDefaults: UserDefaults = .standard) {}
    public func triggerCrashHaptic() {}
    public func triggerGridUpdateHaptic() {}
}
#endif

//
//  UIKitHapticFeedbackController.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import RetroRacingShared
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
/// iOS implementation: failure haptic on crash, light impact on grid update. Respects UserDefaults hapticFeedbackEnabled.
public final class UIKitHapticFeedbackController: HapticFeedbackController {
    private let userDefaults: UserDefaults
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)

    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        notificationGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
    }

    public func triggerCrashHaptic() {
        guard userDefaults.object(forKey: HapticFeedbackPreference.storageKey) == nil
            || userDefaults.bool(forKey: HapticFeedbackPreference.storageKey) else { return }
        notificationGenerator.notificationOccurred(.error)
    }

    public func triggerGridUpdateHaptic() {
        guard userDefaults.object(forKey: HapticFeedbackPreference.storageKey) == nil
            || userDefaults.bool(forKey: HapticFeedbackPreference.storageKey) else { return }
        lightImpactGenerator.impactOccurred()
    }

    public func triggerMoveHaptic() {
        guard userDefaults.object(forKey: HapticFeedbackPreference.storageKey) == nil
            || userDefaults.bool(forKey: HapticFeedbackPreference.storageKey) else { return }
        mediumImpactGenerator.impactOccurred()
    }

    public func triggerSuccessHaptic() {
        guard userDefaults.object(forKey: HapticFeedbackPreference.storageKey) == nil
            || userDefaults.bool(forKey: HapticFeedbackPreference.storageKey) else { return }
        notificationGenerator.notificationOccurred(.success)
    }
}
#else
/// No-op for macOS and other platforms without UIKit.
public final class UIKitHapticFeedbackController: HapticFeedbackController {
    public init(userDefaults: UserDefaults) {}
    public func triggerCrashHaptic() {}
    public func triggerGridUpdateHaptic() {}
    public func triggerMoveHaptic() {}
    public func triggerSuccessHaptic() {}
}
#endif

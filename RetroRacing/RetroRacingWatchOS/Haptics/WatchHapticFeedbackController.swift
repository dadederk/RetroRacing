import Foundation
import WatchKit
import RetroRacingShared

/// watchOS implementation backed by the Taptic Engine.
final class WatchHapticFeedbackController: HapticFeedbackController {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func triggerCrashHaptic() {
        guard isHapticsEnabled else { return }
        WKInterfaceDevice.current().play(.failure)
    }

    func triggerGridUpdateHaptic() {
        guard isHapticsEnabled else { return }
        WKInterfaceDevice.current().play(.click)
    }

    func triggerMoveHaptic() {
        guard isHapticsEnabled else { return }
        WKInterfaceDevice.current().play(.click)
    }

    func triggerSuccessHaptic() {
        guard isHapticsEnabled else { return }
        WKInterfaceDevice.current().play(.success)
    }

    func triggerWarningHaptic() {
        guard isHapticsEnabled else { return }
        WKInterfaceDevice.current().play(.notification)
    }

    private var isHapticsEnabled: Bool {
        userDefaults.object(forKey: HapticFeedbackPreference.storageKey) == nil
            || userDefaults.bool(forKey: HapticFeedbackPreference.storageKey)
    }
}

import Foundation
import WatchKit
import RetroRacingShared

/// watchOS implementation backed by the Taptic Engine.
final class WatchHapticFeedbackController: HapticFeedbackController {
    private enum ScheduledHaptic {
        case crash
        case gridTick
        case move
        case success
        case warning

        var pattern: WKHapticType {
            switch self {
            case .crash:
                return .failure
            case .gridTick:
                return .click
            case .move:
                return .directionUp
            case .success:
                return .success
            case .warning:
                return .notification
            }
        }

        var shouldSequence: Bool {
            self == .warning
        }
    }

    private enum Timing {
        static let warningSpacingSeconds: TimeInterval = 0.12
    }

    private let userDefaults: UserDefaults
    private let schedulerQueue = DispatchQueue(label: "com.retroracing.watch.haptic-scheduler")
    private var nextWarningNanoseconds: UInt64 = 0

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func triggerCrashHaptic() {
        play(.crash)
    }

    func triggerGridUpdateHaptic() {
        play(.gridTick)
    }

    func triggerMoveHaptic() {
        play(.move)
    }

    func triggerSuccessHaptic() {
        play(.success)
    }

    func triggerWarningHaptic() {
        play(.warning)
    }

    private var isHapticsEnabled: Bool {
        userDefaults.object(forKey: HapticFeedbackPreference.storageKey) == nil
            || userDefaults.bool(forKey: HapticFeedbackPreference.storageKey)
    }

    private func play(_ haptic: ScheduledHaptic) {
        guard isHapticsEnabled else { return }
        guard haptic.shouldSequence else {
            dispatchHapticOnMain(haptic.pattern)
            return
        }

        schedulerQueue.async { [weak self] in
            guard let self else { return }
            let now = DispatchTime.now().uptimeNanoseconds
            let playbackStart = max(now, self.nextWarningNanoseconds)
            self.nextWarningNanoseconds = playbackStart &+ Self.nanoseconds(from: Timing.warningSpacingSeconds)
            let delayNanoseconds = playbackStart > now ? playbackStart - now : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.dispatchInterval(from: delayNanoseconds)) {
                [weak self] in
                guard let self else { return }
                self.dispatchHapticOnMain(haptic.pattern)
            }
        }
    }

    private func dispatchHapticOnMain(_ pattern: WKHapticType) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isHapticsEnabled else { return }
            guard WKExtension.shared().applicationState == .active else { return }
            WKInterfaceDevice.current().play(pattern)
        }
    }

    private static func nanoseconds(from seconds: TimeInterval) -> UInt64 {
        guard seconds > 0 else { return 0 }
        return UInt64(seconds * 1_000_000_000)
    }

    private static func dispatchInterval(from nanoseconds: UInt64) -> DispatchTimeInterval {
        .nanoseconds(Int(min(nanoseconds, UInt64(Int.max))))
    }
}

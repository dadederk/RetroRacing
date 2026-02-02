import Foundation

/// Protocol for triggering haptic feedback from the view layer. Implement on iOS (failure + light impact) and optionally watchOS; no-op elsewhere.
public protocol HapticFeedbackController: Sendable {
    /// Trigger failure haptic (e.g. on crash). Call from `gameSceneDidDetectCollision`.
    func triggerCrashHaptic()
    /// Trigger light impact (e.g. on each grid line update). Call from `gameSceneDidUpdateGrid`.
    func triggerGridUpdateHaptic()
}

/// No-op implementation for platforms that do not use haptics (e.g. tvOS, macOS).
public struct NoOpHapticFeedbackController: HapticFeedbackController, Sendable {
    public init() {}
    public func triggerCrashHaptic() {}
    public func triggerGridUpdateHaptic() {}
}

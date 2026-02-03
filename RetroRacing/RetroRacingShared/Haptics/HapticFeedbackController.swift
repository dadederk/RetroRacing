//
//  HapticFeedbackController.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Protocol for triggering haptic feedback from the view layer with platform-specific implementations.
public protocol HapticFeedbackController {
    /// Trigger failure haptic (e.g. on crash). Call from `gameSceneDidDetectCollision`.
    func triggerCrashHaptic()
    /// Trigger light impact (e.g. on each grid tick). Call from `gameSceneDidUpdateGrid`.
    func triggerGridUpdateHaptic()
    /// Trigger medium impact (e.g. on user move left/right).
    func triggerMoveHaptic()
    /// Trigger success haptic (e.g. on new personal best).
    func triggerSuccessHaptic()
}

/// No-op implementation for platforms that do not use haptics (e.g. tvOS, macOS).
public struct NoOpHapticFeedbackController: HapticFeedbackController {
    public init() {}
    public func triggerCrashHaptic() {}
    public func triggerGridUpdateHaptic() {}
    public func triggerMoveHaptic() {}
    public func triggerSuccessHaptic() {}
}

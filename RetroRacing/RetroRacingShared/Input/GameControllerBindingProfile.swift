//
//  GameControllerBindingProfile.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-03-02.
//

import Foundation

/// An action that can be assigned to a remappable controller button.
public enum GameControllerRemapAction: Equatable, Sendable {
    case moveLeft
    case moveRight
    case pauseResume
}

/// A physical controller button that can be mapped to a game action.
public enum GameControllerRemapButton: String, CaseIterable, Codable, Sendable {
    case none
    case dpadLeft
    case dpadRight
    case a
    case b
    case x
    case y
    case leftShoulder
    case rightShoulder
    case leftTrigger
    case rightTrigger
    case menu

    public var localizedNameKey: String {
        "controller_button_\(rawValue)"
    }
}

/// The player's button bindings for game controller input.
///
/// Defaults mirror the physical defaults: D-pad left moves left, D-pad right moves right,
/// and the Menu/Start button pauses/resumes. Reassigning a button replaces its default.
///
/// The left stick always works as a directional backup regardless of this profile.
///
/// Conflict rule: a single button may not be assigned to more than one action.
/// If the same button is assigned to a new action, the previous assignment is cleared.
public struct GameControllerBindingProfile: Codable, Equatable, Sendable {
    public var leftButton: GameControllerRemapButton
    public var rightButton: GameControllerRemapButton
    public var pauseButton: GameControllerRemapButton

    public static let `default` = GameControllerBindingProfile(
        leftButton: .dpadLeft,
        rightButton: .dpadRight,
        pauseButton: .menu
    )

    public init(
        leftButton: GameControllerRemapButton,
        rightButton: GameControllerRemapButton,
        pauseButton: GameControllerRemapButton
    ) {
        self.leftButton = leftButton
        self.rightButton = rightButton
        self.pauseButton = pauseButton
    }

    /// Returns the action associated with a button, or nil if unassigned or `.none`.
    public func action(for button: GameControllerRemapButton) -> GameControllerRemapAction? {
        guard button != .none else { return nil }
        if button == leftButton { return .moveLeft }
        if button == rightButton { return .moveRight }
        if button == pauseButton { return .pauseResume }
        return nil
    }

    /// Returns a copy with `leftButton` set, clearing any conflicting prior assignment.
    public func settingLeft(_ button: GameControllerRemapButton) -> GameControllerBindingProfile {
        var copy = self
        copy.resolveConflict(for: button, preserving: .moveLeft)
        copy.leftButton = button
        return copy
    }

    /// Returns a copy with `rightButton` set, clearing any conflicting prior assignment.
    public func settingRight(_ button: GameControllerRemapButton) -> GameControllerBindingProfile {
        var copy = self
        copy.resolveConflict(for: button, preserving: .moveRight)
        copy.rightButton = button
        return copy
    }

    /// Returns a copy with `pauseButton` set, clearing any conflicting prior assignment.
    public func settingPause(_ button: GameControllerRemapButton) -> GameControllerBindingProfile {
        var copy = self
        copy.resolveConflict(for: button, preserving: .pauseResume)
        copy.pauseButton = button
        return copy
    }

    // Clears any field that already owns `button`, except the action being preserved.
    private mutating func resolveConflict(
        for button: GameControllerRemapButton,
        preserving action: GameControllerRemapAction
    ) {
        guard button != .none else { return }
        if button == leftButton && action != .moveLeft { leftButton = .none }
        if button == rightButton && action != .moveRight { rightButton = .none }
        if button == pauseButton && action != .pauseResume { pauseButton = .none }
    }
}

//
//  GameControllerInputSource.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-03-02.
//

import Foundation

/// An action emitted by a physical game controller.
public enum GameControllerAction: Sendable {
    case moveLeft
    case moveRight
    case pauseResume

    /// Converts a remappable action into a controller action.
    public init(_ remapAction: GameControllerRemapAction) {
        switch remapAction {
        case .moveLeft: self = .moveLeft
        case .moveRight: self = .moveRight
        case .pauseResume: self = .pauseResume
        }
    }
}

/// Provides game controller input events to the game view.
///
/// Implementations observe physical controllers and emit `GameControllerAction` values
/// via the registered handler. The protocol is injected at the composition root so
/// the shared `GameView` stays platform-agnostic.
public protocol GameControllerInputSource: AnyObject {
    /// Starts observing controller input and routing events to `handler`.
    func start(handler: @escaping @MainActor @Sendable (GameControllerAction) -> Void)
    /// Stops observing controller input and clears the handler.
    func stop()
}

/// Platform behaviour configuration injected into `SystemGameControllerInputSource`.
///
/// Avoids `#if os()` guards inside the service layer by separating platform-specific
/// decisions into a value type set up at the composition root.
public struct GameControllerPlatformConfig: Sendable {
    /// When `true`, D-pad and left stick trigger directional moves.
    /// Set to `false` on tvOS, where `.onMoveCommand` already handles direction.
    public let capturesDirectionalInput: Bool

    /// When `true`, the physical Start/Menu button emits `.pauseResume`.
    /// Set to `false` on tvOS, where `.onPlayPauseCommand` already handles pause.
    public let capturesMenuButton: Bool

    public init(capturesDirectionalInput: Bool, capturesMenuButton: Bool) {
        self.capturesDirectionalInput = capturesDirectionalInput
        self.capturesMenuButton = capturesMenuButton
    }

    /// Standard iOS/macOS config: captures direction, stick, and menu button.
    public static let standard = GameControllerPlatformConfig(
        capturesDirectionalInput: true,
        capturesMenuButton: true
    )

    /// tvOS config: direction handled by `onMoveCommand`, pause by `onPlayPauseCommand`.
    /// Only remapped face buttons are captured.
    public static let tvOS = GameControllerPlatformConfig(
        capturesDirectionalInput: false,
        capturesMenuButton: false
    )
}

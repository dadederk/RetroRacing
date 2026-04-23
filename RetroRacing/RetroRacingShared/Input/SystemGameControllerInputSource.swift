//
//  SystemGameControllerInputSource.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-03-02.
//

// GameController is not available on watchOS or visionOS.
#if !os(watchOS) && !os(visionOS)

import GameController
import Foundation

/// Live `GameControllerInputSource` backed by Apple's `GCController` APIs.
///
/// Behaviour:
/// - Connects to already-attached controllers on `start()` and subscribes to
///   future connect/disconnect notifications.
/// - D-pad left/right and menu button route through the binding profile stored
///   in `UserDefaults`. These are replaceable defaults, so remapping in Settings
///   changes which physical buttons trigger move/pause actions immediately.
/// - Left stick always moves left/right regardless of the profile (analog backup).
///   Stick uses threshold (0.5) with hysteresis (resets below 0.2) to prevent lane spam.
/// - Face buttons and shoulder/trigger buttons also route through the binding profile.
/// - One global profile applies to all connected controllers.
/// - On tvOS (`capturesDirectionalInput = false`, `capturesMenuButton = false`),
///   directional and menu inputs are handled by `onMoveCommand`/`onPlayPauseCommand`
///   instead; only face/shoulder buttons are captured here.
@MainActor
public final class SystemGameControllerInputSource: GameControllerInputSource {
    private let platformConfig: GameControllerPlatformConfig
    private let userDefaults: UserDefaults
    private var actionHandler: (@MainActor @Sendable (GameControllerAction) -> Void)?
    private var activeSubscriptions = 0
    private var connectObserver: NSObjectProtocol?
    private var disconnectObserver: NSObjectProtocol?
    private var stickState: [ObjectIdentifier: StickHysteresisState] = [:]

    public init(platformConfig: GameControllerPlatformConfig, userDefaults: UserDefaults) {
        self.platformConfig = platformConfig
        self.userDefaults = userDefaults
    }

    public func start(handler: @escaping @MainActor @Sendable (GameControllerAction) -> Void) {
        activeSubscriptions += 1
        actionHandler = handler
        if activeSubscriptions == 1 {
            attachToConnectedControllers()
            observeControllerConnections()
            AppLog.info(
                AppLog.input + AppLog.game,
                "CONTROLLER_INPUT_SOURCE",
                outcome: .started,
                fields: [
                    .bool("capturesDirectional", platformConfig.capturesDirectionalInput),
                    .bool("capturesMenu", platformConfig.capturesMenuButton),
                    .int("activeSubscriptions", activeSubscriptions)
                ]
            )
        } else {
            AppLog.debug(
                AppLog.input + AppLog.game,
                "CONTROLLER_INPUT_SOURCE",
                outcome: .completed,
                fields: [
                    .reason("handler_replaced_while_active"),
                    .int("activeSubscriptions", activeSubscriptions)
                ]
            )
        }
    }

    public func stop() {
        guard activeSubscriptions > 0 else {
            AppLog.debug(
                AppLog.input + AppLog.game,
                "CONTROLLER_INPUT_SOURCE",
                outcome: .ignored,
                fields: [
                    .reason("already_inactive")
                ]
            )
            return
        }

        activeSubscriptions -= 1
        guard activeSubscriptions == 0 else {
            AppLog.debug(
                AppLog.input + AppLog.game,
                "CONTROLLER_INPUT_SOURCE",
                outcome: .deferred,
                fields: [
                    .reason("other_subscribers_active"),
                    .int("activeSubscriptions", activeSubscriptions)
                ]
            )
            return
        }

        removeConnectionObservers()
        actionHandler = nil
        stickState = [:]
        AppLog.info(
            AppLog.input + AppLog.game,
            "CONTROLLER_INPUT_SOURCE",
            outcome: .completed
        )
    }

    // MARK: - Setup

    private func attachToConnectedControllers() {
        for controller in GCController.controllers() {
            attachInputHandlers(to: controller)
        }
    }

    private func observeControllerConnections() {
        connectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let controller = notification.object as? GCController else { return }
            Task { @MainActor [weak self] in
                self?.attachInputHandlers(to: controller)
            }
        }

        disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let controller = notification.object as? GCController else { return }
            Task { @MainActor [weak self] in
                self?.stickState.removeValue(forKey: ObjectIdentifier(controller))
                AppLog.debug(
                    AppLog.input + AppLog.game,
                    "CONTROLLER_DISCONNECTED",
                    outcome: .completed,
                    fields: [
                        .string("vendor", controller.vendorName ?? "unknown")
                    ]
                )
            }
        }
    }

    private func removeConnectionObservers() {
        if let obs = connectObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = disconnectObserver { NotificationCenter.default.removeObserver(obs) }
        connectObserver = nil
        disconnectObserver = nil
    }

    // MARK: - Per-controller handlers

    private func attachInputHandlers(to controller: GCController) {
        guard let gamepad = controller.extendedGamepad else {
            AppLog.debug(
                AppLog.input + AppLog.game,
                "CONTROLLER_ATTACH",
                outcome: .skipped,
                fields: [
                    .reason("no_extended_gamepad"),
                    .string("vendor", controller.vendorName ?? "unknown")
                ]
            )
            return
        }
        stickState[ObjectIdentifier(controller)] = StickHysteresisState()
        AppLog.info(
            AppLog.input + AppLog.game,
            "CONTROLLER_ATTACH",
            outcome: .started,
            fields: [
                .string("vendor", controller.vendorName ?? "unknown")
            ]
        )

        attachStickHandler(gamepad: gamepad, controllerID: ObjectIdentifier(controller))
        attachProfileDrivenHandlers(gamepad: gamepad)
    }

    /// Attaches the left-stick handler. The stick always emits move actions regardless of
    /// the binding profile — it acts as an analog backup to the d-pad.
    private func attachStickHandler(
        gamepad: GCExtendedGamepad,
        controllerID: ObjectIdentifier
    ) {
        guard platformConfig.capturesDirectionalInput else { return }

        gamepad.leftThumbstick.valueChangedHandler = { [weak self] _, xValue, _ in
            Task { @MainActor [weak self] in
                self?.handleStickX(xValue, controllerID: controllerID)
            }
        }
    }

    /// Attaches all buttons that route through the binding profile.
    ///
    /// D-pad and menu are included conditionally based on `platformConfig`, so tvOS
    /// does not capture inputs that are already handled by system focus/play-pause APIs.
    private func attachProfileDrivenHandlers(gamepad: GCExtendedGamepad) {
        var buttons: [(GCControllerButtonInput, GameControllerRemapButton)] = [
            (gamepad.buttonA, .a),
            (gamepad.buttonB, .b),
            (gamepad.buttonX, .x),
            (gamepad.buttonY, .y),
            (gamepad.leftShoulder, .leftShoulder),
            (gamepad.rightShoulder, .rightShoulder),
            (gamepad.leftTrigger, .leftTrigger),
            (gamepad.rightTrigger, .rightTrigger),
        ]

        if platformConfig.capturesDirectionalInput {
            buttons += [
                (gamepad.dpad.left, .dpadLeft),
                (gamepad.dpad.right, .dpadRight),
            ]
        }

        if platformConfig.capturesMenuButton {
            buttons.append((gamepad.buttonMenu, .menu))
        }

        for (button, remapButton) in buttons {
            button.pressedChangedHandler = { [weak self] _, _, pressed in
                guard pressed else { return }
                Task { @MainActor [weak self] in
                    self?.emitProfileAction(for: remapButton)
                }
            }
        }
    }

    // MARK: - Action emission

    private func handleStickX(_ x: Float, controllerID: ObjectIdentifier) {
        guard var state = stickState[controllerID] else { return }
        if let action = state.handleX(x) {
            stickState[controllerID] = state
            emit(action)
        } else {
            stickState[controllerID] = state
        }
    }

    private func emitProfileAction(for button: GameControllerRemapButton) {
        let profile = GameControllerBindingPreference.currentProfile(from: userDefaults)
        guard let remapAction = profile.action(for: button) else {
            AppLog.debug(
                AppLog.input + AppLog.game,
                "CONTROLLER_BUTTON_PRESS",
                outcome: .ignored,
                fields: [
                    .reason("button_not_mapped"),
                    .string("button", button.rawValue)
                ]
            )
            return
        }
        emit(GameControllerAction(remapAction))
    }

    private func emit(_ action: GameControllerAction) {
        guard let actionHandler else {
            AppLog.warning(
                AppLog.input + AppLog.game,
                "CONTROLLER_ACTION_EMIT",
                outcome: .failed,
                fields: [
                    .reason("missing_handler"),
                    .string("action", String(describing: action))
                ]
            )
            return
        }
        AppLog.debug(
            AppLog.input + AppLog.game,
            "CONTROLLER_ACTION_EMIT",
            outcome: .succeeded,
            fields: [
                .string("action", String(describing: action))
            ]
        )
        actionHandler(action)
    }
}

// MARK: - Stick hysteresis

/// Tracks analog stick state for a single controller, preventing repeated lane moves
/// while the stick is held in one direction.
private struct StickHysteresisState {
    private static let triggerThreshold: Float = 0.5
    private static let resetZone: Float = 0.2

    private var leftTriggered = false
    private var rightTriggered = false

    /// Returns a move action on the leading edge of a threshold crossing, nil otherwise.
    mutating func handleX(_ x: Float) -> GameControllerAction? {
        if x < -Self.triggerThreshold, !leftTriggered {
            leftTriggered = true
            rightTriggered = false
            return .moveLeft
        } else if x > Self.triggerThreshold, !rightTriggered {
            rightTriggered = true
            leftTriggered = false
            return .moveRight
        } else if abs(x) < Self.resetZone {
            leftTriggered = false
            rightTriggered = false
        }
        return nil
    }
}

#endif // !os(watchOS) && !os(visionOS)

//
//  GameView+GameControl.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI

#if canImport(UIKit) && os(iOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

// MARK: - Keyboard input (macOS / iOS)

#if os(macOS) || os(iOS)
/// Keyboard handling wrapper for the game area on macOS and iOS using a shared
/// hardware keyboard bridge.
struct GameAreaKeyboardModifier: ViewModifier {
    let inputAdapter: GameInputAdapter?
    var onMoveLeft: (() -> Void)?
    var onMoveRight: (() -> Void)?
    var onKeyboardInput: (() -> Void)?
    var onSwipeInput: (() -> Void)?
    var onTogglePause: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .background(
                HardwareKeyboardInputView(
                    onKeyboardLeft: {
                        AppLog.debug(
                            AppLog.input + AppLog.game,
                            "KEYBOARD_INPUT_RECEIVED",
                            outcome: .completed,
                            fields: [
                                .string("source", "hardware_bridge"),
                                .string("key", "left_arrow")
                            ]
                        )
                        onKeyboardInput?()
                        onMoveLeft?()
                        inputAdapter?.handleLeft()
                    },
                    onKeyboardRight: {
                        AppLog.debug(
                            AppLog.input + AppLog.game,
                            "KEYBOARD_INPUT_RECEIVED",
                            outcome: .completed,
                            fields: [
                                .string("source", "hardware_bridge"),
                                .string("key", "right_arrow")
                            ]
                        )
                        onKeyboardInput?()
                        onMoveRight?()
                        inputAdapter?.handleRight()
                    },
                    onSwipeLeft: {
                        AppLog.debug(
                            AppLog.input + AppLog.game,
                            "TRACKPAD_SWIPE_RECEIVED",
                            outcome: .completed,
                            fields: [
                                .string("source", "hardware_bridge"),
                                .string("direction", "left")
                            ]
                        )
                        onSwipeInput?()
                        onMoveLeft?()
                        inputAdapter?.handleLeft()
                    },
                    onSwipeRight: {
                        AppLog.debug(
                            AppLog.input + AppLog.game,
                            "TRACKPAD_SWIPE_RECEIVED",
                            outcome: .completed,
                            fields: [
                                .string("source", "hardware_bridge"),
                                .string("direction", "right")
                            ]
                        )
                        onSwipeInput?()
                        onMoveRight?()
                        inputAdapter?.handleRight()
                    },
                    onPauseToggle: {
                        AppLog.debug(
                            AppLog.input + AppLog.game,
                            "KEYBOARD_INPUT_RECEIVED",
                            outcome: .completed,
                            fields: [
                                .string("source", "hardware_bridge"),
                                .string("key", "space_bar")
                            ]
                        )
                        onTogglePause?()
                    }
                )
            )
    }
}
#else
struct GameAreaKeyboardModifier: ViewModifier {
    let inputAdapter: GameInputAdapter?
    var onMoveLeft: (() -> Void)?
    var onMoveRight: (() -> Void)?
    var onKeyboardInput: (() -> Void)?
    var onSwipeInput: (() -> Void)?
    var onTogglePause: (() -> Void)?

    func body(content: Content) -> some View {
        content
    }
}
#endif

// MARK: - Hardware keyboard bridge (iOS / macOS)

#if os(macOS) || os(iOS)
/// SwiftUI wrapper that hosts the platform-specific hardware keyboard bridge view.
struct HardwareKeyboardInputView: View {
    var onKeyboardLeft: () -> Void
    var onKeyboardRight: () -> Void
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void
    var onPauseToggle: () -> Void

    var body: some View {
        #if canImport(UIKit) && os(iOS)
        UIKitHardwareKeyboardInputView(
            onKeyboardLeft: onKeyboardLeft,
            onKeyboardRight: onKeyboardRight,
            onPauseToggle: onPauseToggle
        )
        #elseif os(macOS)
        AppKitHardwareKeyboardInputView(
            onKeyboardLeft: onKeyboardLeft,
            onKeyboardRight: onKeyboardRight,
            onSwipeLeft: onSwipeLeft,
            onSwipeRight: onSwipeRight,
            onPauseToggle: onPauseToggle
        )
        #endif
    }
}

#if canImport(UIKit) && os(iOS)
/// Invisible UIView that becomes first responder and listens for hardware arrow key commands (iOS).
private struct UIKitHardwareKeyboardInputView: UIViewRepresentable {
    var onKeyboardLeft: () -> Void
    var onKeyboardRight: () -> Void
    var onPauseToggle: () -> Void

    func makeUIView(context: Context) -> KeyInputView {
        let view = KeyInputView()
        view.backgroundColor = .clear
        view.onKeyboardLeft = onKeyboardLeft
        view.onKeyboardRight = onKeyboardRight
        view.onPauseToggle = onPauseToggle
        view.requestFirstResponder(reason: "make")
        return view
    }

    func updateUIView(_ uiView: KeyInputView, context: Context) {
        uiView.onKeyboardLeft = onKeyboardLeft
        uiView.onKeyboardRight = onKeyboardRight
        uiView.onPauseToggle = onPauseToggle
        uiView.requestFirstResponder(reason: "update")
    }

    final class KeyInputView: UIView {
        var onKeyboardLeft: (() -> Void)?
        var onKeyboardRight: (() -> Void)?
        var onPauseToggle: (() -> Void)?

        override var canBecomeFirstResponder: Bool { true }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            requestFirstResponder(reason: "didMoveToWindow")
        }

        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            requestFirstResponder(reason: "didMoveToSuperview")
        }

        override var keyCommands: [UIKeyCommand]? {
            let left = UIKeyCommand(
                input: UIKeyCommand.inputLeftArrow,
                modifierFlags: [],
                action: #selector(handleLeft)
            )
            let right = UIKeyCommand(
                input: UIKeyCommand.inputRightArrow,
                modifierFlags: [],
                action: #selector(handleRight)
            )
            let space = UIKeyCommand(input: " ", modifierFlags: [], action: #selector(handleSpace))
            if #available(iOS 15.0, *) {
                left.wantsPriorityOverSystemBehavior = true
                right.wantsPriorityOverSystemBehavior = true
                space.wantsPriorityOverSystemBehavior = true
            }
            return [left, right, space]
        }

        func requestFirstResponder(reason: String) {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.window != nil else { return }
                let became = self.becomeFirstResponder()
                AppLog.debug(
                    AppLog.input + AppLog.game,
                    "FIRST_RESPONDER_REQUEST",
                    outcome: .completed,
                    fields: [
                        .string("platform", "ios"),
                        .string("surface", "uikit_keyboard_input_view"),
                        .string("trigger", reason),
                        .bool("becameFirstResponder", became)
                    ]
                )
            }
        }

        @objc private func handleLeft() {
            AppLog.debug(
                AppLog.input + AppLog.game,
                "KEYBOARD_INPUT_RECEIVED",
                outcome: .completed,
                fields: [
                    .string("source", "uikit_key_command"),
                    .string("key", "left_arrow")
                ]
            )
            onKeyboardLeft?()
        }

        @objc private func handleRight() {
            AppLog.debug(
                AppLog.input + AppLog.game,
                "KEYBOARD_INPUT_RECEIVED",
                outcome: .completed,
                fields: [
                    .string("source", "uikit_key_command"),
                    .string("key", "right_arrow")
                ]
            )
            onKeyboardRight?()
        }

        @objc private func handleSpace() {
            AppLog.debug(
                AppLog.input + AppLog.game,
                "KEYBOARD_INPUT_RECEIVED",
                outcome: .completed,
                fields: [
                    .string("source", "uikit_key_command"),
                    .string("key", "space_bar")
                ]
            )
            onPauseToggle?()
        }
    }
}
#endif

#if os(macOS)
/// Invisible NSView that becomes first responder and listens for hardware arrow key events (macOS).
private struct AppKitHardwareKeyboardInputView: NSViewRepresentable {
    var onKeyboardLeft: () -> Void
    var onKeyboardRight: () -> Void
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void
    var onPauseToggle: () -> Void

    func makeNSView(context: Context) -> KeyInputView {
        let view = KeyInputView()
        view.onKeyboardLeft = onKeyboardLeft
        view.onKeyboardRight = onKeyboardRight
        view.onSwipeLeft = onSwipeLeft
        view.onSwipeRight = onSwipeRight
        view.onPauseToggle = onPauseToggle
        DispatchQueue.main.async {
            let became = view.window?.makeFirstResponder(view) ?? view.becomeFirstResponder()
            AppLog.debug(
                AppLog.input + AppLog.game,
                "FIRST_RESPONDER_REQUEST",
                outcome: .completed,
                fields: [
                    .string("platform", "macos"),
                    .string("surface", "appkit_keyboard_input_view"),
                    .string("trigger", "make"),
                    .bool("becameFirstResponder", became)
                ]
            )
        }
        return view
    }

    func updateNSView(_ nsView: KeyInputView, context: Context) {
        nsView.onKeyboardLeft = onKeyboardLeft
        nsView.onKeyboardRight = onKeyboardRight
        nsView.onSwipeLeft = onSwipeLeft
        nsView.onSwipeRight = onSwipeRight
        nsView.onPauseToggle = onPauseToggle
        DispatchQueue.main.async {
            let became = nsView.window?.makeFirstResponder(nsView) ?? nsView.becomeFirstResponder()
            AppLog.debug(
                AppLog.input + AppLog.game,
                "FIRST_RESPONDER_REQUEST",
                outcome: .completed,
                fields: [
                    .string("platform", "macos"),
                    .string("surface", "appkit_keyboard_input_view"),
                    .string("trigger", "update"),
                    .bool("becameFirstResponder", became)
                ]
            )
        }
    }

    final class KeyInputView: NSView {
        var onKeyboardLeft: (() -> Void)?
        var onKeyboardRight: (() -> Void)?
        var onSwipeLeft: (() -> Void)?
        var onSwipeRight: (() -> Void)?
        var onPauseToggle: (() -> Void)?
        private var swipeInterpreter = MacTrackpadSwipeInterpreter()

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            switch event.keyCode {
            case 123: // left arrow
                AppLog.debug(
                    AppLog.input + AppLog.game,
                    "KEYBOARD_INPUT_RECEIVED",
                    outcome: .completed,
                    fields: [
                        .string("source", "appkit_key_down"),
                        .string("key", "left_arrow")
                    ]
                )
                onKeyboardLeft?()
            case 124: // right arrow
                AppLog.debug(
                    AppLog.input + AppLog.game,
                    "KEYBOARD_INPUT_RECEIVED",
                    outcome: .completed,
                    fields: [
                        .string("source", "appkit_key_down"),
                        .string("key", "right_arrow")
                    ]
                )
                onKeyboardRight?()
            case 49: // space bar
                AppLog.debug(
                    AppLog.input + AppLog.game,
                    "KEYBOARD_INPUT_RECEIVED",
                    outcome: .completed,
                    fields: [
                        .string("source", "appkit_key_down"),
                        .string("key", "space_bar")
                    ]
                )
                onPauseToggle?()
            default:
                super.keyDown(with: event)
            }
        }

        override func scrollWheel(with event: NSEvent) {
            guard VoiceOverStatus.isVoiceOverRunning == false else {
                super.scrollWheel(with: event)
                return
            }
            guard event.hasPreciseScrollingDeltas else {
                super.scrollWheel(with: event)
                return
            }
            guard event.momentumPhase.isEmpty else {
                return
            }

            let phase = Self.swipePhase(from: event.phase)
            let action = swipeInterpreter.interpret(
                deltaX: event.scrollingDeltaX,
                deltaY: event.scrollingDeltaY,
                phase: phase,
                isDirectionInvertedFromDevice: event.isDirectionInvertedFromDevice,
                timestamp: event.timestamp
            )
            switch action {
            case .moveLeft:
                AppLog.debug(
                    AppLog.input + AppLog.game,
                    "TRACKPAD_SWIPE_RECEIVED",
                    outcome: .completed,
                    fields: [
                        .string("source", "appkit_scroll_wheel"),
                        .string("direction", "left")
                    ]
                )
                onSwipeLeft?()
            case .moveRight:
                AppLog.debug(
                    AppLog.input + AppLog.game,
                    "TRACKPAD_SWIPE_RECEIVED",
                    outcome: .completed,
                    fields: [
                        .string("source", "appkit_scroll_wheel"),
                        .string("direction", "right")
                    ]
                )
                onSwipeRight?()
            case nil:
                super.scrollWheel(with: event)
            }
        }

        private static func swipePhase(from phase: NSEvent.Phase) -> MacTrackpadSwipeInterpreter.Phase {
            if phase.contains(.began) {
                return .began
            }
            if phase.contains(.ended) {
                return .ended
            }
            if phase.contains(.cancelled) {
                return .cancelled
            }
            if phase.contains(.changed) || phase.contains(.stationary) {
                return .changed
            }
            return .none
        }
    }
}
#endif

#endif // os(macOS) || os(iOS)

// MARK: - Delegate implementation

/// Bridges GameScene callbacks to UI state updates and optional haptics.
final class GameSceneDelegateImpl: GameSceneDelegate {
    let onScoreUpdate: (Int) -> Void
    let onLevelChangeImminent: (Bool) -> Void
    let onCollision: () -> Void
    let onPauseStateChange: (Bool) -> Void
    let hapticController: HapticFeedbackController?

    init(
        onScoreUpdate: @escaping (Int) -> Void,
        onLevelChangeImminent: @escaping (Bool) -> Void,
        onCollision: @escaping () -> Void,
        onPauseStateChange: @escaping (Bool) -> Void,
        hapticController: HapticFeedbackController?
    ) {
        self.onScoreUpdate = onScoreUpdate
        self.onLevelChangeImminent = onLevelChangeImminent
        self.onCollision = onCollision
        self.onPauseStateChange = onPauseStateChange
        self.hapticController = hapticController
    }

    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        onScoreUpdate(score)
    }

    func gameScene(_ gameScene: GameScene, levelChangeImminent isImminent: Bool) {
        onLevelChangeImminent(isImminent)
    }

    func gameSceneDidDetectCollision(_ gameScene: GameScene) {
        onCollision()
    }

    func gameSceneDidUpdateGrid(_ gameScene: GameScene) {
        hapticController?.triggerGridUpdateHaptic()
    }

    func gameScene(_ gameScene: GameScene, didUpdatePauseState isPaused: Bool) {
        onPauseStateChange(isPaused)
    }

    func gameScene(_ gameScene: GameScene, didAchieveNewHighScore score: Int) {
        // Handled in view layer; no-op here to satisfy protocol.
    }
}

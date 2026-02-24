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
    var onTogglePause: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .background(
                HardwareKeyboardInputView(
                    onLeft: {
                        AppLog.info(AppLog.game, "🎮 Hardware keyboard left arrow received (bridge)")
                        onMoveLeft?()
                        inputAdapter?.handleLeft()
                    },
                    onRight: {
                        AppLog.info(AppLog.game, "🎮 Hardware keyboard right arrow received (bridge)")
                        onMoveRight?()
                        inputAdapter?.handleRight()
                    },
                    onPauseToggle: {
                        AppLog.info(AppLog.game, "🎮 Hardware keyboard space bar received (bridge)")
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
    var onLeft: () -> Void
    var onRight: () -> Void
    var onPauseToggle: () -> Void

    var body: some View {
        #if canImport(UIKit) && os(iOS)
        UIKitHardwareKeyboardInputView(onLeft: onLeft, onRight: onRight, onPauseToggle: onPauseToggle)
        #elseif os(macOS)
        AppKitHardwareKeyboardInputView(onLeft: onLeft, onRight: onRight, onPauseToggle: onPauseToggle)
        #endif
    }
}

#if canImport(UIKit) && os(iOS)
/// Invisible UIView that becomes first responder and listens for hardware arrow key commands (iOS).
private struct UIKitHardwareKeyboardInputView: UIViewRepresentable {
    var onLeft: () -> Void
    var onRight: () -> Void
    var onPauseToggle: () -> Void

    func makeUIView(context: Context) -> KeyInputView {
        let view = KeyInputView()
        view.backgroundColor = .clear
        view.onLeft = onLeft
        view.onRight = onRight
        view.onPauseToggle = onPauseToggle
        DispatchQueue.main.async {
            let became = view.becomeFirstResponder()
            AppLog.info(AppLog.game, "🎮 UIKitHardwareKeyboardInputView becomeFirstResponder (make) = \(became)")
        }
        return view
    }

    func updateUIView(_ uiView: KeyInputView, context: Context) {
        uiView.onLeft = onLeft
        uiView.onRight = onRight
        uiView.onPauseToggle = onPauseToggle
        DispatchQueue.main.async {
            let became = uiView.becomeFirstResponder()
            AppLog.info(AppLog.game, "🎮 UIKitHardwareKeyboardInputView becomeFirstResponder (update) = \(became)")
        }
    }

    final class KeyInputView: UIView {
        var onLeft: (() -> Void)?
        var onRight: (() -> Void)?
        var onPauseToggle: (() -> Void)?

        override var canBecomeFirstResponder: Bool { true }

        override var keyCommands: [UIKeyCommand]? {
            [
                UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(handleLeft)),
                UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(handleRight)),
                UIKeyCommand(input: " ", modifierFlags: [], action: #selector(handleSpace))
            ]
        }

        @objc private func handleLeft() {
            AppLog.info(AppLog.game, "🎮 UIKeyCommand left arrow received (UIKit view)")
            onLeft?()
        }

        @objc private func handleRight() {
            AppLog.info(AppLog.game, "🎮 UIKeyCommand right arrow received (UIKit view)")
            onRight?()
        }

        @objc private func handleSpace() {
            AppLog.info(AppLog.game, "🎮 UIKeyCommand space bar received (UIKit view)")
            onPauseToggle?()
        }
    }
}
#endif

#if os(macOS)
/// Invisible NSView that becomes first responder and listens for hardware arrow key events (macOS).
private struct AppKitHardwareKeyboardInputView: NSViewRepresentable {
    var onLeft: () -> Void
    var onRight: () -> Void
    var onPauseToggle: () -> Void

    func makeNSView(context: Context) -> KeyInputView {
        let view = KeyInputView()
        view.onLeft = onLeft
        view.onRight = onRight
        view.onPauseToggle = onPauseToggle
        DispatchQueue.main.async {
            let became = view.window?.makeFirstResponder(view) ?? view.becomeFirstResponder()
            AppLog.info(AppLog.game, "🎮 AppKitHardwareKeyboardInputView becomeFirstResponder (make) = \(became)")
        }
        return view
    }

    func updateNSView(_ nsView: KeyInputView, context: Context) {
        nsView.onLeft = onLeft
        nsView.onRight = onRight
        nsView.onPauseToggle = onPauseToggle
        DispatchQueue.main.async {
            let became = nsView.window?.makeFirstResponder(nsView) ?? nsView.becomeFirstResponder()
            AppLog.info(AppLog.game, "🎮 AppKitHardwareKeyboardInputView becomeFirstResponder (update) = \(became)")
        }
    }

    final class KeyInputView: NSView {
        var onLeft: (() -> Void)?
        var onRight: (() -> Void)?
        var onPauseToggle: (() -> Void)?
        private var swipeInterpreter = MacTrackpadSwipeInterpreter()

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            switch event.keyCode {
            case 123: // left arrow
                AppLog.info(AppLog.game, "🎮 keyDown left arrow received (AppKit view)")
                onLeft?()
            case 124: // right arrow
                AppLog.info(AppLog.game, "🎮 keyDown right arrow received (AppKit view)")
                onRight?()
            case 49: // space bar
                AppLog.info(AppLog.game, "🎮 keyDown space bar received (AppKit view)")
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
            guard event.momentumPhase == .none else {
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
                AppLog.info(AppLog.game, "🎮 macOS trackpad swipe left received")
                onLeft?()
            case .moveRight:
                AppLog.info(AppLog.game, "🎮 macOS trackpad swipe right received")
                onRight?()
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

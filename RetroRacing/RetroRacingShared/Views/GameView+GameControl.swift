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

    var body: some View {
        #if canImport(UIKit) && os(iOS)
        UIKitHardwareKeyboardInputView(onLeft: onLeft, onRight: onRight)
        #elseif os(macOS)
        AppKitHardwareKeyboardInputView(onLeft: onLeft, onRight: onRight)
        #endif
    }
}

#if canImport(UIKit) && os(iOS)
/// Invisible UIView that becomes first responder and listens for hardware arrow key commands (iOS).
private struct UIKitHardwareKeyboardInputView: UIViewRepresentable {
    var onLeft: () -> Void
    var onRight: () -> Void

    func makeUIView(context: Context) -> KeyInputView {
        let view = KeyInputView()
        view.backgroundColor = .clear
        view.onLeft = onLeft
        view.onRight = onRight
        DispatchQueue.main.async {
            let became = view.becomeFirstResponder()
            AppLog.info(AppLog.game, "🎮 UIKitHardwareKeyboardInputView becomeFirstResponder (make) = \(became)")
        }
        return view
    }

    func updateUIView(_ uiView: KeyInputView, context: Context) {
        uiView.onLeft = onLeft
        uiView.onRight = onRight
        DispatchQueue.main.async {
            let became = uiView.becomeFirstResponder()
            AppLog.info(AppLog.game, "🎮 UIKitHardwareKeyboardInputView becomeFirstResponder (update) = \(became)")
        }
    }

    final class KeyInputView: UIView {
        var onLeft: (() -> Void)?
        var onRight: (() -> Void)?

        override var canBecomeFirstResponder: Bool { true }

        override var keyCommands: [UIKeyCommand]? {
            [
                UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(handleLeft)),
                UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(handleRight))
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
    }
}
#endif

#if os(macOS)
/// Invisible NSView that becomes first responder and listens for hardware arrow key events (macOS).
private struct AppKitHardwareKeyboardInputView: NSViewRepresentable {
    var onLeft: () -> Void
    var onRight: () -> Void

    func makeNSView(context: Context) -> KeyInputView {
        let view = KeyInputView()
        view.onLeft = onLeft
        view.onRight = onRight
        DispatchQueue.main.async {
            let became = view.window?.makeFirstResponder(view) ?? view.becomeFirstResponder()
            AppLog.info(AppLog.game, "🎮 AppKitHardwareKeyboardInputView becomeFirstResponder (make) = \(became)")
        }
        return view
    }

    func updateNSView(_ nsView: KeyInputView, context: Context) {
        nsView.onLeft = onLeft
        nsView.onRight = onRight
        DispatchQueue.main.async {
            let became = nsView.window?.makeFirstResponder(nsView) ?? nsView.becomeFirstResponder()
            AppLog.info(AppLog.game, "🎮 AppKitHardwareKeyboardInputView becomeFirstResponder (update) = \(became)")
        }
    }

    final class KeyInputView: NSView {
        var onLeft: (() -> Void)?
        var onRight: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            switch event.keyCode {
            case 123: // left arrow
                AppLog.info(AppLog.game, "🎮 keyDown left arrow received (AppKit view)")
                onLeft?()
            case 124: // right arrow
                AppLog.info(AppLog.game, "🎮 keyDown right arrow received (AppKit view)")
                onRight?()
            default:
                super.keyDown(with: event)
            }
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

//
//  GameView+Navigation.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI
#if os(iOS)
import UIKit

/// Disables the iOS interactive pop (swipe-back) gesture while the game view is visible so drag controls
/// are not intercepted by the navigation controller. Restores the previous state on exit.
struct InteractivePopGestureDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {}

    final class Controller: UIViewController {
        private var previousEnabled: Bool?

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
            previousEnabled = gesture.isEnabled
            gesture.isEnabled = false
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            restoreGestureState()
        }

        deinit {
            restoreGestureState()
        }

        private func restoreGestureState() {
            guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
            // Default back to enabled if we never captured a prior state.
            gesture.isEnabled = previousEnabled ?? true
        }
    }
}
#endif

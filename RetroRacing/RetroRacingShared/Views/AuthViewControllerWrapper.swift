//
//  AuthViewControllerWrapper.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Presents an arbitrary UIViewController in a full-screen cover (e.g. Game Center sign-in).
struct AuthViewControllerWrapper: UIViewControllerRepresentable {
    let viewController: UIViewController
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> AuthContainerViewController {
        let container = AuthContainerViewController()
        container.authViewController = viewController
        container.onDismiss = onDismiss
        return container
    }

    func updateUIViewController(_ uiViewController: AuthContainerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: AuthContainerViewController, coordinator: ()) {
        uiViewController.onDismiss?()
    }
}

final class AuthContainerViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    weak var authViewController: UIViewController?
    var onDismiss: (() -> Void)?
    private var hasPresentedAuthentication = false
    private var hasFinishedAuthentication = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard hasFinishedAuthentication == false else { return }
        if hasPresentedAuthentication {
            guard presentedViewController == nil else { return }
            finishAuthenticationPresentation()
            return
        }
        guard let vc = authViewController, presentedViewController == nil else { return }
        hasPresentedAuthentication = true
        present(vc, animated: true) { [weak self] in
            vc.presentationController?.delegate = self
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finishAuthenticationPresentation()
    }

    private func finishAuthenticationPresentation() {
        guard hasFinishedAuthentication == false else { return }
        hasFinishedAuthentication = true
        onDismiss?()
    }
}
#endif

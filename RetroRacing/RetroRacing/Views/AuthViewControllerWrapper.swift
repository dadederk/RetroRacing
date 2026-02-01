import SwiftUI

#if canImport(UIKit)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let vc = authViewController, presentedViewController == nil {
            present(vc, animated: true) { [weak self] in
                vc.presentationController?.delegate = self
            }
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismiss?()
    }
}
#endif

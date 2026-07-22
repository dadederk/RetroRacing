//
//  SharePlayActivitySharingPresenter.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// Token for presenting the system SharePlay sharing UI. A fresh identity is created for each
/// tap on **Play with Friends** so re-presenting works after dismiss.
public struct SharePlaySharingPresentation: Identifiable {
    public let id = UUID()

    public init() {}
}

#if canImport(GroupActivities) && os(iOS)
import GroupActivities
import SwiftUI
import UIKit

/// Presents the system `GroupActivitySharingController` as a native UIKit modal, driven by a
/// hidden SwiftUI-hosted UIKit presenter on the menu. Used when
/// the device isn't currently in a FaceTime call or Messages conversation
/// (`GroupStateObserver.isEligibleForGroupSession == false`); it lets the person pick
/// participants and starts the call on their behalf. The resulting session is delivered through
/// the same `RetroRacingGroupActivity.sessions()` stream as a direct `activate()` call.
///
/// `GroupActivitySharingController` manages its own sheet chrome and renders incorrectly when
/// embedded as the content of a SwiftUI `.sheet`. Presenting it via `UIViewController.present`
/// from a dedicated invisible host avoids double chrome and avoids leaving a blank full-screen
/// SwiftUI cover behind when the system sheet is dismissed.
public struct SharePlayActivitySharingPresenter: UIViewControllerRepresentable {
    var onUserDismissed: (() -> Void)?

    public init(onUserDismissed: (() -> Void)? = nil) {
        self.onUserDismissed = onUserDismissed
    }

    public func makeUIViewController(context: Context) -> SharePlayActivitySharingHostController {
        let host = SharePlayActivitySharingHostController()
        host.onUserDismissed = onUserDismissed
        return host
    }

    public func updateUIViewController(_ uiViewController: SharePlayActivitySharingHostController, context: Context) {
        uiViewController.onUserDismissed = onUserDismissed
    }

    public static func dismantleUIViewController(_ uiViewController: SharePlayActivitySharingHostController, coordinator: ()) {
        uiViewController.onUserDismissed = nil
        uiViewController.dismissPresentedSharingControllerIfNeeded()
    }
}

/// Invisible host that owns the UIKit presentation of `GroupActivitySharingController`,
/// matching the `AuthContainerViewController` pattern used for Game Center sign-in.
public final class SharePlayActivitySharingHostController: UIViewController, UIAdaptivePresentationControllerDelegate {
    var onUserDismissed: (() -> Void)?
    private var hasAttemptedPresentation = false
    private var hasReportedDismissal = false

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentSharingControllerIfNeeded()
    }

    private func presentSharingControllerIfNeeded() {
        guard hasAttemptedPresentation == false else { return }
        guard presentedViewController == nil else { return }
        guard view.window != nil else { return }
        hasAttemptedPresentation = true

        guard let controller = try? GroupActivitySharingController(RetroRacingGroupActivity()) else {
            AppLog.error(AppLog.game, "SHAREPLAY_SHARING_CONTROLLER", outcome: .failed)
            notifyUserDismissed()
            return
        }

        present(controller, animated: true) { [weak controller] in
            controller?.presentationController?.delegate = self
        }
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        notifyUserDismissed()
    }

    func dismissPresentedSharingControllerIfNeeded() {
        presentedViewController?.dismiss(animated: false)
    }

    private func notifyUserDismissed() {
        guard hasReportedDismissal == false else { return }
        hasReportedDismissal = true
        onUserDismissed?()
    }
}
#endif

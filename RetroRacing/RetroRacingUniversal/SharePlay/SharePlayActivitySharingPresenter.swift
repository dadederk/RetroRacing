//
//  SharePlayActivitySharingPresenter.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation
import RetroRacingShared

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
    let presentationID: UUID
    var onUserDismissed: (() -> Void)?

    public init(presentationID: UUID, onUserDismissed: (() -> Void)? = nil) {
        self.presentationID = presentationID
        self.onUserDismissed = onUserDismissed
    }

    public func makeUIViewController(context: Context) -> SharePlayActivitySharingHostController {
        let host = SharePlayActivitySharingHostController()
        host.configure(presentationID: presentationID, onUserDismissed: onUserDismissed)
        return host
    }

    public func updateUIViewController(_ uiViewController: SharePlayActivitySharingHostController, context: Context) {
        uiViewController.configure(presentationID: presentationID, onUserDismissed: onUserDismissed)
    }

    public static func dismantleUIViewController(_ uiViewController: SharePlayActivitySharingHostController, coordinator: ()) {
        uiViewController.prepareForDismantle()
    }
}

/// Invisible host that owns the UIKit presentation of `GroupActivitySharingController`,
/// matching the `AuthContainerViewController` pattern used for Game Center sign-in.
public final class SharePlayActivitySharingHostController: UIViewController, UIAdaptivePresentationControllerDelegate {
    private var presentationID: UUID?
    private var onUserDismissed: (() -> Void)?
    private var sharingResultTask: Task<Void, Never>?
    private var hasAttemptedPresentation = false
    private var hasReportedDismissal = false
    private var isReplacingPresentation = false

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if hasAttemptedPresentation,
           presentedViewController == nil,
           sharingResultTask == nil,
           hasReportedDismissal == false {
            notifyUserDismissed()
            return
        }
        presentSharingControllerIfNeeded()
    }

    func configure(presentationID: UUID, onUserDismissed: (() -> Void)?) {
        self.onUserDismissed = onUserDismissed
        guard self.presentationID != presentationID else {
            presentSharingControllerIfNeeded()
            return
        }

        self.presentationID = presentationID
        hasAttemptedPresentation = false
        hasReportedDismissal = false
        cancelSharingResultObservation()

        guard let presentedViewController else {
            presentSharingControllerIfNeeded()
            return
        }

        isReplacingPresentation = true
        presentedViewController.dismiss(animated: false) { [weak self] in
            guard let self else { return }
            isReplacingPresentation = false
            presentSharingControllerIfNeeded()
        }
    }

    private func presentSharingControllerIfNeeded() {
        guard hasAttemptedPresentation == false else { return }
        guard presentedViewController == nil else { return }
        guard view.window != nil else { return }
        hasAttemptedPresentation = true

        guard let controller = try? GroupActivitySharingController(RetroRacingGroupActivity()) else {
            AppLog.error(.game, "SHAREPLAY_SHARING_CONTROLLER", outcome: .failed)
            notifyUserDismissed()
            return
        }

        controller.presentationController?.delegate = self
        observeResult(for: controller)
        present(controller, animated: true) { [weak controller] in
            controller?.presentationController?.delegate = self
        }
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard isReplacingPresentation == false else { return }
        guard sharingResultTask == nil else { return }
        notifyUserDismissed()
    }

    func dismissPresentedSharingControllerIfNeeded() {
        presentedViewController?.dismiss(animated: false)
    }

    func prepareForDismantle() {
        onUserDismissed = nil
        cancelSharingResultObservation()
        dismissPresentedSharingControllerIfNeeded()
    }

    private func observeResult(for controller: GroupActivitySharingController) {
        cancelSharingResultObservation()
        sharingResultTask = Task { [weak self, controller] in
            let result = await controller.result
            guard Task.isCancelled == false else { return }
            self?.handleSharingResult(result)
        }
    }

    private func handleSharingResult(_ result: GroupActivitySharingResult) {
        sharingResultTask = nil
        switch result {
        case .success:
            hasReportedDismissal = true
        case .cancelled:
            notifyUserDismissed()
        @unknown default:
            notifyUserDismissed()
        }
    }

    private func cancelSharingResultObservation() {
        sharingResultTask?.cancel()
        sharingResultTask = nil
    }

    private func notifyUserDismissed() {
        guard hasReportedDismissal == false else { return }
        hasReportedDismissal = true
        onUserDismissed?()
    }
}
#endif

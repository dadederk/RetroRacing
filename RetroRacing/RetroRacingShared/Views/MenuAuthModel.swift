//
//  MenuAuthModel.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI
import Observation
#if canImport(GameKit) && !os(watchOS)
import GameKit
#endif
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

@MainActor
@Observable
final class MenuAuthModel {
    enum AuthState: Equatable {
        case idle
        case authenticating
        case authenticated
        case failed
    }

    enum LeaderboardRequestResult: Equatable {
        case present(leaderboardID: String)
        case authenticationRequested
        case unavailable
    }

    var authState: AuthState = .idle
    var authError: String?
    private var authTimeoutTask: Task<Void, Never>?
    private var hasAttemptedAutomaticAuthentication = false
    private var acceptsAuthenticationPresentation = true
    private var pendingLeaderboardID: String?

    #if canImport(UIKit) && !os(watchOS)
    var authViewControllerToPresent: UIViewController?
    #endif

    private let gameCenterService: GameCenterService
    private let authenticationPresenter: AuthenticationPresenter

    init(
        gameCenterService: GameCenterService,
        authenticationPresenter: AuthenticationPresenter
    ) {
        self.gameCenterService = gameCenterService
        self.authenticationPresenter = authenticationPresenter
    }

    var isAuthenticated: Bool {
        #if os(macOS)
        // On macOS, rely on the system-level Game Center login and always
        // allow the user to attempt to open the leaderboard. The Game Center
        // UI (via GKAccessPoint in `LeaderboardView`) will handle any
        // authentication prompts as needed.
        true
        #else
        authState == .authenticated
        #endif
    }

    #if canImport(UIKit) && !os(watchOS)
    func configurePresentationHandler() {
        guard let presenter = authenticationPresenter as? UIKitAuthenticationPresenter else { return }
        presenter.setPresentationHandler { [weak self] viewController in
            guard let self, self.acceptsAuthenticationPresentation else {
                AppLog.info(
                    AppLog.leaderboard + AppLog.lifecycle,
                    "AUTH_PRESENTATION",
                    outcome: .skipped,
                    fields: [.reason("previous_presentation_dismissed")]
                )
                return
            }
            self.authViewControllerToPresent = viewController
        }
    }

    func authenticationPresentationDidDismiss() {
        acceptsAuthenticationPresentation = false
        authViewControllerToPresent = nil
    }

    /// Resolves the authentication result only after SwiftUI has fully dismissed its cover.
    /// This prevents Game Center from trying to present the leaderboard over another presentation.
    func authenticationCoverDidDismiss() {
        refreshAuthState()
        cancelAuthTimeout()
        guard isAuthenticated == false else { return }

        let hadPendingLeaderboard = pendingLeaderboardID != nil
        pendingLeaderboardID = nil
        guard authState != .failed else { return }

        authState = .idle
        if hadPendingLeaderboard {
            authError = GameLocalizedStrings.string("Sign in to Game Center to view the leaderboard.")
            AppLog.info(
                AppLog.leaderboard + AppLog.lifecycle,
                "AUTH_REQUEST",
                outcome: .cancelled,
                fields: [.reason("authentication_ui_dismissed")]
            )
        }
    }
    #else
    func configurePresentationHandler() { }
    #endif

    #if canImport(GameKit) && !os(watchOS)
    /// Presents Game Center leaderboard using the modern access point trigger without showing an empty modal.
    func presentLeaderboard(leaderboardID: String) {
        guard GKAccessPoint.shared.isPresentingGameCenter == false else {
            AppLog.info(
                AppLog.leaderboard + AppLog.lifecycle,
                "ACCESS_POINT_TRIGGER",
                outcome: .skipped,
                fields: [.reason("already_presenting")]
            )
            return
        }
        GKAccessPoint.shared.trigger(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        ) {
            AppLog.debug(
                AppLog.leaderboard + AppLog.lifecycle,
                "ACCESS_POINT_TRIGGER",
                outcome: .completed
            )
            self.refreshAuthState()
        }
    }

    func requestLeaderboardPresentation(leaderboardID: String) -> LeaderboardRequestResult {
        authError = nil
        refreshAuthState()

        if isAuthenticated {
            return .present(leaderboardID: leaderboardID)
        }

        guard authState != .failed else {
            pendingLeaderboardID = nil
            return .unavailable
        }

        pendingLeaderboardID = leaderboardID
        startAuthentication(startedByUser: true)
        return .authenticationRequested
    }

    /// Returns a deferred leaderboard request exactly once, after authentication succeeds and
    /// any authentication cover is gone.
    func takePendingLeaderboardIDIfReady() -> String? {
        guard isAuthenticated else { return nil }
        #if canImport(UIKit) && !os(watchOS)
        guard authViewControllerToPresent == nil else { return nil }
        #endif
        guard let pendingLeaderboardID else { return nil }

        self.pendingLeaderboardID = nil
        cancelAuthTimeout()
        return pendingLeaderboardID
    }

    func startAuthentication(startedByUser: Bool) {
        refreshAuthState()
        guard authState != .authenticated, authState != .failed else { return }
        if startedByUser == false {
            guard hasAttemptedAutomaticAuthentication == false else {
                AppLog.info(
                    AppLog.leaderboard + AppLog.lifecycle,
                    "AUTH_REQUEST",
                    outcome: .skipped,
                    fields: [.reason("automatic_attempt_already_completed")]
                )
                return
            }
            hasAttemptedAutomaticAuthentication = true
        } else {
            acceptsAuthenticationPresentation = true
        }
        authState = .authenticating
        if startedByUser {
            AppLog.info(
                AppLog.leaderboard + AppLog.lifecycle,
                "AUTH_REQUEST",
                outcome: .requested,
                fields: [.string("trigger", "leaderboard_tap")]
            )
        } else {
            AppLog.info(
                AppLog.leaderboard + AppLog.lifecycle,
                "AUTH_REQUEST",
                outcome: .requested,
                fields: [.string("trigger", "view_appear")]
            )
        }
        gameCenterService.authenticate(presenter: authenticationPresenter)
        scheduleAuthTimeout()
    }

    func authenticationStateDidChange(error: Error?) {
        refreshAuthState()
        if isAuthenticated {
            cancelAuthTimeout()
            return
        }

        guard let error else { return }
        let hadPendingLeaderboard = pendingLeaderboardID != nil
        pendingLeaderboardID = nil
        cancelAuthTimeout()

        if authState != .failed {
            authState = .idle
            if hadPendingLeaderboard {
                authError = GameLocalizedStrings.string("Sign in to Game Center to view the leaderboard.")
            }
        }

        AppLog.warning(
            AppLog.leaderboard + AppLog.lifecycle,
            "AUTH_REQUEST",
            outcome: .failed,
            fields: [.reason("gamekit_error")] + AppLog.Field.error(error)
        )
    }

    func refreshAuthState() {
        if gameCenterService.isAuthenticated() {
            authState = .authenticated
            authError = nil
            AppLog.info(
                AppLog.leaderboard + AppLog.lifecycle,
                "AUTH_STATE_REFRESH",
                outcome: .succeeded
            )
        } else {
            authState = .idle
            if GKLocalPlayer.local.isUnderage {
                authError = GameLocalizedStrings.string("Game Center is unavailable for this account.")
                authState = .failed
                AppLog.warning(
                    AppLog.leaderboard + AppLog.lifecycle,
                    "AUTH_STATE_REFRESH",
                    outcome: .blocked,
                    fields: [.reason("underage_account")]
                )
            }
        }
    }

    /// Prevents the spinner from hanging forever if Game Center never calls back.
    func scheduleAuthTimeout() {
        authTimeoutTask?.cancel()
        authTimeoutTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(8))
            } catch {
                return
            }
            authenticationDidTimeOut()
        }
    }

    func authenticationDidTimeOut() {
        cancelAuthTimeout()
        refreshAuthState()
        guard isAuthenticated == false else { return }

        let hadPendingLeaderboard = pendingLeaderboardID != nil
        pendingLeaderboardID = nil
        if authState != .failed {
            authState = .idle
            if hadPendingLeaderboard {
                authError = GameLocalizedStrings.string("Sign in to Game Center to view the leaderboard.")
            }
        }

        AppLog.warning(
            AppLog.leaderboard + AppLog.lifecycle,
            "AUTH_REQUEST",
            outcome: .failed,
            fields: [.reason("timeout")]
        )
    }

    @discardableResult
    func cancelAuthTimeout() -> Task<Void, Never>? {
        let task = authTimeoutTask
        authTimeoutTask = nil
        task?.cancel()
        return task
    }
    #else
    func presentLeaderboard(leaderboardID: String) { }
    func requestLeaderboardPresentation(leaderboardID: String) -> LeaderboardRequestResult { .unavailable }
    func takePendingLeaderboardIDIfReady() -> String? { nil }
    func startAuthentication(startedByUser: Bool) { }
    func authenticationStateDidChange(error: Error?) { }
    func refreshAuthState() { }
    func scheduleAuthTimeout() { }
    func authenticationDidTimeOut() { }
    @discardableResult
    func cancelAuthTimeout() -> Task<Void, Never>? { nil }
    #endif
}

#if canImport(UIKit) && !os(watchOS)
struct IdentifiableVC: Identifiable {
    let id: ObjectIdentifier
    let vc: UIViewController

    init(vc: UIViewController) {
        self.id = ObjectIdentifier(vc)
        self.vc = vc
    }
}
#endif

/// Presents leaderboard wrappers where needed (iOS/tvOS).
struct LeaderboardPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let leaderboardID: String

    func body(content: Content) -> some View {
        #if canImport(UIKit) && !os(watchOS)
        content
            .fullScreenCover(isPresented: $isPresented) {
                LeaderboardView(leaderboardID: leaderboardID) {
                    isPresented = false
                }
            }
        #elseif os(macOS)
        content
        #else
        content
            .sheet(isPresented: $isPresented) {
                LeaderboardView(leaderboardID: leaderboardID) {
                    isPresented = false
                }
            }
        #endif
    }
}

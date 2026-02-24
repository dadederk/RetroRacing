//
//  MenuAuthModel.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI
import Observation
#if canImport(UIKit) && !os(watchOS)
import GameKit
import UIKit
#endif

@MainActor
@Observable
final class MenuAuthModel {
    enum AuthState {
        case idle
        case authenticating
        case authenticated
        case failed
    }

    var authState: AuthState = .idle
    var authError: String?

    #if canImport(UIKit) && !os(watchOS)
    var authViewControllerToPresent: UIViewController?
    private var authTimeoutTask: Task<Void, Never>?
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
            self?.authViewControllerToPresent = viewController
        }
    }

    /// Presents Game Center leaderboard using the modern access point trigger without showing an empty modal.
    func presentLeaderboard(leaderboardID: String) {
        GKAccessPoint.shared.trigger(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        ) {
            AppLog.info(AppLog.game, "GC access point handler finished; refreshing auth state")
            self.refreshAuthState()
        }
    }

    func startAuthentication(startedByUser: Bool) {
        refreshAuthState()
        guard authState != .authenticated else { return }
        authState = .authenticating
        if startedByUser {
            AppLog.info(AppLog.game, "🔐 Starting Game Center authentication from leaderboard tap")
        } else {
            AppLog.info(AppLog.game, "🔐 Starting Game Center authentication on appear")
        }
        gameCenterService.authenticate(presenter: authenticationPresenter)
        scheduleAuthTimeout()
    }

    func refreshAuthState() {
        if GKLocalPlayer.local.isAuthenticated {
            authState = .authenticated
            authError = nil
            AppLog.info(AppLog.game, "✅ Game Center authenticated")
        } else {
            authState = .idle
            if GKLocalPlayer.local.isUnderage {
                authError = GameLocalizedStrings.string("Game Center is unavailable for this account.")
                authState = .failed
                AppLog.error(AppLog.game, "🚫 Game Center unavailable: underage account")
            }
        }
    }

    /// Prevents the spinner from hanging forever if Game Center never calls back.
    func scheduleAuthTimeout() {
        authTimeoutTask?.cancel()
        authTimeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(8))
            if authState == .authenticating {
                refreshAuthState()
                guard authState == .authenticating else { return }
                AppLog.error(AppLog.game, "⌛️ Game Center auth timed out; resetting state")
                authState = .idle
            }
        }
    }

    func cancelAuthTimeout() {
        authTimeoutTask?.cancel()
        authTimeoutTask = nil
    }
    #else
    func configurePresentationHandler() { }
    func presentLeaderboard(leaderboardID: String) { }
    func startAuthentication(startedByUser: Bool) { }
    func refreshAuthState() { }
    func scheduleAuthTimeout() { }
    func cancelAuthTimeout() { }
    #endif
}

#if canImport(UIKit) && !os(watchOS)
struct IdentifiableVC: Identifiable {
    let id = UUID()
    let vc: UIViewController
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

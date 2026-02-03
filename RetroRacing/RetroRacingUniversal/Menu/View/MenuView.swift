//
//  MenuView.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
import RetroRacingShared
import GameKit
#if os(macOS)
import StoreKit
#endif

/// Root menu for launching gameplay, viewing leaderboards, and accessing settings.
struct MenuView: View {
    let leaderboardService: LeaderboardService
    let gameCenterService: GameCenterService
    let ratingService: RatingService
    let leaderboardConfiguration: LeaderboardConfiguration
    let authenticationPresenter: AuthenticationPresenter
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    let hapticController: HapticFeedbackController
    /// Injected by app; when false, haptic setting is hidden (device has no haptics).
    let supportsHapticFeedback: Bool

    #if os(macOS)
    @Environment(\.requestReview) private var requestReview
    #endif
    @State private var showGame = false
    @State private var showLeaderboard = false
    @State private var showSettings = false
    #if canImport(UIKit)
    @State private var authViewControllerToPresent: UIViewController?
    #endif
    @State private var authState: AuthState = .idle
    @State private var authError: String?

    private enum AuthState {
        case idle
        case authenticating
        case authenticated
        case failed
    }

    private static var settingsToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .primaryAction
        #else
        .topBarTrailing
        #endif
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(GameLocalizedStrings.string("gameName"))
                    .font(fontPreferenceStore.font(size: 27))
                    .dynamicTypeSize(.xSmall ... .xxxLarge)
                    .padding(.bottom, 40)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 24) {
                    menuPlayButton
                    menuLeaderboardButton
                    menuRateButton
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: Self.settingsToolbarPlacement) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(GameLocalizedStrings.string("settings"))
                    #if os(macOS)
                    .keyboardShortcut(",", modifiers: .command)
                    #endif
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(themeManager: themeManager, fontPreferenceStore: fontPreferenceStore, supportsHapticFeedback: supportsHapticFeedback)
            }
            .navigationDestination(isPresented: $showGame) {
                GameView(
                    leaderboardService: leaderboardService,
                    ratingService: ratingService,
                    theme: themeManager.currentTheme,
                    hapticController: hapticController,
                    fontPreferenceStore: fontPreferenceStore
                )
            }
#if os(macOS)
            .modifier(LeaderboardPresentationModifier(
                isPresented: $showLeaderboard,
                leaderboardID: leaderboardConfiguration.leaderboardID
            ))
#endif
            #if canImport(UIKit)
            .fullScreenCover(item: authVCItem) { item in
                AuthViewControllerWrapper(viewController: item.vc) {
                    authViewControllerToPresent = nil
                }
            }
            #endif
        }
        .onAppear {
            #if canImport(UIKit)
            if let universalPresenter = authenticationPresenter as? AuthenticationPresenterUniversal {
                universalPresenter.onPresent = { [self] vc in
                    authViewControllerToPresent = vc
                }
            }
            // Start authentication as early as possible (UIKit platforms).
            startAuthentication(startedByUser: false)
            #endif
        }
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)) { _ in
            refreshAuthState()
        }
        #endif
    }

    @ViewBuilder
    private var menuPlayButton: some View {
        Button {
            showGame = true
        } label: {
            Text(GameLocalizedStrings.string("play"))
                .font(fontPreferenceStore.font(size: 18))
        }
        .buttonStyle(.glassProminent)
    }

    @ViewBuilder
    private var menuLeaderboardButton: some View {
        Button {
            authError = nil
#if canImport(UIKit)
            presentLeaderboard()
#else
            showLeaderboard = true
#endif
        } label: {
            Text(GameLocalizedStrings.string("leaderboard"))
                .font(fontPreferenceStore.font(size: 18))
        }
        .buttonStyle(.glass)
        .disabled(authState != .authenticated)
        .alert(authError ?? "", isPresented: Binding(
            get: { authError != nil },
            set: { _ in authError = nil }
        )) {
            Button(GameLocalizedStrings.string("ok"), role: .cancel) {}
        }
    }

#if canImport(UIKit)
    /// Presents Game Center leaderboard using the modern access point trigger without showing an empty modal.
    private func presentLeaderboard() {
        GKAccessPoint.shared.trigger(
            leaderboardID: leaderboardConfiguration.leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        ) {
            AppLog.info(AppLog.game, "GC access point handler finished; refreshing auth state")
            refreshAuthState()
        }
    }

    private func startAuthentication(startedByUser: Bool) {
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

    private func refreshAuthState() {
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
    private func scheduleAuthTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            if authState == .authenticating {
                refreshAuthState()
                guard authState == .authenticating else { return }
                AppLog.error(AppLog.game, "⌛️ Game Center auth timed out; resetting state")
                authState = .idle
            }
        }
    }
#endif

#if os(macOS)
    // macOS build: Game Center auth flow not shown; keep stubs so menu compiles.
    private func startAuthentication(startedByUser: Bool) { }
    private func refreshAuthState() { }
#endif

    @ViewBuilder
    private var menuRateButton: some View {
        Button {
            #if os(macOS)
            requestReview()
            #else
            ratingService.requestRating()
            #endif
        } label: {
            Text(GameLocalizedStrings.string("rateApp"))
                .font(fontPreferenceStore.font(size: 18))
        }
        .buttonStyle(.glass)
    }

    #if canImport(UIKit)
    private var authVCItem: Binding<IdentifiableVC?> {
        Binding(
            get: { authViewControllerToPresent.map { IdentifiableVC(vc: $0) } },
            set: { authViewControllerToPresent = $0?.vc }
        )
    }
    #endif
}

#if canImport(UIKit)
private struct IdentifiableVC: Identifiable {
    let id = UUID()
    let vc: UIViewController
}
#endif

/// Presents leaderboard: fullScreenCover on iOS/tvOS, sheet on macOS.
private struct LeaderboardPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let leaderboardID: String

    func body(content: Content) -> some View {
        #if canImport(UIKit)
        content
            .fullScreenCover(isPresented: $isPresented) {
                LeaderboardView(leaderboardID: leaderboardID) {
                    isPresented = false
                }
            }
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

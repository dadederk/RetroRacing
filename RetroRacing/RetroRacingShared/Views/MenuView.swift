//
//  MenuView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
#if canImport(UIKit) && !os(watchOS)
import GameKit
#endif
#if os(macOS)
import StoreKit
import AppKit
#endif

/// Root menu for launching gameplay, viewing leaderboards, and accessing settings.
@MainActor
public struct MenuView: View {
    public let leaderboardService: LeaderboardService
    public let ratingService: RatingService
    public let leaderboardConfiguration: LeaderboardConfiguration
    public let themeManager: ThemeManager
    public let fontPreferenceStore: FontPreferenceStore
    public let hapticController: HapticFeedbackController
    /// Injected by app; when false, haptic setting is hidden (device has no haptics).
    public let supportsHapticFeedback: Bool
    public let highestScoreStore: HighestScoreStore
    public let playLimitService: PlayLimitService?
    public let style: MenuViewStyle
    public let settingsStyle: SettingsViewStyle
    public let gameViewStyle: GameViewStyle
    public let controlsDescriptionKey: String
    public let showRateButton: Bool
    public let inputAdapterFactory: any GameInputAdapterFactory
    private let onPlayRequest: (() -> Void)?

    #if os(macOS)
    @Environment(\.requestReview) private var requestReview
    #endif
    @State private var showGame = false
    @State private var showLeaderboard = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var authModel: MenuAuthModel

    public init(
        leaderboardService: LeaderboardService,
        gameCenterService: GameCenterService,
        ratingService: RatingService,
        leaderboardConfiguration: LeaderboardConfiguration,
        authenticationPresenter: AuthenticationPresenter,
        themeManager: ThemeManager,
        fontPreferenceStore: FontPreferenceStore,
        hapticController: HapticFeedbackController,
        supportsHapticFeedback: Bool,
        highestScoreStore: HighestScoreStore,
        playLimitService: PlayLimitService?,
        style: MenuViewStyle,
        settingsStyle: SettingsViewStyle,
        gameViewStyle: GameViewStyle,
        controlsDescriptionKey: String,
        showRateButton: Bool,
        inputAdapterFactory: any GameInputAdapterFactory,
        onPlayRequest: (() -> Void)? = nil
    ) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        self.leaderboardConfiguration = leaderboardConfiguration
        self.themeManager = themeManager
        self.fontPreferenceStore = fontPreferenceStore
        self.hapticController = hapticController
        self.supportsHapticFeedback = supportsHapticFeedback
        self.highestScoreStore = highestScoreStore
        self.playLimitService = playLimitService
        self.style = style
        self.settingsStyle = settingsStyle
        self.gameViewStyle = gameViewStyle
        self.controlsDescriptionKey = controlsDescriptionKey
        self.showRateButton = showRateButton
        self.inputAdapterFactory = inputAdapterFactory
        self.onPlayRequest = onPlayRequest
        _authModel = State(initialValue: MenuAuthModel(
            gameCenterService: gameCenterService,
            authenticationPresenter: authenticationPresenter,
            leaderboardConfiguration: leaderboardConfiguration
        ))
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let padding = style.contentPadding {
                    menuContent
                        .padding(padding)
                } else {
                    menuContent
                }
            }
            .fontPreferenceStore(fontPreferenceStore)
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
                SettingsView(
                    themeManager: themeManager,
                    fontPreferenceStore: fontPreferenceStore,
                    supportsHapticFeedback: supportsHapticFeedback,
                    controlsDescriptionKey: controlsDescriptionKey,
                    style: settingsStyle,
                    ratingService: ratingService,
                    playLimitService: playLimitService
                )
                .fontPreferenceStore(fontPreferenceStore)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(playLimitService: playLimitService)
                    .fontPreferenceStore(fontPreferenceStore)
            }
            .navigationDestination(isPresented: $showGame) {
                GameView(
                    leaderboardService: leaderboardService,
                    ratingService: ratingService,
                    theme: themeManager.currentTheme,
                    hapticController: hapticController,
                    fontPreferenceStore: fontPreferenceStore,
                    highestScoreStore: highestScoreStore,
                    playLimitService: playLimitService,
                    style: gameViewStyle,
                    inputAdapterFactory: inputAdapterFactory
                )
            }
            .modifier(LeaderboardPresentationModifier(
                isPresented: $showLeaderboard,
                leaderboardID: leaderboardConfiguration.leaderboardID
            ))
            #if canImport(UIKit) && !os(watchOS)
            .fullScreenCover(item: authVCItem) { item in
                AuthViewControllerWrapper(viewController: item.vc) {
                    authModel.authViewControllerToPresent = nil
                }
            }
            #endif
        }
        .onAppear {
            authModel.configurePresentationHandler()
            authModel.startAuthentication(startedByUser: false)
        }
        #if canImport(UIKit) && !os(watchOS)
        .onReceive(NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)) { _ in
            authModel.refreshAuthState()
        }
        #endif
        .onDisappear {
            authModel.cancelAuthTimeout()
        }
    }

    private var menuContent: some View {
        MenuContentView(
            style: style,
            fontPreferenceStore: fontPreferenceStore,
            showRateButton: showRateButton,
            isLeaderboardEnabled: authModel.isAuthenticated,
            authError: Binding(
                get: { authModel.authError },
                set: { authModel.authError = $0 }
            ),
            onPlay: {
                if let service = playLimitService,
                   service.canStartNewGame(on: Date()) == false {
                    showPaywall = true
                } else if let onPlayRequest {
                    onPlayRequest()
                } else {
                    showGame = true
                }
            },
            onLeaderboard: handleLeaderboardTap,
            onRate: handleRateTap,
            onSettings: { showSettings = true }
        )
    }

    private func handleLeaderboardTap() {
        authModel.authError = nil
        #if canImport(UIKit) && !os(watchOS)
        AppLog.info(AppLog.game, "🎮 Menu leaderboard tap - presenting via GKAccessPoint (UIKit)")
        authModel.presentLeaderboard()
        #elseif os(macOS)
        AppLog.info(AppLog.game, "🎮 Menu leaderboard tap - presenting in-app macOS leaderboard sheet")
        showLeaderboard = true
        #else
        AppLog.info(AppLog.game, "🎮 Menu leaderboard tap - presenting shared LeaderboardView sheet")
        showLeaderboard = true
        #endif
    }

    private func handleRateTap() {
        #if os(macOS)
        requestReview()
        #else
        ratingService.requestRating()
        #endif
    }

    #if canImport(UIKit) && !os(watchOS)
    private var authVCItem: Binding<IdentifiableVC?> {
        Binding(
            get: { authModel.authViewControllerToPresent.map { IdentifiableVC(vc: $0) } },
            set: { authModel.authViewControllerToPresent = $0?.vc }
        )
    }
    #endif
}

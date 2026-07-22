//
//  MenuView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
#if (canImport(UIKit) && !os(watchOS)) || os(macOS)
import GameKit
#endif

enum PaywallTrigger: Identifiable {
    case limitReached
    case voluntary
    var id: Self { self }
}

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
    public let achievementProgressService: AchievementProgressService
    public let playLimitService: PlayLimitService?
    public let specialEventService: SpecialEventService?
    public let style: MenuViewStyle
    public let settingsStyle: SettingsViewStyle
    public let gameViewStyle: GameViewStyle
    public let controlsDescriptionKey: String
    public let showRateButton: Bool
    public let inputAdapterFactory: any GameInputAdapterFactory
    private let onPlayRequest: (() -> Void)?
    private let onSettingsRequest: (() -> Void)?
    /// Present only when non-nil. The composition root only supplies this on the v1 SharePlay
    /// scope (iOS/iPad); other platforms omit it and the button stays hidden.
    private let onPlayWithFriendsRequest: (() -> Void)?
    /// True while a SharePlay match is active. Locks difficulty editing in the Settings sheet
    /// presented from this menu, since the difficulty is shared/synchronized between both
    /// participants for the duration of the match.
    private let isSharePlayActive: Bool

    @Environment(\.openURL) private var openURL
    @Environment(StoreKitService.self) private var storeKit
    @AppStorage(GameDifficulty.conditionalDefaultStorageKey) private var difficultyStorageData: Data = Data()
    @State private var showGame = false
    @State private var showLeaderboard = false
    @State private var showSettings = false
    @State private var paywallTrigger: PaywallTrigger? = nil
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
        achievementProgressService: AchievementProgressService,
        playLimitService: PlayLimitService?,
        specialEventService: SpecialEventService? = nil,
        style: MenuViewStyle,
        settingsStyle: SettingsViewStyle,
        gameViewStyle: GameViewStyle,
        controlsDescriptionKey: String,
        showRateButton: Bool,
        inputAdapterFactory: any GameInputAdapterFactory,
        onPlayRequest: (() -> Void)? = nil,
        onSettingsRequest: (() -> Void)? = nil,
        onPlayWithFriendsRequest: (() -> Void)? = nil,
        isSharePlayActive: Bool = false
    ) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        self.leaderboardConfiguration = leaderboardConfiguration
        self.themeManager = themeManager
        self.fontPreferenceStore = fontPreferenceStore
        self.hapticController = hapticController
        self.supportsHapticFeedback = supportsHapticFeedback
        self.highestScoreStore = highestScoreStore
        self.achievementProgressService = achievementProgressService
        self.playLimitService = playLimitService
        self.specialEventService = specialEventService
        self.style = style
        self.settingsStyle = settingsStyle
        self.gameViewStyle = gameViewStyle
        self.controlsDescriptionKey = controlsDescriptionKey
        self.showRateButton = showRateButton
        self.inputAdapterFactory = inputAdapterFactory
        self.onPlayRequest = onPlayRequest
        self.onSettingsRequest = onSettingsRequest
        self.onPlayWithFriendsRequest = onPlayWithFriendsRequest
        self.isSharePlayActive = isSharePlayActive
        _authModel = State(initialValue: MenuAuthModel(
            gameCenterService: gameCenterService,
            authenticationPresenter: authenticationPresenter
        ))
    }

    public var body: some View {
        NavigationStack {
            menuContentContainer
            .fontPreferenceStore(fontPreferenceStore)
            .toolbar {
                ToolbarItem(placement: Self.settingsToolbarPlacement) {
                    Button {
                        presentSettings()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(GameLocalizedStrings.string("settings"))
                }
            }
            .sheet(isPresented: $showSettings) {
                let previewDependencies = settingsPreviewDependencyFactory.make(
                    hapticController: hapticController
                )
                SettingsView(
                    themeManager: themeManager,
                    fontPreferenceStore: fontPreferenceStore,
                    supportsHapticFeedback: supportsHapticFeedback,
                    hapticController: hapticController,
                    audioCueTutorialPreviewPlayer: previewDependencies.audioCueTutorialPreviewPlayer,
                    speedWarningFeedbackPreviewPlayer: previewDependencies.speedWarningFeedbackPreviewPlayer,
                    controlsDescriptionKey: controlsDescriptionKey,
                    style: settingsStyle,
                    achievementProgressService: achievementProgressService,
                    isGameSessionInProgress: isSharePlayActive,
                    playLimitService: playLimitService,
                    specialEventService: specialEventService
                )
                .fontPreferenceStore(fontPreferenceStore)
            }
            .sheet(item: $paywallTrigger) { trigger in
                PaywallView(playLimitService: playLimitService, isLimitReached: trigger == .limitReached)
                    .fontPreferenceStore(fontPreferenceStore)
            }
            .navigationDestination(isPresented: $showGame) {
                GameView(
                    leaderboardService: leaderboardService,
                    ratingService: ratingService,
                    theme: themeManager.currentTheme,
                    hapticController: hapticController,
                    supportsHapticFeedback: supportsHapticFeedback,
                    fontPreferenceStore: fontPreferenceStore,
                    highestScoreStore: highestScoreStore,
                    achievementProgressService: achievementProgressService,
                    playLimitService: playLimitService,
                    specialEventService: specialEventService,
                    style: gameViewStyle,
                    inputAdapterFactory: inputAdapterFactory,
                    controllerInputSource: NoOpGameControllerInputSource(),
                    controlsDescriptionKey: controlsDescriptionKey
                )
            }
            .modifier(LeaderboardPresentationModifier(
                isPresented: $showLeaderboard,
                leaderboardID: leaderboardConfiguration.leaderboardID(for: selectedDifficulty)
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
        #if (canImport(UIKit) && !os(watchOS)) || os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)) { _ in
            authModel.refreshAuthState()
        }
        #endif
        .onDisappear {
            authModel.cancelAuthTimeout()
        }
    }

    @ViewBuilder
    private var menuContentContainer: some View {
        if style.allowsDynamicType {
            ScrollView {
                paddedMenuContent
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        } else {
            paddedMenuContent
        }
    }

    @ViewBuilder
    private var paddedMenuContent: some View {
        if let padding = style.contentPadding {
            menuContent
                .padding(padding)
        } else {
            menuContent
        }
    }

    private var menuContent: some View {
        MenuContentView(
            style: style,
            fontPreferenceStore: fontPreferenceStore,
            showRateButton: shouldShowRateButton,
            showSupportButton: shouldShowSupportButton,
            isLeaderboardEnabled: authModel.isAuthenticated,
            authError: Binding(
                get: { authModel.authError },
                set: { authModel.authError = $0 }
            ),
            onPlay: handlePlayTap,
            onLeaderboard: handleLeaderboardTap,
            onRate: handleRateTap,
            onSupport: handleSupportTap,
            showPlayWithFriends: onPlayWithFriendsRequest != nil,
            showPlayWithFriendsFreeFootnote: shouldShowPlayWithFriendsFreeFootnote,
            onPlayWithFriends: { onPlayWithFriendsRequest?() }
        )
    }

    private func handleLeaderboardTap() {
        authModel.authError = nil
        #if canImport(UIKit) && !os(watchOS)
        AppLog.info(AppLog.leaderboard + AppLog.game, "LEADERBOARD_PRESENT", outcome: .requested, fields: [.string("surface", "uikit_access_point")])
        authModel.presentLeaderboard(leaderboardID: leaderboardConfiguration.leaderboardID(for: selectedDifficulty))
        #elseif os(macOS)
        let leaderboardID = leaderboardConfiguration.leaderboardID(for: selectedDifficulty)
        AppLog.info(AppLog.leaderboard + AppLog.game, "LEADERBOARD_PRESENT", outcome: .requested, fields: [.string("surface", "macos_access_point")])
        GKAccessPoint.shared.trigger(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        ) {
            AppLog.info(AppLog.leaderboard + AppLog.game, "LEADERBOARD_PRESENT", outcome: .completed, fields: [.string("surface", "macos_access_point")])
        }
        #else
        AppLog.info(AppLog.leaderboard + AppLog.game, "LEADERBOARD_PRESENT", outcome: .requested, fields: [.string("surface", "shared_sheet")])
        showLeaderboard = true
        #endif
    }

    private func presentSettings() {
        if let onSettingsRequest {
            onSettingsRequest()
            return
        }
        showSettings = true
    }

    private func handlePlayTap() {
        let now = Date()
        let decision = PlayStartEligibilityPolicy.decision(
            hasUnlimitedAccessForGating: storeKit.hasPremiumAccessForGating,
            isSpecialEventActive: specialEventService?.isEventActive(on: now) == true,
            playLimitServiceExists: playLimitService != nil,
            canStartNewGame: playLimitService?.canStartNewGame(on: now) ?? true
        )

        switch decision {
        case .startGame:
            startGameFromMenu()
        case .showLimitPaywall:
            paywallTrigger = .limitReached
        }
    }

    private func startGameFromMenu() {
        if let onPlayRequest {
            onPlayRequest()
        } else {
            showGame = true
        }
    }

    private var selectedDifficulty: GameDifficulty {
        _ = difficultyStorageData
        return GameDifficulty.currentSelection(from: InfrastructureDefaults.userDefaults)
    }

    private var shouldShowPlayWithFriendsFreeFootnote: Bool {
        guard onPlayWithFriendsRequest != nil else { return false }
        guard storeKit.hasPremiumAccessForGating == false else { return false }
        return specialEventService?.isEventActive(on: Date()) != true
    }

    private var settingsPreviewDependencyFactory: SettingsPreviewDependencyFactory {
        SettingsPreviewDependencyFactory(
            laneCuePlayerFactory: { PlatformFactories.makeLaneCuePlayer() },
            announcementPoster: AccessibilityAnnouncementPoster(),
            announcementTextProvider: {
                GameLocalizedStrings.string("speed_increase_announcement")
            },
            volumeProvider: {
                SoundEffectsVolumePreference.currentSelection(from: InfrastructureDefaults.userDefaults)
            }
        )
    }

    private func handleRateTap() {
        guard let reviewURL = AppStoreReviewURL.writeReview else { return }
        openURL(reviewURL)
    }

    static func shouldShowSupportButtonPolicy(
        showRateButton: Bool,
        shouldShowFreeTierAffordances: Bool
    ) -> Bool {
        showRateButton && shouldShowFreeTierAffordances
    }

    private var shouldShowSupportButton: Bool {
        return Self.shouldShowSupportButtonPolicy(
            showRateButton: showRateButton,
            shouldShowFreeTierAffordances: storeKit.shouldShowFreeTierAffordances
        )
    }

    /// Unlimited Plays purchasers have already supported the game, so the menu's rate CTA
    /// is hidden for them (`Requirements/rating_system.md`). They can still rate from About.
    static func shouldShowRateButtonPolicy(
        showRateButton: Bool,
        hasPremiumAccessForGating: Bool
    ) -> Bool {
        showRateButton && !hasPremiumAccessForGating
    }

    private var shouldShowRateButton: Bool {
        return Self.shouldShowRateButtonPolicy(
            showRateButton: showRateButton,
            hasPremiumAccessForGating: storeKit.hasPremiumAccessForGating
        )
    }

    private func handleSupportTap() {
        paywallTrigger = .voluntary
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

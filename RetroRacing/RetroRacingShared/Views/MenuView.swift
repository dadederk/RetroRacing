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

private enum MenuNavigationDestination: Hashable {
    case help
    case settings
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
    /// scope (iOS/iPad/macOS); other platforms omit it and the button stays hidden.
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
    @State private var showHelp = false
    @State private var navigationPath = NavigationPath()
    @State private var paywallTrigger: PaywallTrigger? = nil
    @State private var authModel: MenuAuthModel
    @Namespace private var menuFocusScope

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
        NavigationStack(path: $navigationPath) {
            menuContentContainer
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .fontPreferenceStore(fontPreferenceStore)
                .overlay(alignment: .topTrailing) {
                    if style.utilityActionPlacement == .content {
                        MenuUtilityActionsView(
                            showsHelp: style.showsHelpAction,
                            font: fontPreferenceStore.font(fixedSize: style.utilityActionFontSize),
                            onHelp: presentHelp,
                            onSettings: presentSettings
                        )
                        .padding(.top, style.utilityActionPadding)
                        .padding(.trailing, style.utilityActionPadding)
                        .modifier(MenuUtilityNavigationRegionModifier())
                    }
                }
            #if os(tvOS)
                .focusScope(menuFocusScope)
            #endif
                .toolbar {
                    if style.utilityActionPlacement == .toolbar {
                        ToolbarItemGroup(placement: Self.settingsToolbarPlacement) {
                            if style.showsHelpAction {
                                Button {
                                    presentHelp()
                                } label: {
                                    Image(systemName: "questionmark.circle")
                                }
                                .accessibilityLabel(GameLocalizedStrings.string("tutorial_help_button"))
                            }
                            Button {
                                presentSettings()
                            } label: {
                                Image(systemName: "gearshape")
                            }
                            .accessibilityLabel(GameLocalizedStrings.string("settings"))
                        }
                    }
                }
            .sheet(isPresented: helpSheetBinding) {
                helpSurface(presentation: .modal)
            }
            .sheet(isPresented: settingsSheetBinding) {
                settingsSurface
                .settingsSheetStyle()
            }
            .sheet(item: $paywallTrigger) { trigger in
                PaywallView(playLimitService: playLimitService, isLimitReached: trigger == .limitReached)
                    .fontPreferenceStore(fontPreferenceStore)
            }
            .navigationDestination(isPresented: $showGame) {
                fallbackGameDestination
            }
            .navigationDestination(for: MenuNavigationDestination.self) { destination in
                switch destination {
                case .help:
                    helpSurface(presentation: .navigationDestination)
                case .settings:
                    settingsSurface
                }
            }
            .modifier(LeaderboardPresentationModifier(
                isPresented: $showLeaderboard,
                leaderboardID: leaderboardConfiguration.leaderboardID(for: selectedDifficulty)
            ))
            #if canImport(UIKit) && !os(watchOS)
            .fullScreenCover(item: authVCItem) { item in
                AuthViewControllerWrapper(viewController: item.vc) {
                    authModel.authenticationPresentationDidDismiss()
                }
            }
            #endif
        }
        #if os(tvOS)
        .onExitCommand(perform: handleTVOSExitCommand)
        #endif
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
            menuFocusScope: menuFocusScope,
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

    private func helpSurface(
        presentation: NavigationSurfacePresentation
    ) -> some View {
        let previewDependencies = settingsPreviewDependencyFactory.make(
            hapticController: hapticController
        )
        return InGameHelpView(
            controlsDescriptionKey: controlsDescriptionKey,
            supportsHapticFeedback: supportsHapticFeedback,
            hapticController: hapticController,
            audioCueTutorialPreviewPlayer: previewDependencies.audioCueTutorialPreviewPlayer,
            speedWarningFeedbackPreviewPlayer: previewDependencies.speedWarningFeedbackPreviewPlayer,
            presentation: presentation
        )
        .fontPreferenceStore(fontPreferenceStore)
    }

    private var settingsSurface: some View {
        let previewDependencies = settingsPreviewDependencyFactory.make(
            hapticController: hapticController
        )
        return SettingsView(
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

    private var helpSheetBinding: Binding<Bool> {
        presentationBinding(
            state: Binding(get: { showHelp }, set: { showHelp = $0 }),
            matches: style.destinationPresentation == .sheet
        )
    }

    private var settingsSheetBinding: Binding<Bool> {
        presentationBinding(
            state: Binding(get: { showSettings }, set: { showSettings = $0 }),
            matches: style.destinationPresentation == .sheet
        )
    }

    private func presentationBinding(
        state: Binding<Bool>,
        matches: Bool
    ) -> Binding<Bool> {
        Binding(
            get: { matches && state.wrappedValue },
            set: { isPresented in
                if isPresented == false {
                    state.wrappedValue = false
                }
            }
        )
    }

    @ViewBuilder
    private var fallbackGameDestination: some View {
        if onPlayRequest == nil {
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
    }

    private func handleLeaderboardTap() {
        authModel.authError = nil
        #if os(visionOS)
        AppLog.info(AppLog.leaderboard + AppLog.game, "LEADERBOARD_PRESENT", outcome: .requested, fields: [.string("surface", "visionos_access_point")])
        GKAccessPoint.shared.trigger(state: .leaderboards) {
            AppLog.info(AppLog.leaderboard + AppLog.game, "LEADERBOARD_PRESENT", outcome: .completed, fields: [.string("surface", "visionos_access_point")])
        }
        #elseif canImport(UIKit) && !os(watchOS)
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
        if style.destinationPresentation == .navigation {
            navigationPath.append(MenuNavigationDestination.settings)
        } else {
            showSettings = true
        }
    }

    private func presentHelp() {
        if style.destinationPresentation == .navigation {
            navigationPath.append(MenuNavigationDestination.help)
        } else {
            showHelp = true
        }
    }

    private func handleTVOSExitCommand() {
        guard navigationPath.isEmpty == false else { return }
        navigationPath.removeLast()
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
        Self.shouldShowPlayWithFriendsFreeFootnotePolicy(
            hasPlayWithFriendsEntryPoint: onPlayWithFriendsRequest != nil,
            shouldShowFreeTierAffordances: storeKit.shouldShowFreeTierAffordances,
            isSpecialEventActive: specialEventService?.isEventActive(on: Date()) == true
        )
    }

    static func shouldShowPlayWithFriendsFreeFootnotePolicy(
        hasPlayWithFriendsEntryPoint: Bool,
        shouldShowFreeTierAffordances: Bool,
        isSpecialEventActive: Bool
    ) -> Bool {
        hasPlayWithFriendsEntryPoint && shouldShowFreeTierAffordances && !isSpecialEventActive
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

private struct MenuUtilityNavigationRegionModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(tvOS)
        content
            .frame(maxWidth: .infinity, alignment: .trailing)
            .focusSection()
        #else
        content
        #endif
    }
}

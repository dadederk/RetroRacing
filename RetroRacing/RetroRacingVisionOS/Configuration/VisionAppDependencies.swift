//
//  VisionAppDependencies.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import GameKit
import GroupActivities
import RetroRacingShared
import StoreKit
import UIKit

/// Long-lived services shared by the visionOS menu, Settings, and Classic gameplay.
@MainActor
struct VisionAppDependencies {
    let authenticationPresenter: AuthenticationPresenterUniversal
    let gameCenterService: GameCenterService
    let leaderboardConfiguration: LeaderboardConfigurationVisionOS
    let ratingService: RatingService
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    let hapticController: HapticFeedbackController
    let imageLoader: any ImageLoader
    let highestScoreStore: HighestScoreStore
    let achievementProgressService: AchievementProgressService
    let playLimitService: PlayLimitService
    let specialEventService: SpecialEventService
    let storeKitService: StoreKitService
    let sharePlayMatchService: any SharePlayMatchService
    let gameplayAudioFeedbackCoordinator: GameplayAudioFeedbackCoordinator

    init(userDefaults: UserDefaults = InfrastructureDefaults.userDefaults) {
        AppBootstrap.configureGameCenterAccessPoint()
        AppBootstrap.configureAudioSession()
        let customFontAvailable = AppBootstrap.registerCustomFont()
        SettingsPreferenceMigration.runIfNeeded(
            userDefaults: userDefaults,
            supportsHaptics: false
        )

        let leaderboardConfiguration = LeaderboardConfigurationVisionOS()
        let authenticationPresenter = AuthenticationPresenterUniversal()
        let pendingScoreStore = UserDefaultsPendingLeaderboardScoreStore(userDefaults: userDefaults)
        let authenticationHandlerSetter: AuthenticateHandlerSetter = { presenter in
            GKLocalPlayer.local.authenticateHandler = { viewController, error in
                if let viewController {
                    presenter.presentAuthenticationUI(viewController)
                    return
                }
                NotificationCenter.default.post(
                    name: .GKPlayerAuthenticationDidChangeNotificationName,
                    object: error
                )
            }
        }
        let gameCenterService = GameCenterService(
            configuration: leaderboardConfiguration,
            friendSnapshotService: GameCenterFriendSnapshotService(
                configuration: .standard,
                avatarCache: GameCenterAvatarCache()
            ),
            authenticationPresenter: authenticationPresenter,
            authenticateHandlerSetter: authenticationHandlerSetter,
            isDebugBuild: BuildConfiguration.isDebug,
            allowDebugScoreSubmission: false,
            pendingScoreStore: pendingScoreStore
        )
        let storeKitService = StoreKitService(userDefaults: userDefaults)
        let playLimitService = UserDefaultsPlayLimitService(userDefaults: userDefaults)
        let themeManager = ThemeManager(
            configuration: .configuration(
                for: .visionOS,
                experimentalThemes: DebugGameplayStorageKeys.experimentalThemeConfiguration(
                    userDefaults: userDefaults,
                    debugFeaturesAllowed: BuildConfiguration.shouldShowDebugFeatures,
                    platform: .visionOS
                )
            ),
            userDefaults: userDefaults,
            hasPremiumAccess: storeKitService.hasPremiumAccessForGating
        )
        storeKitService.onEntitlementsUpdated = { isPremium in
            if isPremium {
                playLimitService.unlockUnlimitedAccess()
            } else {
                playLimitService.clearUnlimitedAccess()
            }
        }
        storeKitService.onPremiumAccessForGatingUpdated = { hasPremiumAccess in
            themeManager.syncPremiumAccess(hasPremiumAccess)
        }

        let highestScoreStore = UserDefaultsHighestScoreStore(userDefaults: userDefaults)
        let soundPlayer = PlatformFactories.makeSoundPlayer()
        let laneCuePlayer = PlatformFactories.makeLaneCuePlayer()
        let noOpHapticController = NoOpHapticFeedbackController()
        let speedWarningPlayer = SpeedIncreaseWarningFeedbackPlayer(
            announcementPoster: AccessibilityAnnouncementPoster(),
            hapticController: nil,
            playWarningSound: {
                laneCuePlayer.playSpeedWarningCue()
            },
            announcementTextProvider: {
                GameLocalizedStrings.string("speed_increase_announcement")
            }
        )
        let gameplayAudioFeedbackCoordinator = GameplayAudioFeedbackCoordinator(
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: nil,
            speedWarningPlayer: speedWarningPlayer,
            preferences: GameplayAudioFeedbackPreferences(
                volume: {
                    SoundEffectsVolumePreference.currentSelection(from: userDefaults)
                },
                mode: {
                    AudioFeedbackMode.currentSelection(from: userDefaults)
                },
                laneMoveStyle: {
                    let style = LaneMoveCueStyle.currentSelection(from: userDefaults)
                    return style == .haptics ? .defaultStyle : style
                },
                speedWarningMode: {
                    SpeedWarningFeedbackPreference.currentSelection(
                        from: userDefaults,
                        supportsHaptics: false,
                        isVoiceOverRunning: VoiceOverStatus.isVoiceOverRunning
                    )
                }
            )
        )
        gameplayAudioFeedbackCoordinator.refreshVolume()
        let sharePlayMatchService = GroupActivitiesSharePlayMatchService(
            difficultyProvider: {
                GameDifficulty.currentSelection(from: userDefaults)
            }
        )
        let achievementProgressService = LocalAchievementProgressService(
            store: UserDefaultsAchievementProgressStore(userDefaults: userDefaults),
            highestScoreStore: highestScoreStore,
            reporter: GameCenterAchievementProgressReporter()
        )
        achievementProgressService.performInitialBackfillIfNeeded()
        achievementProgressService.replayAchievedAchievements()

        self.authenticationPresenter = authenticationPresenter
        self.gameCenterService = gameCenterService
        self.leaderboardConfiguration = leaderboardConfiguration
        self.ratingService = StoreReviewService(
            userDefaults: userDefaults,
            ratingProvider: VisionRatingServiceProvider()
        )
        self.themeManager = themeManager
        self.fontPreferenceStore = FontPreferenceStore(
            userDefaults: userDefaults,
            customFontAvailable: customFontAvailable
        )
        self.hapticController = noOpHapticController
        self.imageLoader = PlatformFactories.makeImageLoader()
        self.highestScoreStore = highestScoreStore
        self.achievementProgressService = achievementProgressService
        self.playLimitService = playLimitService
        self.specialEventService = DateRangeSpecialEventService.miamiGrandPrix2026
        self.storeKitService = storeKitService
        self.sharePlayMatchService = sharePlayMatchService
        self.gameplayAudioFeedbackCoordinator = gameplayAudioFeedbackCoordinator
    }
}

private struct VisionRatingServiceProvider: RatingServiceProvider {
    func presentRatingRequest() {
        Task { @MainActor in
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) else {
                return
            }
            AppStore.requestReview(in: windowScene)
        }
    }
}

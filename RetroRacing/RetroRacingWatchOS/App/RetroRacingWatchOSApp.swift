//
//  RetroRacingWatchOSApp.swift
//  RetroRacingWatchOS
//

import SwiftUI
import RetroRacingShared
import CoreText
import GameKit
#if canImport(WatchKit)
import WatchKit
#endif

@main
struct RetroRacingWatchOSApp: App {
    private static let maxAuthenticationRetries = 3
    private static let authenticationRetryDelay: Duration = .seconds(2)

    private let themeManager: ThemeManager = {
        let config = ThemePlatformConfig(
            defaultThemeID: "pocket",
            availableThemes: [LCDTheme(), PocketTheme()]
        )
        return ThemeManager(
            initialThemes: config.availableThemes,
            defaultThemeID: config.defaultThemeID,
            userDefaults: InfrastructureDefaults.userDefaults
        )
    }()
    private let leaderboardService: GameCenterService
    private let bestScoreSyncService: BestScoreSyncService
    private let fontPreferenceStore: FontPreferenceStore
    private let highestScoreStore = UserDefaultsHighestScoreStore(userDefaults: InfrastructureDefaults.userDefaults)
    private let achievementProgressService: AchievementProgressService
    private let achievementMetadataService: any AchievementMetadataService
    private let pendingLeaderboardScoreStore: any PendingLeaderboardScoreStore
    private let playLimitService = UserDefaultsPlayLimitService(userDefaults: InfrastructureDefaults.userDefaults)
    private let watchBestScoreRelaySender: WatchBestScoreRelaySender
    @State private var authenticationRetryCount = 0

    var body: some Scene {
        WindowGroup {
            ContentView(
                themeManager: themeManager,
                fontPreferenceStore: fontPreferenceStore,
                highestScoreStore: highestScoreStore,
                achievementProgressService: achievementProgressService,
                leaderboardService: leaderboardService,
                watchBestScoreRelaySender: watchBestScoreRelaySender
            )
            .achievementMetadataService(achievementMetadataService)
            .onAppear {
                setupGameCenterAuthentication {
                    Task {
                        await bestScoreSyncService.syncIfPossible()
                        achievementProgressService.replayAchievedAchievements()
                        leaderboardService.flushPendingScoresIfPossible()
                        await achievementMetadataService.invalidate()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)) { _ in
                let isAuthenticated = GKLocalPlayer.local.isAuthenticated
                AppLog.info(
                    AppLog.leaderboard + AppLog.lifecycle,
                    "AUTH_STATE_CHANGED",
                    outcome: .completed,
                    fields: [
                        .bool("isAuthenticated", isAuthenticated)
                    ]
                )
                Task {
                    await bestScoreSyncService.syncIfPossible()
                    achievementProgressService.replayAchievedAchievements()
                    leaderboardService.flushPendingScoresIfPossible()
                    await achievementMetadataService.invalidate()
                }
            }
        }
    }

    init() {
        AppBootstrap.configureAudioSession()
        SettingsPreferenceMigration.runIfNeeded(
            userDefaults: InfrastructureDefaults.userDefaults,
            supportsHaptics: true
        )
        let customFontAvailable = FontRegistrar.registerPressStart2P(additionalBundles: [Bundle.main])
        fontPreferenceStore = FontPreferenceStore(
            userDefaults: InfrastructureDefaults.userDefaults,
            customFontAvailable: customFontAvailable
        )
        
        // Initialize Game Center service for watchOS
        let configuration = LeaderboardConfigurationWatchOS()
        let pendingStore = UserDefaultsPendingLeaderboardScoreStore(userDefaults: InfrastructureDefaults.userDefaults)
        pendingLeaderboardScoreStore = pendingStore
        leaderboardService = GameCenterService(
            configuration: configuration,
            friendSnapshotService: GameCenterFriendSnapshotService(
                configuration: .watchOS,
                avatarCache: GameCenterAvatarCache()
            ),
            authenticationPresenter: nil,
            authenticateHandlerSetter: nil,
            isDebugBuild: BuildConfiguration.isDebug,
            allowDebugScoreSubmission: false,
            pendingScoreStore: pendingStore
        )
        bestScoreSyncService = BestScoreSyncService(
            leaderboardService: leaderboardService,
            highestScoreStore: highestScoreStore,
            difficultyProvider: {
                GameDifficulty.currentSelection(from: InfrastructureDefaults.userDefaults)
            }
        )
        achievementProgressService = LocalAchievementProgressService(
            store: UserDefaultsAchievementProgressStore(userDefaults: InfrastructureDefaults.userDefaults),
            highestScoreStore: highestScoreStore,
            reporter: GameCenterAchievementProgressReporter()
        )
        achievementProgressService.performInitialBackfillIfNeeded()
        achievementProgressService.replayAchievedAchievements()
        achievementMetadataService = GameCenterAchievementMetadataService()
        let relaySender = WatchConnectivityBestScoreRelaySender()
        relaySender.activateIfPossible()
        watchBestScoreRelaySender = relaySender
    }
    
    private func setupGameCenterAuthentication(onAuthStateChanged: @escaping () -> Void) {
        logGameCenterDiagnostics()
        AppLog.info(
            AppLog.leaderboard + AppLog.lifecycle,
            "AUTH_SETUP",
            outcome: .started
        )
        GKLocalPlayer.local.authenticateHandler = { error in
            if let error = error {
                let nsError = error as NSError
                if shouldRetryAuthentication(for: nsError) {
                    scheduleAuthenticationRetry(onAuthStateChanged: onAuthStateChanged)
                }
                AppLog.error(
                    AppLog.leaderboard + AppLog.lifecycle,
                    "AUTH_RESULT",
                    outcome: .failed,
                    fields: [
                        .reason("gamekit_error")
                    ] + AppLog.Field.error(error)
                )
                onAuthStateChanged()
                return
            }
            // No error = auth completed (success or silent failure)
            if GKLocalPlayer.local.isAuthenticated {
                authenticationRetryCount = 0
                AppLog.info(
                    AppLog.leaderboard + AppLog.lifecycle,
                    "AUTH_RESULT",
                    outcome: .succeeded,
                    fields: [
                        .string("player", AppLog.redactedPlayer(GKLocalPlayer.local.displayName))
                    ]
                )
            } else {
                AppLog.info(
                    AppLog.leaderboard + AppLog.lifecycle,
                    "AUTH_RESULT",
                    outcome: .blocked,
                    fields: [
                        .reason("player_not_authenticated")
                    ]
                )
            }
            onAuthStateChanged()
        }
    }

    private func shouldRetryAuthentication(for error: NSError) -> Bool {
        guard error.domain == GKErrorDomain else { return false }
        guard error.code == GKError.Code.gameUnrecognized.rawValue else { return false }
        guard authenticationRetryCount < Self.maxAuthenticationRetries else {
            AppLog.warning(
                AppLog.leaderboard + AppLog.lifecycle,
                "AUTH_RETRY",
                outcome: .failed,
                fields: [
                    .reason("retry_limit_reached"),
                    .int("maxRetries", Self.maxAuthenticationRetries)
                ]
            )
            return false
        }
        authenticationRetryCount += 1
        AppLog.info(
            AppLog.leaderboard + AppLog.lifecycle,
            "AUTH_RETRY",
            outcome: .deferred,
            fields: [
                .reason("game_unrecognized"),
                .int("attempt", authenticationRetryCount),
                .int("maxRetries", Self.maxAuthenticationRetries)
            ]
        )
        return true
    }

    private func scheduleAuthenticationRetry(onAuthStateChanged: @escaping () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: Self.authenticationRetryDelay)
            guard GKLocalPlayer.local.isAuthenticated == false else {
                return
            }
            setupGameCenterAuthentication(onAuthStateChanged: onAuthStateChanged)
        }
    }

    private func logGameCenterDiagnostics() {
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let companionBundleID = Bundle.main.object(forInfoDictionaryKey: "WKCompanionAppBundleIdentifier") as? String ?? "missing"
        let runsIndependently = Bundle.main.object(forInfoDictionaryKey: "WKRunsIndependentlyOfCompanionApp") as? Bool
        let localPlayer = GKLocalPlayer.local
        AppLog.info(
            AppLog.leaderboard + AppLog.lifecycle,
            "GC_DIAGNOSTICS",
            outcome: .completed,
            fields: [
                .string("bundleID", bundleID),
                .string("companionBundleID", companionBundleID),
                .string("runsIndependently", runsIndependently?.description ?? "missing"),
                .bool("debugBuild", BuildConfiguration.isDebug),
                .bool("isAuthenticated", localPlayer.isAuthenticated),
                .bool("isUnderage", localPlayer.isUnderage)
            ]
        )
    }
}

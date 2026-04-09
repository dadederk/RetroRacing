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
                    AppLog.game + AppLog.leaderboard,
                    "🏆 watchOS Game Center auth state changed via notification (isAuthenticated: \(isAuthenticated))"
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
        AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS setting up Game Center authentication")
        GKLocalPlayer.local.authenticateHandler = { error in
            if let error = error {
                let nsError = error as NSError
                if shouldRetryAuthentication(for: nsError) {
                    scheduleAuthenticationRetry(onAuthStateChanged: onAuthStateChanged)
                }
                AppLog.error(
                    AppLog.game + AppLog.leaderboard,
                    "🏆 watchOS Game Center authentication error: \(error.localizedDescription) (domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo))"
                )
                onAuthStateChanged()
                return
            }
            // No error = auth completed (success or silent failure)
            if GKLocalPlayer.local.isAuthenticated {
                authenticationRetryCount = 0
                AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS Game Center authenticated successfully - player: \(GKLocalPlayer.local.displayName)")
            } else {
                AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS Game Center authentication handler called, but player not authenticated")
            }
            onAuthStateChanged()
        }
    }

    private func shouldRetryAuthentication(for error: NSError) -> Bool {
        guard error.domain == GKErrorDomain else { return false }
        guard error.code == GKError.Code.gameUnrecognized.rawValue else { return false }
        guard authenticationRetryCount < Self.maxAuthenticationRetries else {
            AppLog.error(
                AppLog.game + AppLog.leaderboard,
                "🏆 watchOS authentication retries exhausted for GKErrorGameUnrecognized"
            )
            return false
        }
        authenticationRetryCount += 1
        AppLog.info(
            AppLog.game + AppLog.leaderboard,
            "🏆 watchOS scheduling Game Center auth retry \(authenticationRetryCount)/\(Self.maxAuthenticationRetries) after GKErrorGameUnrecognized"
        )
        AppLog.info(
            AppLog.game + AppLog.leaderboard,
            "🏆 GKErrorGameUnrecognized – watchOS bundle ID not matched to a Game Center profile. Check WKRunsIndependentlyOfCompanionApp setting and App Store Connect Game Center config."
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
            AppLog.game + AppLog.leaderboard,
            """
            🏆 watchOS GC diagnostics bundleID=\(bundleID), companionBundleID=\(companionBundleID), runsIndependently=\(runsIndependently?.description ?? "missing"), debugBuild=\(BuildConfiguration.isDebug), isAuthenticated=\(localPlayer.isAuthenticated), isUnderage=\(localPlayer.isUnderage)
            """
        )
    }
}

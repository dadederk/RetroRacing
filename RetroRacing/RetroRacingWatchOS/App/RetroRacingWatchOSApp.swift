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

/// Game Center leaderboard configuration for watchOS sandbox.
private struct LeaderboardConfigurationWatchOS: LeaderboardConfiguration {
    func leaderboardID(for difficulty: GameDifficulty) -> String {
        switch difficulty {
        case .cruise:
            return "bestwatchos001cruise"
        case .fast:
            return "bestwatchos001fast"
        case .rapid:
            return "bestwatchos001test"
        @unknown default:
            return "bestwatchos001test"
        }
    }
}

@main
struct RetroRacingWatchOSApp: App {
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
    private let crownConfiguration = LegacyCrownInputProcessor.Configuration.watchLegacy
    private let leaderboardService: GameCenterService
    private let bestScoreSyncService: BestScoreSyncService
    private let fontPreferenceStore: FontPreferenceStore
    private let highestScoreStore = UserDefaultsHighestScoreStore(userDefaults: InfrastructureDefaults.userDefaults)
    private let playLimitService = UserDefaultsPlayLimitService(userDefaults: InfrastructureDefaults.userDefaults)

    var body: some Scene {
        WindowGroup {
            ContentView(
                themeManager: themeManager,
                fontPreferenceStore: fontPreferenceStore,
                highestScoreStore: highestScoreStore,
                crownConfiguration: crownConfiguration,
                leaderboardService: leaderboardService
            )
            .onAppear {
                setupGameCenterAuthentication {
                    Task {
                        await bestScoreSyncService.syncIfPossible()
                    }
                }
                Task {
                    await bestScoreSyncService.syncIfPossible()
                }
            }
        }
    }

    init() {
        let customFontAvailable = FontRegistrar.registerPressStart2P(additionalBundles: [Bundle.main])
        fontPreferenceStore = FontPreferenceStore(
            userDefaults: InfrastructureDefaults.userDefaults,
            customFontAvailable: customFontAvailable
        )
        
        // Initialize Game Center service for watchOS
        let configuration = LeaderboardConfigurationWatchOS()
        leaderboardService = GameCenterService(
            configuration: configuration,
            authenticationPresenter: nil,
            authenticateHandlerSetter: nil,
            isDebugBuild: BuildConfiguration.isDebug
        )
        bestScoreSyncService = BestScoreSyncService(
            leaderboardService: leaderboardService,
            highestScoreStore: highestScoreStore,
            difficultyProvider: {
                GameDifficulty.currentSelection(from: InfrastructureDefaults.userDefaults)
            }
        )
    }
    
    private func setupGameCenterAuthentication(onAuthStateChanged: @escaping () -> Void) {
        logGameCenterDiagnostics()
        AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS setting up Game Center authentication")
        GKLocalPlayer.local.authenticateHandler = { error in
            if let error = error {
                let nsError = error as NSError
                AppLog.error(
                    AppLog.game + AppLog.leaderboard,
                    "🏆 watchOS Game Center authentication error: \(error.localizedDescription) (domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo))"
                )
                onAuthStateChanged()
                return
            }
            // No error = auth completed (success or silent failure)
            if GKLocalPlayer.local.isAuthenticated {
                AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS Game Center authenticated successfully - player: \(GKLocalPlayer.local.displayName)")
            } else {
                AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS Game Center authentication handler called, but player not authenticated")
            }
            onAuthStateChanged()
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

/// No-op authentication presenter for watchOS (no UI to present).
private final class NoOpAuthenticationPresenter: AuthenticationPresenter {
    func presentAuthenticationUI(_ viewController: Any) {
        AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS NoOpAuthenticationPresenter.presentAuthenticationUI called (no-op)")
    }
}

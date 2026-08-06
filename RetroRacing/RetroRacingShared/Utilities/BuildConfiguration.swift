//
//  BuildConfiguration.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 10/02/2026.
//

import Foundation
import StoreKit

/// Utility for detecting build configuration and deciding when to show debug features.
public enum BuildConfiguration {
    /// Cached TestFlight detection result.
    private static var cachedIsTestFlight: Bool?

    /// Returns true if running in a DEBUG build.
    public static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// Returns true if running in a TestFlight build.
    /// Uses StoreKit 2's `AppTransaction` to detect a sandbox environment.
    /// Returns cached value if available, otherwise `false` (safe default).
    static var isTestFlight: Bool {
        cachedIsTestFlight ?? false
    }

    /// Initializes the TestFlight detection check.
    /// Call this early in the app lifecycle (e.g., in `RetroRacingApp` init).
    public static func initializeTestFlightCheck() {
        Task {
            await checkTestFlightEnvironment()
        }
    }

    /// Returns true when debug-only UI/features should be visible.
    /// Enabled in DEBUG and TestFlight builds.
    public static var shouldShowDebugFeatures: Bool {
        isDebug
    }

    /// Returns true when the current process is hosting an XCTest bundle.
    public static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Returns true only for app launches explicitly configured by the UI-test target.
    public static var isRunningUITests: Bool {
        isDebug && ProcessInfo.processInfo.arguments.contains("--ui-testing")
    }

    // MARK: - Private

    private static func checkTestFlightEnvironment() async {
        do {
            let verificationResult = try await AppTransaction.shared

            switch verificationResult {
            case .verified(let transaction):
                // TestFlight builds run in the sandbox environment.
                cachedIsTestFlight = (transaction.environment == .sandbox)
            case .unverified:
                cachedIsTestFlight = false
            }
        } catch {
            // If `AppTransaction` is unavailable, fall back to false.
            cachedIsTestFlight = false
        }
    }
}

/// Shared debug-only storage keys for gameplay QA tooling.
public enum DebugGameplayStorageKeys {
    public static let forcedAchievementIdentifier = "debugGameplay.forcedAchievementIdentifier"
    public static let noForcedAchievementIdentifier = ""
    public static let showSpriteKitFrameStats = "debugGameplay.showSpriteKitFrameStats"
    public static let experimentalThirtyTwoBitThemeEnabled = "debugGameplay.experimentalThirtyTwoBitThemeEnabled"
    public static let experimentalSixtyFourBitThemeEnabled = "debugGameplay.experimentalSixtyFourBitThemeEnabled"

    public static func isExperimentalThirtyTwoBitThemeEnabled(
        userDefaults: UserDefaults,
        debugFeaturesAllowed: Bool,
        platform: ThemeCatalogPlatform
    ) -> Bool {
        isExperimentalThemeEnabled(
            storageKey: experimentalThirtyTwoBitThemeEnabled,
            userDefaults: userDefaults,
            debugFeaturesAllowed: debugFeaturesAllowed,
            defaultEnabled: platform.alwaysIncludes(.thirtyTwoBit)
        )
    }

    public static func isExperimentalSixtyFourBitThemeEnabled(
        userDefaults: UserDefaults,
        debugFeaturesAllowed: Bool,
        platform: ThemeCatalogPlatform
    ) -> Bool {
        isExperimentalThemeEnabled(
            storageKey: experimentalSixtyFourBitThemeEnabled,
            userDefaults: userDefaults,
            debugFeaturesAllowed: debugFeaturesAllowed,
            defaultEnabled: platform.alwaysIncludes(.sixtyFourBit)
        )
    }

    public static func experimentalThemeConfiguration(
        userDefaults: UserDefaults,
        debugFeaturesAllowed: Bool,
        platform: ThemeCatalogPlatform
    ) -> ExperimentalThemeConfiguration {
        ExperimentalThemeConfiguration(
            isThirtyTwoBitEnabled: isExperimentalThirtyTwoBitThemeEnabled(
                userDefaults: userDefaults,
                debugFeaturesAllowed: debugFeaturesAllowed,
                platform: platform
            ),
            isSixtyFourBitEnabled: isExperimentalSixtyFourBitThemeEnabled(
                userDefaults: userDefaults,
                debugFeaturesAllowed: debugFeaturesAllowed,
                platform: platform
            )
        )
    }

    private static func isExperimentalThemeEnabled(
        storageKey: String,
        userDefaults: UserDefaults,
        debugFeaturesAllowed: Bool,
        defaultEnabled: Bool
    ) -> Bool {
        // Distribution builds keep only the platform's required default experiment.
        guard debugFeaturesAllowed else { return defaultEnabled }
        guard userDefaults.object(forKey: storageKey) != nil else {
            return defaultEnabled
        }
        return userDefaults.bool(forKey: storageKey)
    }
}

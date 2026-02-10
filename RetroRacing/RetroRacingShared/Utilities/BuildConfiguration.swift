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
    static var isDebug: Bool {
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
    static var shouldShowDebugFeatures: Bool {
        isDebug || isTestFlight
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


//
//  AppStoreScreenshotCaptureDefaults.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public enum AppStoreScreenshotCaptureDefaults {
    public static func normalizedPlatform(_ platform: String) -> String {
        switch platform.lowercased() {
        case "mac", "macos":
            return "mac"
        case "iphone", "ios":
            return "iphone"
        case "ipad", "ipados":
            return "ipad"
        case "watch", "watchos", "applewatch":
            return "appleWatch"
        default:
            return platform
        }
    }

    public static func defaultLocales(for platform: String) -> [String] {
        _ = platform
        return ScreenshotStudioWorkflow.locales
    }

    /// CLI platform tokens for a full multi-platform capture pass (order matters).
    public static let capturePlatforms = ["iphone", "ipad", "mac", "watch"]

    public static func stagingDirectory(repositoryRoot: URL, platform: String) -> URL {
        repositoryRoot
            .appending(path: ".build/screenshot-capture")
            .appending(path: normalizedPlatform(platform))
    }

    /// Flat `/tmp` capture files written by macOS UI tests; synced into `stagingDirectory` after each run.
    public static func macFlatCaptureURL(
        locale: String,
        slideIndex: Int,
        fileExtension: String
    ) -> URL {
        URL(fileURLWithPath: "/tmp/retrorapid-mac-\(locale)_\(slideIndex)\(fileExtension)")
    }

    /// Legacy directory-based runtime staging retained for older sandboxed runners.
    public static func macUITestRuntimeStagingDirectory() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(
                "Library/Containers/com.accessibilityUpTo11.RetroRacingUITests.xctrunner/Data/tmp/retrorapid-screenshot-capture/mac",
                isDirectory: true
            )
    }

    public static func macRuntimeStagingDirectory() -> URL {
        macUITestRuntimeStagingDirectory()
    }

    public static func destination(for platform: String) -> String {
        fallbackDestination(for: platform)
    }

    public static func fallbackDestination(for platform: String) -> String {
        switch normalizedPlatform(platform) {
        case "mac":
            return "platform=macOS"
        case "ipad":
            return "platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=27.0"
        case "appleWatch":
            return "platform=watchOS Simulator,name=Apple Watch Ultra 3 (49mm),OS=27.0"
        default:
            return "platform=iOS Simulator,name=iPhone 17 Pro Max,OS=27.0"
        }
    }
}

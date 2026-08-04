//
//  ScreenshotCaptureConfiguration.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public enum ScreenshotCaptureThemePolicy {
    static let captureSuiteName = "com.accessibilityUpTo11.RetroRapid.ScreenshotCaptureTheme"

    public static func makeCaptureUserDefaults(platform: String?) -> UserDefaults? {
        guard let userDefaults = UserDefaults(suiteName: captureSuiteName) else {
            return nil
        }
        userDefaults.removePersistentDomain(forName: captureSuiteName)
        userDefaults.register(defaults: [
            ThemeManager.selectedThemeKey: ThemePlatformConfig
                .screenshotCapture(platform: platform)
                .defaultThemeID
                .rawValue,
        ])
        return userDefaults
    }
}

public struct ScreenshotCaptureConfiguration: Equatable, Sendable {
    public let slideIndex: Int
    public let fixture: ScreenshotSlideFixture
    public let stagingDirectory: URL?

    public var readinessIdentifier: String {
        ScreenshotCaptureIdentifiers.readinessIdentifier(slideIndex: slideIndex)
    }

    public static var current: ScreenshotCaptureConfiguration? {
        guard isCaptureModeEnabled else { return nil }
        guard isWatchCapturePlatform == false else { return nil }
        guard let slideIndex = slideIndexFromEnvironment else { return nil }
        guard let fixture = ScreenshotSlideFixture.fixture(
            for: slideIndex,
            platform: capturePlatform
        ) else { return nil }
        return ScreenshotCaptureConfiguration(
            slideIndex: slideIndex,
            fixture: fixture,
            stagingDirectory: stagingDirectoryFromEnvironment
        )
    }

    public static var isWatchCapturePlatform: Bool {
        switch capturePlatform?.lowercased() {
        case "watch", "applewatch":
            return true
        default:
            return false
        }
    }

    static var slideIndexFromEnvironment: Int? {
        if let launchIndex = slideIndexFromLaunchArguments {
            return launchIndex
        }
        guard let rawValue = ProcessInfo.processInfo.environment[ScreenshotCaptureIdentifiers.slideIndexKey] else {
            return nil
        }
        return Int(rawValue)
    }

    static var stagingDirectoryFromEnvironment: URL? {
        if let launchPath = launchArgumentValue(following: "-ScreenshotCaptureStaging") {
            return URL(fileURLWithPath: launchPath, isDirectory: true)
        }
        guard let path = ProcessInfo.processInfo.environment[ScreenshotCaptureIdentifiers.stagingDirectoryKey] else {
            return nil
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    public static var isCaptureModeEnabled: Bool {
        guard BuildConfiguration.isDebug else { return false }
        if explicitCaptureFlagIsEnabled || explicitCaptureFlagFromLaunchArguments {
            return true
        }
        if slideIndexFromLaunchArguments != nil {
            return true
        }
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil,
           slideIndexFromEnvironment != nil {
            return true
        }
        return false
    }

    private static var explicitCaptureFlagIsEnabled: Bool {
        ProcessInfo.processInfo.environment[ScreenshotCaptureIdentifiers.captureEnabledKey] == "1"
    }

    private static var explicitCaptureFlagFromLaunchArguments: Bool {
        launchArgumentValue(following: "-ScreenshotCaptureEnabled") == "1"
    }

    private static var slideIndexFromLaunchArguments: Int? {
        guard let rawValue = launchArgumentValue(following: "-ScreenshotCaptureSlide") else {
            return nil
        }
        return Int(rawValue)
    }

    public static var capturePlatform: String? {
        if let launchPlatform = launchArgumentValue(following: "-ScreenshotCapturePlatform"),
           launchPlatform.isEmpty == false {
            return launchPlatform
        }
        guard let platform = ProcessInfo.processInfo.environment[ScreenshotCaptureIdentifiers.platformKey],
              platform.isEmpty == false else {
            return nil
        }
        return platform
    }

    private static func launchArgumentValue(following flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }
}

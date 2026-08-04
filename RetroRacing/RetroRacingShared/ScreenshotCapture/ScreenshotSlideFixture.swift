//
//  ScreenshotSlideFixture.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public enum ScreenshotCaptureRoute: Equatable, Sendable {
    case gameplay
    case settings(ScreenshotSettingsFocus)
    case gameOver
    case menu
    case achievementUnlock
}

public enum ScreenshotSettingsFocus: Equatable, Sendable {
    case accessibility
    case themeAndFont
    case customize
}

public enum ScreenshotSlideFixture: Equatable, Sendable, CaseIterable {
    case hookGameplay
    case actionGameplay
    case gameOver
    case accessibilitySettings
    case sharePlayWaiting
    case friendMarkerGameplay
    case themeSettings
    case pocketGameplay
    case achievementUnlock
    case freeUserMenu

    public static let universalSlideCount = 10
    public static let macSlideCount = 9

    public static func slideCount(for platform: String?) -> Int {
        guard let platform else { return universalSlideCount }
        switch platform.lowercased() {
        case "mac":
            return macSlideCount
        default:
            return universalSlideCount
        }
    }

    public static func fixture(for slideIndex: Int, platform: String? = nil) -> ScreenshotSlideFixture? {
        let resolvedPlatform = platform ?? ScreenshotCaptureConfiguration.capturePlatform
        if resolvedPlatform?.lowercased() == "mac" {
            return macFixture(for: slideIndex)
        }
        return universalFixture(for: slideIndex)
    }

    public var route: ScreenshotCaptureRoute {
        switch self {
        case .hookGameplay, .actionGameplay, .friendMarkerGameplay, .pocketGameplay, .sharePlayWaiting:
            return .gameplay
        case .accessibilitySettings:
            return .settings(.accessibility)
        case .themeSettings:
            return .settings(.customize)
        case .gameOver:
            return .gameOver
        case .achievementUnlock:
            return .achievementUnlock
        case .freeUserMenu:
            return .menu
        }
    }

    public var layout: GameScreenshotLayout? {
        switch self {
        case .hookGameplay, .pocketGameplay:
            return .hookGameplay
        case .actionGameplay:
            return .actionGameplay
        case .friendMarkerGameplay:
            return GameScreenshotLayout.friendMarkerGameplay()
        case .sharePlayWaiting:
            return .hookGameplay
        case .accessibilitySettings, .themeSettings, .gameOver, .achievementUnlock, .freeUserMenu:
            return nil
        }
    }

    /// Gameplay scene shown behind settings and game-over sheets.
    public var gameplayBackgroundLayout: GameScreenshotLayout {
        switch self {
        case .hookGameplay, .pocketGameplay, .accessibilitySettings, .themeSettings:
            return .hookGameplay
        case .actionGameplay:
            return .actionGameplay
        case .gameOver:
            return .gameOverBackground
        case .friendMarkerGameplay:
            return GameScreenshotLayout.friendMarkerGameplay()
        case .sharePlayWaiting, .achievementUnlock:
            return .hookGameplay
        case .freeUserMenu:
            return .hookGameplay
        }
    }

    public var presentsSettingsSheet: Bool {
        if case .settings = route { return true }
        return false
    }

    public var presentsGameOverSheet: Bool {
        route == .gameOver
    }

    public var presentsMenu: Bool {
        route == .menu
    }

    public var presentsAchievementSheet: Bool {
        route == .achievementUnlock
    }

    public var usesSharePlayWaitingOverlay: Bool {
        self == .sharePlayWaiting
    }

    public var showsPlayWithFriendsOnMenu: Bool {
        self == .freeUserMenu
    }

    public var usesPocketTheme: Bool {
        self == .pocketGameplay
    }

    public func themeID(for platform: String?) -> ThemeID {
        if usesPocketTheme {
            return .pocket
        }
        return ThemePlatformConfig.screenshotCapture(platform: platform).defaultThemeID
    }

    private static func universalFixture(for slideIndex: Int) -> ScreenshotSlideFixture? {
        switch slideIndex {
        case 0: return .hookGameplay
        case 1: return .actionGameplay
        case 2: return .gameOver
        case 3: return .accessibilitySettings
        case 4: return .sharePlayWaiting
        case 5: return .friendMarkerGameplay
        case 6: return .themeSettings
        case 7: return .pocketGameplay
        case 8: return .achievementUnlock
        case 9: return .freeUserMenu
        default: return nil
        }
    }

    private static func macFixture(for slideIndex: Int) -> ScreenshotSlideFixture? {
        switch slideIndex {
        case 0: return .hookGameplay
        case 1: return .actionGameplay
        case 2: return .gameOver
        case 3: return .accessibilitySettings
        case 4: return .friendMarkerGameplay
        case 5: return .themeSettings
        case 6: return .pocketGameplay
        case 7: return .achievementUnlock
        case 8: return .freeUserMenu
        default: return nil
        }
    }
}

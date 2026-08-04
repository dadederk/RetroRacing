//
//  WatchScreenshotSlideFixture.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation

public enum WatchScreenshotCaptureRoute: Equatable, Sendable {
    case gameplay
    case menu
    case settings
    case gameOver
    case achievementUnlock
}

public enum WatchScreenshotSlideFixture: Int, CaseIterable, Sendable {
    case hookGameplay = 0
    case gameOver = 1
    case actionGameplay = 2
    case achievementUnlock = 3
    case themeGameplay = 4
    case menu = 5
    case settings = 6

    public var slideIndex: Int { rawValue }

    public var route: WatchScreenshotCaptureRoute {
        switch self {
        case .hookGameplay, .actionGameplay, .themeGameplay:
            return .gameplay
        case .menu:
            return .menu
        case .settings:
            return .settings
        case .gameOver:
            return .gameOver
        case .achievementUnlock:
            return .achievementUnlock
        }
    }

    public var layout: GameScreenshotLayout? {
        switch self {
        case .hookGameplay, .themeGameplay:
            return .hookGameplay
        case .actionGameplay:
            return .actionGameplay
        case .menu, .settings, .gameOver, .achievementUnlock:
            return nil
        }
    }

    public var themeID: ThemeID {
        switch self {
        case .themeGameplay:
            return .lcd
        case .hookGameplay, .menu, .actionGameplay, .settings, .gameOver, .achievementUnlock:
            return .pocket
        }
    }

    public var presentsSettingsSheet: Bool {
        route == .settings
    }

    public static let slideCount = 7

    public static func fixture(for slideIndex: Int) -> WatchScreenshotSlideFixture? {
        WatchScreenshotSlideFixture(rawValue: slideIndex)
    }
}

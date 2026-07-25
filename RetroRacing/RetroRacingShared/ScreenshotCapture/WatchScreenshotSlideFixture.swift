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
}

public enum WatchScreenshotSlideFixture: Int, CaseIterable, Sendable {
    case hookGameplay = 0
    case menu = 1
    case actionGameplay = 2
    case pocketGameplay = 3
    case settings = 4

    public var slideIndex: Int { rawValue }

    public var route: WatchScreenshotCaptureRoute {
        switch self {
        case .hookGameplay, .actionGameplay, .pocketGameplay:
            return .gameplay
        case .menu:
            return .menu
        case .settings:
            return .settings
        }
    }

    public var layout: GameScreenshotLayout? {
        switch self {
        case .hookGameplay, .pocketGameplay:
            return .hookGameplay
        case .actionGameplay:
            return .actionGameplay
        case .menu, .settings:
            return nil
        }
    }

    public var usesPocketTheme: Bool {
        self == .pocketGameplay
    }

    public var presentsSettingsSheet: Bool {
        route == .settings
    }

    public static let slideCount = 5

    public static func fixture(for slideIndex: Int) -> WatchScreenshotSlideFixture? {
        WatchScreenshotSlideFixture(rawValue: slideIndex)
    }
}

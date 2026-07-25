//
//  WatchScreenshotCaptureConfiguration.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation

public struct WatchScreenshotCaptureConfiguration: Equatable, Sendable {
    public let slideIndex: Int
    public let fixture: WatchScreenshotSlideFixture
    public let stagingDirectory: URL?

    public var readinessIdentifier: String {
        ScreenshotCaptureIdentifiers.readinessIdentifier(slideIndex: slideIndex)
    }

    public static var current: WatchScreenshotCaptureConfiguration? {
        guard ScreenshotCaptureConfiguration.isCaptureModeEnabled else { return nil }
        guard ScreenshotCaptureConfiguration.isWatchCapturePlatform else { return nil }
        guard let slideIndex = ScreenshotCaptureConfiguration.slideIndexFromEnvironment else { return nil }
        guard let fixture = WatchScreenshotSlideFixture.fixture(for: slideIndex) else { return nil }
        return WatchScreenshotCaptureConfiguration(
            slideIndex: slideIndex,
            fixture: fixture,
            stagingDirectory: ScreenshotCaptureConfiguration.stagingDirectoryFromEnvironment
        )
    }
}

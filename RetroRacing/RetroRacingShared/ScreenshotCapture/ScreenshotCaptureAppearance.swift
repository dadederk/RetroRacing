//
//  ScreenshotCaptureAppearance.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation
import SwiftUI

/// App Store screenshot appearance. Capture defaults to light; dark is opt-in via CLI.
public enum ScreenshotCaptureAppearance: String, CaseIterable, Sendable {
    case light
    case dark

    public static let `default`: ScreenshotCaptureAppearance = .light

    public var colorScheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    /// Resolved only during screenshot capture; otherwise returns `.light` unused by UI.
    public static var current: ScreenshotCaptureAppearance {
        guard ScreenshotCaptureConfiguration.isCaptureModeEnabled else {
            return .default
        }
        if let raw = launchArgumentValue(following: "-ScreenshotCaptureAppearance"),
           let appearance = ScreenshotCaptureAppearance(rawValue: raw.lowercased()) {
            return appearance
        }
        if let raw = ProcessInfo.processInfo.environment[ScreenshotCaptureIdentifiers.appearanceKey],
           let appearance = ScreenshotCaptureAppearance(rawValue: raw.lowercased()) {
            return appearance
        }
        return .default
    }

    /// Writes `AppleInterfaceStyle` so UIKit chrome matches SwiftUI preferred scheme during capture.
    public static func applySystemInterfaceStyleIfNeeded() {
        guard ScreenshotCaptureConfiguration.isCaptureModeEnabled else { return }
        UserDefaults.standard.set(
            current == .dark ? "Dark" : "Light",
            forKey: "AppleInterfaceStyle"
        )
        UserDefaults.standard.synchronize()
    }

    private static func launchArgumentValue(following flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }
}

public extension View {
    /// Forces light (default) or dark appearance while App Store screenshot capture is active.
    @ViewBuilder
    func screenshotCaptureColorScheme() -> some View {
        if ScreenshotCaptureConfiguration.isCaptureModeEnabled {
            preferredColorScheme(ScreenshotCaptureAppearance.current.colorScheme)
        } else {
            self
        }
    }
}

//
//  AppStoreScreenshotAppearance.swift
//  RetroRacing
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation

/// Capture appearance for App Store screenshots. Defaults to light; dark is opt-in.
public enum AppStoreScreenshotAppearance: String, CaseIterable, Sendable {
    case light
    case dark

    public static let `default`: AppStoreScreenshotAppearance = .light

    public static func parse(_ raw: String?) throws -> AppStoreScreenshotAppearance {
        guard let raw, raw.isEmpty == false else {
            return .default
        }
        guard let appearance = AppStoreScreenshotAppearance(rawValue: raw.lowercased()) else {
            throw AppStoreScreenshotCaptureError.invalidAppearance(raw)
        }
        return appearance
    }
}

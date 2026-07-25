//
//  ScreenshotCaptureIdentifiers.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public enum ScreenshotCaptureIdentifiers {
    public static let captureEnabledKey = "RETRORAPID_SCREENSHOT_CAPTURE"
    public static let slideIndexKey = "RETRORAPID_SCREENSHOT_SLIDE"
    public static let stagingDirectoryKey = "RETRORAPID_SCREENSHOT_STAGING"
    public static let fileExtensionKey = "RETRORAPID_SCREENSHOT_FILE_EXTENSION"
    public static let platformKey = "RETRORAPID_SCREENSHOT_PLATFORM"
    public static let appearanceKey = "RETRORAPID_SCREENSHOT_APPEARANCE"

    public static func readinessIdentifier(slideIndex: Int) -> String {
        "screenshot-ready-slide-\(slideIndex)"
    }

    public static let settingsAccessibilitySection = "screenshot-settings-accessibility-section"
    public static let settingsThemeSection = "screenshot-settings-theme-section"
    public static let settingsCustomizeSection = "screenshot-settings-customize-section"
}

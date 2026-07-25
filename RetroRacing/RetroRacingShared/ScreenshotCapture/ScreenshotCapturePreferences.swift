//
//  ScreenshotCapturePreferences.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation

/// Deterministic preference overrides for App Store screenshot capture (in-memory only).
public enum ScreenshotCapturePreferences {
    /// Big Cars must stay off in marketing gameplay shots.
    public static let gameplayBigCarsEnabled = false

    public static let gameplayRoadVisualStyle = RoadVisualStyle.detailedRoad
}

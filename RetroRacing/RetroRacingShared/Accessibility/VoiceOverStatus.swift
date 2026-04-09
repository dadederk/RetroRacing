//
//  VoiceOverStatus.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 19/02/2026.
//

import Foundation
#if os(watchOS)
import WatchKit
#elseif os(macOS)
import AppKit
#else
import UIKit
#endif

/// Shared VoiceOver status helper so feature code can stay platform-agnostic.
public enum VoiceOverStatus {
    public static var isVoiceOverRunning: Bool {
        #if os(watchOS)
        WKAccessibilityIsVoiceOverRunning()
        #elseif os(macOS)
        NSWorkspace.shared.isVoiceOverEnabled
        #else
        UIAccessibility.isVoiceOverRunning
        #endif
    }
}

/// Shared Switch Control status helper for achievement telemetry.
/// watchOS currently does not expose an equivalent public runtime status API.
public enum SwitchControlStatus {
    public static var isSwitchControlRunning: Bool {
        #if os(watchOS)
        false
        #elseif os(macOS)
        NSWorkspace.shared.isSwitchControlEnabled
        #else
        UIAccessibility.isSwitchControlRunning
        #endif
    }
}

/// Shared assistive-technology status used by GAAD achievement telemetry.
public enum AssistiveTechnologyStatus {
    public static var activeTechnologies: Set<AchievementAssistiveTechnology> {
        var technologies = Set<AchievementAssistiveTechnology>()
        if VoiceOverStatus.isVoiceOverRunning {
            technologies.insert(.voiceOver)
        }
        if SwitchControlStatus.isSwitchControlRunning {
            technologies.insert(.switchControl)
        }
        return technologies
    }
}

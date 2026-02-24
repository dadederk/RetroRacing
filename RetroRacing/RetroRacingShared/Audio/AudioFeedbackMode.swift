//
//  AudioFeedbackMode.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 17/02/2026.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// User-selectable audio feedback behavior for gameplay guidance.
public enum AudioFeedbackMode: String, CaseIterable, Codable, Sendable {
    case retro
    case cueChord
    case cueArpeggio
    case cueLanePulses

    public static let storageKey = "audioFeedbackMode"
    public static let conditionalDefaultStorageKey = "audioFeedbackMode_conditionalDefault"
    public static let defaultMode: AudioFeedbackMode = .retro

    /// Ordered list for settings pickers: keep chord last because it is the hardest pattern.
    public static let displayOrder: [AudioFeedbackMode] = [
        .retro,
        .cueLanePulses,
        .cueArpeggio,
        .cueChord
    ]

    /// System-derived default: lane pulses when VoiceOver is active on supported platforms.
    public static var systemDefault: AudioFeedbackMode {
        #if os(iOS) || os(tvOS) || os(visionOS)
        if UIAccessibility.isVoiceOverRunning {
            return .cueLanePulses
        }
        return .retro
        #elseif os(watchOS)
        // watchOS VoiceOver state is not currently sourced here; keep retro as the default.
        return .retro
        #elseif os(macOS)
        if NSWorkspace.shared.isVoiceOverEnabled {
            return .cueLanePulses
        }
        return .retro
        #endif
    }

    public var localizedNameKey: String {
        switch self {
        case .retro:
            return "settings_audio_feedback_mode_retro"
        case .cueChord:
            return "settings_audio_feedback_mode_cue_chord"
        case .cueArpeggio:
            return "settings_audio_feedback_mode_cue_arpeggio"
        case .cueLanePulses:
            return "settings_audio_feedback_mode_cue_lane_pulses"
        }
    }

    public var supportsAudioCueTutorial: Bool {
        self != .retro
    }

    public static func currentSelection(from userDefaults: UserDefaults) -> AudioFeedbackMode {
        let conditionalDefault = ConditionalDefault<AudioFeedbackMode>.load(
            from: userDefaults,
            key: conditionalDefaultStorageKey
        )
        return conditionalDefault.effectiveValue
    }
}

extension AudioFeedbackMode: ConditionalDefaultValue {
    // systemDefault is already defined above.
}

//
//  AudioFeedbackMode.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 17/02/2026.
//

import Foundation

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

    /// System-derived default from VoiceOver state.
    public static func systemDefault(isVoiceOverRunning: Bool) -> AudioFeedbackMode {
        isVoiceOverRunning ? .cueLanePulses : .retro
    }

    /// System-derived default from the current platform's VoiceOver status.
    public static var systemDefault: AudioFeedbackMode {
        systemDefault(isVoiceOverRunning: VoiceOverStatus.isVoiceOverRunning)
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

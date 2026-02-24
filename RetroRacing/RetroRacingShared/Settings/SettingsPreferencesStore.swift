import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
public final class SettingsPreferencesStore {
    private let userDefaults: UserDefaults
    private let supportsHaptics: Bool
    private let isVoiceOverRunningProvider: @MainActor @Sendable () -> Bool

    private var difficultyConditionalDefault: ConditionalDefault<GameDifficulty> = ConditionalDefault()
    private var audioFeedbackModeConditionalDefault: ConditionalDefault<AudioFeedbackMode> = ConditionalDefault()
    private var speedWarningFeedbackConditionalDefault: ConditionalDefault<SpeedWarningFeedbackMode> = ConditionalDefault()
    private var soundEffectsVolumeConditionalDefault: ConditionalDefault<SoundEffectsVolumeSetting> = ConditionalDefault()
    private var laneMoveCueStyleRawValue: String = LaneMoveCueStyle.defaultStyle.rawValue
    private var hasLoaded = false

    public init(
        userDefaults: UserDefaults,
        supportsHaptics: Bool,
        isVoiceOverRunningProvider: @escaping @MainActor @Sendable () -> Bool
    ) {
        self.userDefaults = userDefaults
        self.supportsHaptics = supportsHaptics
        self.isVoiceOverRunningProvider = isVoiceOverRunningProvider
    }

    public func loadIfNeeded() {
        guard hasLoaded == false else { return }
        hasLoaded = true
        difficultyConditionalDefault = ConditionalDefault<GameDifficulty>.load(
            from: userDefaults,
            key: GameDifficulty.conditionalDefaultStorageKey
        )
        audioFeedbackModeConditionalDefault = ConditionalDefault<AudioFeedbackMode>.load(
            from: userDefaults,
            key: AudioFeedbackMode.conditionalDefaultStorageKey
        )
        speedWarningFeedbackConditionalDefault = ConditionalDefault<SpeedWarningFeedbackMode>.load(
            from: userDefaults,
            key: SpeedWarningFeedbackMode.conditionalDefaultStorageKey
        )
        soundEffectsVolumeConditionalDefault = ConditionalDefault<SoundEffectsVolumeSetting>.load(
            from: userDefaults,
            key: SoundEffectsVolumeSetting.conditionalDefaultStorageKey
        )
        laneMoveCueStyleRawValue = userDefaults.string(forKey: LaneMoveCueStyle.storageKey)
            ?? LaneMoveCueStyle.defaultStyle.rawValue
    }

    public var difficultySelection: Binding<GameDifficulty> {
        Binding(
            get: { self.selectedDifficulty },
            set: { self.setDifficulty($0) }
        )
    }

    public var audioFeedbackModeSelection: Binding<AudioFeedbackMode> {
        Binding(
            get: { self.selectedAudioFeedbackMode },
            set: { self.setAudioFeedbackMode($0) }
        )
    }

    public var laneMoveCueStyleSelection: Binding<LaneMoveCueStyle> {
        Binding(
            get: { self.selectedLaneMoveCueStyle },
            set: { self.setLaneMoveCueStyle($0) }
        )
    }

    public var speedWarningFeedbackSelection: Binding<SpeedWarningFeedbackMode> {
        Binding(
            get: { self.selectedSpeedWarningFeedbackMode },
            set: { self.setSpeedWarningFeedbackMode($0) }
        )
    }

    public var soundEffectsVolumeSelection: Binding<Double> {
        Binding(
            get: { self.selectedSoundEffectsVolume },
            set: { self.setSoundEffectsVolume($0) }
        )
    }

    public var selectedDifficulty: GameDifficulty {
        difficultyConditionalDefault.effectiveValue
    }

    public var selectedAudioFeedbackMode: AudioFeedbackMode {
        audioFeedbackModeConditionalDefault.effectiveValue
    }

    public var selectedLaneMoveCueStyle: LaneMoveCueStyle {
        let selected = LaneMoveCueStyle.fromStoredValue(laneMoveCueStyleRawValue)
        if supportsHaptics == false && selected == .haptics {
            return .defaultStyle
        }
        return selected
    }

    public var selectedSpeedWarningFeedbackMode: SpeedWarningFeedbackMode {
        SpeedWarningFeedbackPreference.currentSelection(
            from: speedWarningFeedbackConditionalDefault,
            supportsHaptics: supportsHaptics,
            isVoiceOverRunning: isVoiceOverRunningProvider()
        )
    }

    public var selectedSoundEffectsVolume: Double {
        soundEffectsVolumeConditionalDefault.effectiveValue.value
    }

    public var shouldShowAudioCueTutorial: Bool {
        selectedAudioFeedbackMode.supportsAudioCueTutorial
    }

    public var shouldEnableSpeedWarningPreview: Bool {
        selectedSpeedWarningFeedbackMode != .announcement || isVoiceOverRunningProvider()
    }

    public var availableLaneMoveCueStyles: [LaneMoveCueStyle] {
        LaneMoveCueStyle.availableStyles(supportsHaptics: supportsHaptics)
    }

    public var availableSpeedWarningFeedbackModes: [SpeedWarningFeedbackMode] {
        SpeedWarningFeedbackMode.availableModes(supportsHaptics: supportsHaptics)
    }

    public func setDifficulty(_ newValue: GameDifficulty) {
        difficultyConditionalDefault.setUserOverride(newValue)
        difficultyConditionalDefault.save(
            to: userDefaults,
            key: GameDifficulty.conditionalDefaultStorageKey
        )
    }

    public func setAudioFeedbackMode(_ newValue: AudioFeedbackMode) {
        audioFeedbackModeConditionalDefault.setUserOverride(newValue)
        audioFeedbackModeConditionalDefault.save(
            to: userDefaults,
            key: AudioFeedbackMode.conditionalDefaultStorageKey
        )
    }

    public func setLaneMoveCueStyle(_ newValue: LaneMoveCueStyle) {
        laneMoveCueStyleRawValue = newValue.rawValue
        userDefaults.set(newValue.rawValue, forKey: LaneMoveCueStyle.storageKey)
    }

    public func setSpeedWarningFeedbackMode(_ newValue: SpeedWarningFeedbackMode) {
        speedWarningFeedbackConditionalDefault.setUserOverride(newValue)
        speedWarningFeedbackConditionalDefault.save(
            to: userDefaults,
            key: SpeedWarningFeedbackMode.conditionalDefaultStorageKey
        )
    }

    public func setSoundEffectsVolume(_ newValue: Double) {
        soundEffectsVolumeConditionalDefault.setUserOverride(
            SoundEffectsVolumeSetting(value: newValue)
        )
        soundEffectsVolumeConditionalDefault.save(
            to: userDefaults,
            key: SoundEffectsVolumeSetting.conditionalDefaultStorageKey
        )
    }
}

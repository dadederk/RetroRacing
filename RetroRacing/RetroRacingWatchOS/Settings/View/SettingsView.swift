import SwiftUI
import RetroRacingShared

struct SettingsView: View {
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    /// Injected by app; watchOS has Taptic Engine, so true.
    let supportsHapticFeedback: Bool
    let hapticController: HapticFeedbackController?
    let audioCueTutorialPreviewPlayer: AudioCueTutorialPreviewPlayer
    let speedWarningFeedbackPreviewPlayer: any SpeedIncreaseWarningFeedbackPlaying
    /// When true, show "scores submitted…"; when false, show "sign in to Game Center on iPhone…".
    let isGameCenterAuthenticated: Bool
    @Environment(\.dismiss) private var dismiss
    @AppStorage(LaneMoveCueStyle.storageKey) private var laneMoveCueStyleRawValue: String = LaneMoveCueStyle.defaultStyle.rawValue
    @State private var difficultyConditionalDefault: ConditionalDefault<GameDifficulty> = ConditionalDefault()
    @State private var audioFeedbackModeConditionalDefault: ConditionalDefault<AudioFeedbackMode> = ConditionalDefault()
    @State private var speedWarningFeedbackConditionalDefault: ConditionalDefault<SpeedWarningFeedbackMode> = ConditionalDefault()
    @State private var soundEffectsVolumeConditionalDefault: ConditionalDefault<SoundEffectsVolumeSetting> = ConditionalDefault()
    @AppStorage(HapticFeedbackPreference.storageKey) private var hapticFeedbackEnabled: Bool = true
    @State private var showingAudioCueTutorial = false

    private var fontForLabels: Font {
        fontPreferenceStore.font(textStyle: .body)
    }

    var body: some View {
        NavigationStack {
            List {
                if fontPreferenceStore.isCustomFontAvailable {
                    Section {
                        Picker(selection: Binding(
                            get: { fontPreferenceStore.currentStyle },
                            set: { fontPreferenceStore.currentStyle = $0 }
                        )) {
                            Text(GameLocalizedStrings.string("font_style_custom"))
                                .tag(AppFontStyle.custom)
                            Text(GameLocalizedStrings.string("font_style_system"))
                                .tag(AppFontStyle.system)
                            Text(GameLocalizedStrings.string("font_style_system_monospaced"))
                                .tag(AppFontStyle.systemMonospaced)
                        } label: {
                            Text(GameLocalizedStrings.string("settings_font"))
                                .font(fontForLabels)
                        }
                    } header: {
                        Text(GameLocalizedStrings.string("settings_font"))
                            .font(fontForLabels)
                    }
                }

                Section {
                    Picker(selection: Binding(
                        get: { themeManager.currentTheme.id },
                        set: { newID in
                            if let theme = themeManager.availableThemes.first(where: { $0.id == newID }),
                               themeManager.isThemeAvailable(theme) {
                                themeManager.setTheme(theme)
                            }
                        }
                    )) {
                        ForEach(themeManager.availableThemes.filter { themeManager.isThemeAvailable($0) }, id: \.id) { theme in
                            Text(theme.name)
                                .font(fontForLabels)
                                .tag(theme.id)
                        }
                    } label: {
                        Text(GameLocalizedStrings.string("settings_theme"))
                            .font(fontForLabels)
                    }
                } header: {
                    Text(GameLocalizedStrings.string("settings_theme"))
                        .font(fontForLabels)
                }

                Section {
                    Text(GameLocalizedStrings.string("settings_controls_watchos"))
                        .font(fontForLabels)
                } header: {
                    Text(GameLocalizedStrings.string("settings_controls"))
                        .font(fontForLabels)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker(selection: difficultySelection) {
                            ForEach(GameDifficulty.allCases, id: \.self) { difficulty in
                                Text(GameLocalizedStrings.string(difficulty.localizedNameKey))
                                    .font(fontForLabels)
                                    .tag(difficulty)
                            }
                        } label: {
                            Text(GameLocalizedStrings.string("settings_speed"))
                                .font(fontForLabels)
                        }
                        
                        // watchOS doesn't have isVoiceOverRunning API, so no conditional note
                    }
                } header: {
                    Text(GameLocalizedStrings.string("settings_speed"))
                        .font(fontForLabels)
                }

                Section {
                    Text(GameLocalizedStrings.string(
                        isGameCenterAuthenticated
                            ? "settings_leaderboard_watch_info"
                            : "settings_leaderboard_watch_sign_in_required"
                    ))
                    .font(fontForLabels)
                } header: {
                    Text(GameLocalizedStrings.string("leaderboard"))
                        .font(fontForLabels)
                }

                Section {
                    Picker(selection: audioFeedbackModeSelection) {
                        ForEach(AudioFeedbackMode.displayOrder, id: \.self) { mode in
                            Text(GameLocalizedStrings.string(mode.localizedNameKey))
                                .font(fontForLabels)
                                .tag(mode)
                        }
                    } label: {
                        Text(GameLocalizedStrings.string("settings_audio_feedback_mode"))
                            .font(fontForLabels)
                    }

                    if selectedAudioFeedbackMode.supportsAudioCueTutorial {
                        Picker(selection: laneMoveCueStyleSelection) {
                            ForEach(LaneMoveCueStyle.availableStyles(supportsHaptics: supportsHapticFeedback), id: \.self) { style in
                                Text(GameLocalizedStrings.string(style.localizedNameKey))
                                    .font(fontForLabels)
                                    .tag(style)
                            }
                        } label: {
                            Text(GameLocalizedStrings.string("settings_lane_move_cue_style"))
                                .font(fontForLabels)
                        }
                    }

                    Button {
                        showingAudioCueTutorial = true
                    } label: {
                        Text(GameLocalizedStrings.string("settings_audio_cue_tutorial"))
                            .font(fontForLabels)
                    }
                    .buttonStyle(.borderless)

                    Slider(value: soundEffectsVolumeSelection, in: 0...1, step: 0.05) {
                        Text(GameLocalizedStrings.string("settings_sound_effects_volume"))
                            .font(fontForLabels)
                    } minimumValueLabel: {
                        Text(GameLocalizedStrings.string("0%")).font(fontForLabels)
                    } maximumValueLabel: {
                        Text(GameLocalizedStrings.string("100%")).font(fontForLabels)
                    }
                } header: {
                    Text(GameLocalizedStrings.string("settings_sound"))
                        .font(fontForLabels)
                }

                if supportsHapticFeedback {
                    Section {
                        Toggle(isOn: $hapticFeedbackEnabled) {
                            Text(GameLocalizedStrings.string("settings_haptic_feedback"))
                                .font(fontForLabels)
                        }
                        .tint(.accentColor)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker(selection: speedWarningFeedbackSelection) {
                            ForEach(
                                SpeedWarningFeedbackMode.availableModes(supportsHaptics: supportsHapticFeedback),
                                id: \.self
                            ) { mode in
                                Text(GameLocalizedStrings.string(mode.localizedNameKey))
                                    .font(fontForLabels)
                                    .tag(mode)
                            }
                        } label: {
                            Text(GameLocalizedStrings.string("settings_speed_warning_feedback"))
                                .font(fontForLabels)
                        }

                        Button {
                            speedWarningFeedbackPreviewPlayer.play(
                                mode: speedWarningFeedbackConditionalDefault.effectiveValue
                            )
                        } label: {
                            Text(GameLocalizedStrings.string("settings_speed_warning_feedback_preview_warning"))
                                .font(fontForLabels)
                        }
                        .buttonStyle(.borderless)
                    }
                } header: {
                    Text(GameLocalizedStrings.string("settings_accessibility"))
                        .font(fontForLabels)
                }
            }
            .navigationTitle(GameLocalizedStrings.string("settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(GameLocalizedStrings.string("done")) {
                        dismiss()
                    }
                    .font(fontForLabels)
                    .buttonStyle(.glass)
                }
            }
            .onAppear {
                difficultyConditionalDefault = ConditionalDefault<GameDifficulty>.load(
                    from: InfrastructureDefaults.userDefaults,
                    key: GameDifficulty.conditionalDefaultStorageKey
                )
                audioFeedbackModeConditionalDefault = ConditionalDefault<AudioFeedbackMode>.load(
                    from: InfrastructureDefaults.userDefaults,
                    key: AudioFeedbackMode.conditionalDefaultStorageKey
                )
                speedWarningFeedbackConditionalDefault = ConditionalDefault<SpeedWarningFeedbackMode>.load(
                    from: InfrastructureDefaults.userDefaults,
                    key: SpeedWarningFeedbackMode.conditionalDefaultStorageKey
                )
                soundEffectsVolumeConditionalDefault = ConditionalDefault<SoundEffectsVolumeSetting>.load(
                    from: InfrastructureDefaults.userDefaults,
                    key: SoundEffectsVolumeSetting.conditionalDefaultStorageKey
                )
            }
            .sheet(isPresented: $showingAudioCueTutorial) {
                NavigationStack {
                    ScrollView {
                        AudioCueTutorialContentView(
                            previewPlayer: audioCueTutorialPreviewPlayer,
                            speedWarningFeedbackPreviewPlayer: speedWarningFeedbackPreviewPlayer,
                            supportsHapticFeedback: supportsHapticFeedback,
                            hapticController: hapticController
                        )
                            .padding()
                    }
                    .navigationTitle(GameLocalizedStrings.string("settings_audio_cue_tutorial"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(GameLocalizedStrings.string("done")) {
                                showingAudioCueTutorial = false
                            }
                            .font(fontForLabels)
                            .buttonStyle(.glass)
                        }
                    }
                }
            }
            .fontPreferenceStore(fontPreferenceStore)
        }
    }

    private var difficultySelection: Binding<GameDifficulty> {
        Binding(
            get: { difficultyConditionalDefault.effectiveValue },
            set: { newValue in
                difficultyConditionalDefault.setUserOverride(newValue)
                difficultyConditionalDefault.save(
                    to: InfrastructureDefaults.userDefaults,
                    key: GameDifficulty.conditionalDefaultStorageKey
                )
            }
        )
    }

    private var audioFeedbackModeSelection: Binding<AudioFeedbackMode> {
        Binding(
            get: { audioFeedbackModeConditionalDefault.effectiveValue },
            set: { newValue in
                audioFeedbackModeConditionalDefault.setUserOverride(newValue)
                audioFeedbackModeConditionalDefault.save(
                    to: InfrastructureDefaults.userDefaults,
                    key: AudioFeedbackMode.conditionalDefaultStorageKey
                )
            }
        )
    }

    private var laneMoveCueStyleSelection: Binding<LaneMoveCueStyle> {
        Binding(
            get: {
                let selected = LaneMoveCueStyle.fromStoredValue(laneMoveCueStyleRawValue)
                if supportsHapticFeedback == false && selected == .haptics {
                    return .defaultStyle
                }
                return selected
            },
            set: { laneMoveCueStyleRawValue = $0.rawValue }
        )
    }

    private var selectedAudioFeedbackMode: AudioFeedbackMode {
        audioFeedbackModeConditionalDefault.effectiveValue
    }

    private var speedWarningFeedbackSelection: Binding<SpeedWarningFeedbackMode> {
        Binding(
            get: { speedWarningFeedbackConditionalDefault.effectiveValue },
            set: { newValue in
                speedWarningFeedbackConditionalDefault.setUserOverride(newValue)
                speedWarningFeedbackConditionalDefault.save(
                    to: InfrastructureDefaults.userDefaults,
                    key: SpeedWarningFeedbackMode.conditionalDefaultStorageKey
                )
            }
        )
    }

    private var soundEffectsVolumeSelection: Binding<Double> {
        Binding(
            get: { soundEffectsVolumeConditionalDefault.effectiveValue.value },
            set: { newValue in
                soundEffectsVolumeConditionalDefault.setUserOverride(
                    SoundEffectsVolumeSetting(value: newValue)
                )
                soundEffectsVolumeConditionalDefault.save(
                    to: InfrastructureDefaults.userDefaults,
                    key: SoundEffectsVolumeSetting.conditionalDefaultStorageKey
                )
            }
        )
    }
}

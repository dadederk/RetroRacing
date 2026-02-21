import SwiftUI
import RetroRacingShared

struct SettingsView: View {
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    /// Injected by app; watchOS has Taptic Engine, so true.
    let supportsHapticFeedback: Bool
    /// When true, show "scores submitted…"; when false, show "sign in to Game Center on iPhone…".
    let isGameCenterAuthenticated: Bool
    @Environment(\.dismiss) private var dismiss
    @AppStorage(LaneMoveCueStyle.storageKey) private var laneMoveCueStyleRawValue: String = LaneMoveCueStyle.defaultStyle.rawValue
    @State private var difficultyConditionalDefault: ConditionalDefault<GameDifficulty> = ConditionalDefault()
    @State private var audioFeedbackModeConditionalDefault: ConditionalDefault<AudioFeedbackMode> = ConditionalDefault()
    @AppStorage(HapticFeedbackPreference.storageKey) private var hapticFeedbackEnabled: Bool = true
    @AppStorage(SoundPreferences.volumeKey) private var sfxVolume: Double = SoundPreferences.defaultVolume
    @AppStorage(InGameAnnouncementsPreference.storageKey) private var inGameAnnouncementsEnabled: Bool = InGameAnnouncementsPreference.defaultEnabled
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
                            ForEach(LaneMoveCueStyle.allCases, id: \.self) { style in
                                Text(GameLocalizedStrings.string(style.localizedNameKey))
                                    .font(fontForLabels)
                                    .tag(style)
                            }
                        } label: {
                            Text(GameLocalizedStrings.string("settings_lane_move_cue_style"))
                                .font(fontForLabels)
                        }
                    }

                    if selectedAudioFeedbackMode.supportsAudioCueTutorial {
                        Button {
                            showingAudioCueTutorial = true
                        } label: {
                            Text(GameLocalizedStrings.string("settings_audio_cue_tutorial"))
                                .font(fontForLabels)
                        }
                        .buttonStyle(.borderless)
                    }

                    Slider(value: $sfxVolume, in: 0...1, step: 0.05) {
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
                    Toggle(isOn: $inGameAnnouncementsEnabled) {
                        Text(GameLocalizedStrings.string("settings_in_game_announcements"))
                            .font(fontForLabels)
                    }
                    .tint(.accentColor)
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
            }
            .sheet(isPresented: $showingAudioCueTutorial) {
                NavigationStack {
                    ScrollView {
                        AudioCueTutorialContentView()
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
                .fontPreferenceStore(fontPreferenceStore)
            }
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
            get: { LaneMoveCueStyle.fromStoredValue(laneMoveCueStyleRawValue) },
            set: { laneMoveCueStyleRawValue = $0.rawValue }
        )
    }

    private var selectedAudioFeedbackMode: AudioFeedbackMode {
        audioFeedbackModeConditionalDefault.effectiveValue
    }
}

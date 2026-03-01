import SwiftUI
import RetroRacingShared

struct SettingsView: View {
    private static let inlineVolumeControlMinimumWidth: CGFloat = 220

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
    @State private var preferencesStore: SettingsPreferencesStore
    @AppStorage(HapticFeedbackPreference.storageKey) private var hapticFeedbackEnabled: Bool = true
    @State private var showingAudioCueTutorial = false

    private var fontForLabels: Font {
        fontPreferenceStore.font(textStyle: .body)
    }

    init(
        themeManager: ThemeManager,
        fontPreferenceStore: FontPreferenceStore,
        supportsHapticFeedback: Bool,
        hapticController: HapticFeedbackController?,
        audioCueTutorialPreviewPlayer: AudioCueTutorialPreviewPlayer,
        speedWarningFeedbackPreviewPlayer: any SpeedIncreaseWarningFeedbackPlaying,
        isGameCenterAuthenticated: Bool
    ) {
        self.themeManager = themeManager
        self.fontPreferenceStore = fontPreferenceStore
        self.supportsHapticFeedback = supportsHapticFeedback
        self.hapticController = hapticController
        self.audioCueTutorialPreviewPlayer = audioCueTutorialPreviewPlayer
        self.speedWarningFeedbackPreviewPlayer = speedWarningFeedbackPreviewPlayer
        self.isGameCenterAuthenticated = isGameCenterAuthenticated
        _preferencesStore = State(initialValue: SettingsPreferencesStore(
            userDefaults: InfrastructureDefaults.userDefaults,
            supportsHaptics: supportsHapticFeedback,
            isVoiceOverRunningProvider: { VoiceOverStatus.isVoiceOverRunning }
        ))
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
                                .font(fontForLabels)
                                .tag(AppFontStyle.custom)
                            Text(GameLocalizedStrings.string("font_style_system"))
                                .font(fontForLabels)
                                .tag(AppFontStyle.system)
                            Text(GameLocalizedStrings.string("font_style_system_monospaced"))
                                .font(fontForLabels)
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
                        Picker(selection: preferencesStore.difficultySelection) {
                            ForEach(GameDifficulty.allCases, id: \.self) { difficulty in
                                Text(GameLocalizedStrings.string(difficulty.localizedNameKey))
                                    .font(fontForLabels)
                                    .tag(difficulty)
                            }
                        } label: {
                            Text(GameLocalizedStrings.string("settings_speed"))
                                .font(fontForLabels)
                        }
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
                    Picker(selection: preferencesStore.audioFeedbackModeSelection) {
                        ForEach(AudioFeedbackMode.displayOrder, id: \.self) { mode in
                            Text(GameLocalizedStrings.string(mode.localizedNameKey))
                                .font(fontForLabels)
                                .tag(mode)
                        }
                    } label: {
                        Text(GameLocalizedStrings.string("settings_audio_feedback_mode"))
                            .font(fontForLabels)
                    }

                    if preferencesStore.shouldShowAudioCueTutorial {
                        Picker(selection: preferencesStore.laneMoveCueStyleSelection) {
                            ForEach(preferencesStore.availableLaneMoveCueStyles, id: \.self) { style in
                                Text(GameLocalizedStrings.string(style.localizedNameKey))
                                    .font(fontForLabels)
                                    .tag(style)
                            }
                        } label: {
                            Text(GameLocalizedStrings.string("settings_lane_move_cue_style"))
                                .font(fontForLabels)
                        }
                    }

                    if preferencesStore.shouldShowAudioCueTutorial {
                        Button {
                            showingAudioCueTutorial = true
                        } label: {
                            Text(GameLocalizedStrings.string("settings_audio_cue_tutorial"))
                                .font(fontForLabels)
                        }
                        .buttonStyle(.borderless)
                    }

                    volumeControl
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
                        Picker(selection: preferencesStore.speedWarningFeedbackSelection) {
                            ForEach(preferencesStore.availableSpeedWarningFeedbackModes, id: \.self) { mode in
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
                                mode: preferencesStore.selectedSpeedWarningFeedbackMode
                            )
                        } label: {
                            Text(GameLocalizedStrings.string("settings_speed_warning_feedback_preview_warning"))
                                .font(fontForLabels)
                        }
                        .buttonStyle(.borderless)
                        .disabled(preferencesStore.shouldEnableSpeedWarningPreview == false)
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
            .onAppear { preferencesStore.loadIfNeeded() }
            .sheet(isPresented: $showingAudioCueTutorial, onDismiss: {
                preferencesStore.reloadFromStorage()
            }) {
                NavigationStack {
                    ScrollView {
                        AudioCueTutorialContentView(
                            previewPlayer: audioCueTutorialPreviewPlayer,
                            speedWarningFeedbackPreviewPlayer: speedWarningFeedbackPreviewPlayer,
                            supportsHapticFeedback: supportsHapticFeedback,
                            hapticController: hapticController,
                            showAudioCueSections: true
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

    @ViewBuilder
    private var volumeControl: some View {
        ViewThatFits(in: .horizontal) {
            inlineVolumeControl
                .frame(minWidth: Self.inlineVolumeControlMinimumWidth)

            compactVolumeControl
        }
    }

    private var inlineVolumeControl: some View {
        Slider(value: preferencesStore.soundEffectsVolumeSelection, in: 0...1, step: 0.05) {
            Text(GameLocalizedStrings.string("settings_sound_effects_volume"))
                .font(fontForLabels)
        } minimumValueLabel: {
            Text(GameLocalizedStrings.string("0%"))
                .font(fontForLabels)
        } maximumValueLabel: {
            Text(GameLocalizedStrings.string("100%"))
                .font(fontForLabels)
        }
    }

    private var compactVolumeControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Slider(value: preferencesStore.soundEffectsVolumeSelection, in: 0...1, step: 0.05) {
                Text(GameLocalizedStrings.string("settings_sound_effects_volume"))
                    .font(fontForLabels)
            }
            HStack {
                Text(GameLocalizedStrings.string("0%"))
                    .font(fontForLabels)
                Spacer()
                Text(GameLocalizedStrings.string("100%"))
                    .font(fontForLabels)
            }
        }
    }
}

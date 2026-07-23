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
    let achievementProgressService: AchievementProgressService
    @Environment(\.dismiss) private var dismiss
    @State private var preferencesStore: SettingsPreferencesStore
    @AppStorage(HapticFeedbackPreference.storageKey) private var hapticFeedbackEnabled: Bool = true
    @State private var presentedSettingsSheet: PresentedSettingsSheet?

    private var fontForLabels: Font {
        fontPreferenceStore.font(textStyle: .body)
    }

    private var sectionHeaderFont: Font {
        fontPreferenceStore.font(textStyle: .headline)
    }

    private enum PresentedSettingsSheet: Hashable, Identifiable {
        case audioCueTutorial
        case controlsHelp

        var id: Self { self }
    }

    init(
        themeManager: ThemeManager,
        fontPreferenceStore: FontPreferenceStore,
        supportsHapticFeedback: Bool,
        hapticController: HapticFeedbackController?,
        audioCueTutorialPreviewPlayer: AudioCueTutorialPreviewPlayer,
        speedWarningFeedbackPreviewPlayer: any SpeedIncreaseWarningFeedbackPlaying,
        isGameCenterAuthenticated: Bool,
        achievementProgressService: AchievementProgressService
    ) {
        self.themeManager = themeManager
        self.fontPreferenceStore = fontPreferenceStore
        self.supportsHapticFeedback = supportsHapticFeedback
        self.hapticController = hapticController
        self.audioCueTutorialPreviewPlayer = audioCueTutorialPreviewPlayer
        self.speedWarningFeedbackPreviewPlayer = speedWarningFeedbackPreviewPlayer
        self.isGameCenterAuthenticated = isGameCenterAuthenticated
        self.achievementProgressService = achievementProgressService
        _preferencesStore = State(initialValue: SettingsPreferencesStore(
            userDefaults: InfrastructureDefaults.userDefaults,
            supportsHaptics: supportsHapticFeedback,
            isVoiceOverRunningProvider: { VoiceOverStatus.isVoiceOverRunning }
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                themeSection
                fontSection
                speedSection
                leaderboardSection
                soundSection
                vibrationSection
                controlsSection
                accessibilitySection
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
            .sheet(item: $presentedSettingsSheet, onDismiss: {
                preferencesStore.reloadFromStorage()
            }) { sheet in
                sheetContent(for: sheet)
            }
            .fontPreferenceStore(fontPreferenceStore)
        }
    }

    private var themeSection: some View {
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
                Text(GameLocalizedStrings.string("settings_theme_style"))
                    .font(fontForLabels)
            }
        } header: {
            settingsSectionHeader("settings_theme")
        }
    }

    @ViewBuilder
    private var fontSection: some View {
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
                settingsSectionHeader("settings_font")
            }
        }
    }

    private var speedSection: some View {
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
            settingsSectionHeader("settings_speed")
        }
    }

    private var leaderboardSection: some View {
        Section {
            Text(GameLocalizedStrings.string(
                isGameCenterAuthenticated
                    ? "settings_leaderboard_watch_info"
                    : "settings_leaderboard_watch_sign_in_required"
            ))
            .font(fontForLabels)
        } header: {
            settingsSectionHeader("leaderboard")
        }
    }

    private var soundSection: some View {
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
                    presentedSettingsSheet = .audioCueTutorial
                } label: {
                    Text(GameLocalizedStrings.string("settings_audio_cue_tutorial"))
                        .font(fontForLabels)
                }
                .buttonStyle(.borderless)
            }

            volumeControl
        } header: {
            settingsSectionHeader("settings_sound")
        }
    }

    @ViewBuilder
    private var vibrationSection: some View {
        if supportsHapticFeedback {
            Section {
                Toggle(isOn: $hapticFeedbackEnabled) {
                    Text(GameLocalizedStrings.string("settings_haptic_feedback"))
                        .font(fontForLabels)
                }
                .tint(.accentColor)
            } header: {
                settingsSectionHeader("settings_vibration")
            }
        }
    }

    private var controlsSection: some View {
        Section {
            Button {
                presentedSettingsSheet = .controlsHelp
            } label: {
                Label(
                    GameLocalizedStrings.string("settings_controls_how_to_play"),
                    systemImage: "questionmark.circle"
                )
                .font(fontForLabels)
            }
        } header: {
            settingsSectionHeader("settings_controls")
        }
    }

    private var accessibilitySection: some View {
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

                Toggle(isOn: preferencesStore.directTouchSelection) {
                    Text(GameLocalizedStrings.string("settings_direct_touch"))
                        .font(fontForLabels)
                }
                .tint(.accentColor)
            }
        } header: {
            settingsSectionHeader("settings_accessibility")
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: PresentedSettingsSheet) -> some View {
        switch sheet {
        case .audioCueTutorial:
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
                            presentedSettingsSheet = nil
                        }
                        .font(fontForLabels)
                        .buttonStyle(.glass)
                    }
                }
            }
            .fontPreferenceStore(fontPreferenceStore)
        case .controlsHelp:
            NavigationStack {
                List {
                    Section {
                        ControlsHelpContentView(
                            controlsDescriptionKey: "settings_controls_watchos",
                            showTitle: false
                        )
                    } header: {
                        settingsSectionHeader("settings_controls")
                    }
                }
                .navigationTitle(GameLocalizedStrings.string("settings_controls_how_to_play"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(GameLocalizedStrings.string("done")) {
                            presentedSettingsSheet = nil
                        }
                        .font(fontForLabels)
                        .buttonStyle(.glass)
                    }
                }
            }
            .fontPreferenceStore(fontPreferenceStore)
        }
    }

    @ViewBuilder
    private func settingsSectionHeader(_ key: String) -> some View {
        Text(GameLocalizedStrings.string(key))
            .retroSectionHeader(font: sectionHeaderFont)
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
                .accessibilityHidden(true)
        } maximumValueLabel: {
            Text(GameLocalizedStrings.string("100%"))
                .font(fontForLabels)
                .accessibilityHidden(true)
        }
        .accessibilityLabel(Text(GameLocalizedStrings.string("settings_sound_effects_volume")))
        .accessibilityValue(Text(soundEffectsVolumeAccessibilityValue))
    }

    private var compactVolumeControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Slider(value: preferencesStore.soundEffectsVolumeSelection, in: 0...1, step: 0.05) {
                Text(GameLocalizedStrings.string("settings_sound_effects_volume"))
                    .font(fontForLabels)
            }
            .accessibilityLabel(Text(GameLocalizedStrings.string("settings_sound_effects_volume")))
            .accessibilityValue(Text(soundEffectsVolumeAccessibilityValue))
            HStack {
                Text(GameLocalizedStrings.string("0%"))
                    .font(fontForLabels)
                    .accessibilityHidden(true)
                Spacer()
                Text(GameLocalizedStrings.string("100%"))
                    .font(fontForLabels)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
        }
    }

    private var soundEffectsVolumeAccessibilityValue: String {
        let clampedValue = min(max(preferencesStore.soundEffectsVolumeSelection.wrappedValue, 0), 1)
        let percent = Int64((clampedValue * 100).rounded())
        return GameLocalizedStrings.format("settings_percentage_value", percent)
    }
}

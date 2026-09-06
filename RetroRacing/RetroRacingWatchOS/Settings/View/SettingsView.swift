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
    let screenshotFocus: ScreenshotSettingsFocus?
    let onScreenshotLayoutReady: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var preferencesStore: SettingsPreferencesStore
    @AppStorage(HapticFeedbackPreference.storageKey) private var hapticFeedbackEnabled: Bool = true
    @State private var presentedSettingsSheet: PresentedSettingsSheet?

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
        achievementProgressService: AchievementProgressService,
        screenshotFocus: ScreenshotSettingsFocus? = nil,
        onScreenshotLayoutReady: (() -> Void)? = nil
    ) {
        self.themeManager = themeManager
        self.fontPreferenceStore = fontPreferenceStore
        self.supportsHapticFeedback = supportsHapticFeedback
        self.hapticController = hapticController
        self.audioCueTutorialPreviewPlayer = audioCueTutorialPreviewPlayer
        self.speedWarningFeedbackPreviewPlayer = speedWarningFeedbackPreviewPlayer
        self.isGameCenterAuthenticated = isGameCenterAuthenticated
        self.achievementProgressService = achievementProgressService
        self.screenshotFocus = screenshotFocus
        self.onScreenshotLayoutReady = onScreenshotLayoutReady
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
                debugSection
            }
            .onAppear {
                preferencesStore.loadIfNeeded()
                prepareScreenshotLayout()
            }
            .navigationTitle(
                screenshotFocus == nil ? GameLocalizedStrings.string("settings") : ""
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(GameLocalizedStrings.string("done")) {
                        dismiss()
                    }
                    .appFont(.body)
                    .buttonStyle(.glass)
                }
            }
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
                        .appFont(.body)
                        .tag(theme.id)
                }
            } label: {
                Text(GameLocalizedStrings.string("settings_theme_style"))
                    .appFont(.body)
            }
        } header: {
            settingsSectionHeader("settings_theme")
        }
    }

    private var fontSection: some View {
        Section {
            NavigationLink {
                FontSelectionView(fontPreferenceStore: fontPreferenceStore)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(GameLocalizedStrings.string("settings_font"))
                        .appFont(.body)
                    Text(fontPreferenceStore.currentStyle.localizedName)
                        .appFont(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityValue(fontPreferenceStore.currentStyle.localizedName)
            .accessibilityIdentifier("settings_font_selection")
        } header: {
            settingsSectionHeader("settings_font")
        }
    }

    private var speedSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Picker(selection: preferencesStore.difficultySelection) {
                    ForEach(GameDifficulty.allCases, id: \.self) { difficulty in
                        Label {
                            Text(GameLocalizedStrings.string(difficulty.localizedNameKey))
                        } icon: {
                            Image(systemName: difficulty.gaugeSystemImageName)
                                .accessibilityHidden(true)
                        }
                        .appFont(.body)
                        .accessibilityLabel(GameLocalizedStrings.string(difficulty.localizedNameKey))
                        .tag(difficulty)
                    }
                } label: {
                    Text(GameLocalizedStrings.string("settings_speed"))
                        .appFont(.body)
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
            .appFont(.body)
        } header: {
            settingsSectionHeader("leaderboard")
        }
    }

    private var soundSection: some View {
        Section {
            Picker(selection: preferencesStore.audioFeedbackModeSelection) {
                ForEach(AudioFeedbackMode.displayOrder, id: \.self) { mode in
                    Text(GameLocalizedStrings.string(mode.localizedNameKey))
                        .appFont(.body)
                        .tag(mode)
                }
            } label: {
                Text(GameLocalizedStrings.string("settings_audio_feedback_mode"))
                    .appFont(.body)
            }

            if preferencesStore.shouldShowAudioCueTutorial {
                Picker(selection: preferencesStore.laneMoveCueStyleSelection) {
                    ForEach(preferencesStore.availableLaneMoveCueStyles, id: \.self) { style in
                        Text(GameLocalizedStrings.string(style.localizedNameKey))
                            .appFont(.body)
                            .tag(style)
                    }
                } label: {
                    Text(GameLocalizedStrings.string("settings_lane_move_cue_style"))
                        .appFont(.body)
                }
            }

            if preferencesStore.shouldShowAudioCueTutorial {
                Button {
                    presentedSettingsSheet = .audioCueTutorial
                } label: {
                    Text(GameLocalizedStrings.string("settings_audio_cue_tutorial"))
                        .appFont(.body)
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
                        .appFont(.body)
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
                .appFont(.body)
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
                            .appFont(.body)
                            .tag(mode)
                    }
                } label: {
                    Text(GameLocalizedStrings.string("settings_speed_warning_feedback"))
                        .appFont(.body)
                }

                Button {
                    speedWarningFeedbackPreviewPlayer.play(
                        mode: preferencesStore.selectedSpeedWarningFeedbackMode
                    )
                } label: {
                    Text(GameLocalizedStrings.string("settings_speed_warning_feedback_preview_warning"))
                        .appFont(.body)
                }
                .buttonStyle(.borderless)
                .disabled(preferencesStore.shouldEnableSpeedWarningPreview == false)

                Toggle(isOn: preferencesStore.directTouchSelection) {
                    Text(GameLocalizedStrings.string("settings_direct_touch"))
                        .appFont(.body)
                }
                .tint(.accentColor)
            }
        } header: {
            settingsSectionHeader("settings_accessibility")
        }
    }

    @ViewBuilder
    private var debugSection: some View {
        if BuildConfiguration.shouldShowDebugFeatures {
            Section {
                if let features = themeManager.releaseFeatures {
                    ReleaseFeatureDebugControls(
                        features: features, showsIcons: false, isGameSessionInProgress: false
                    ) {
                        themeManager.refreshReleaseFeatures()
                    }
                }
            } header: {
                settingsSectionHeader("debug_section_title")
            }
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
                        .appFont(.body)
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
                        .appFont(.body)
                        .buttonStyle(.glass)
                    }
                }
            }
            .fontPreferenceStore(fontPreferenceStore)
        }
    }

    @ViewBuilder
    private func settingsSectionHeader(_ key: String) -> some View {
        if screenshotFocus != nil {
            Text(GameLocalizedStrings.string(key))
                .retroSectionHeader()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        } else {
            Text(GameLocalizedStrings.string(key))
                .retroSectionHeader()
        }
    }

    private func prepareScreenshotLayout() {
        guard screenshotFocus == .themeAndFont else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            onScreenshotLayoutReady?()
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
                .appFont(.body)
        } minimumValueLabel: {
            Text(GameLocalizedStrings.string("0%"))
                .appFont(.body)
                .accessibilityHidden(true)
        } maximumValueLabel: {
            Text(GameLocalizedStrings.string("100%"))
                .appFont(.body)
                .accessibilityHidden(true)
        }
        .accessibilityLabel(Text(GameLocalizedStrings.string("settings_sound_effects_volume")))
        .accessibilityValue(Text(soundEffectsVolumeAccessibilityValue))
    }

    private var compactVolumeControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            Slider(value: preferencesStore.soundEffectsVolumeSelection, in: 0...1, step: 0.05) {
                Text(GameLocalizedStrings.string("settings_sound_effects_volume"))
                    .appFont(.body)
            }
            .accessibilityLabel(Text(GameLocalizedStrings.string("settings_sound_effects_volume")))
            .accessibilityValue(Text(soundEffectsVolumeAccessibilityValue))
            HStack {
                Text(GameLocalizedStrings.string("0%"))
                    .appFont(.body)
                    .accessibilityHidden(true)
                Spacer()
                Text(GameLocalizedStrings.string("100%"))
                    .appFont(.body)
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

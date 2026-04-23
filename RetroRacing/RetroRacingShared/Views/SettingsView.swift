//
//  SettingsView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
import StoreKit
#if os(macOS)
import AppKit
#endif

/// Settings surface for themes, fonts, audio, optional haptics, purchases, debug, and About.
public struct SettingsView: View {
    public let themeManager: ThemeManager
    public let fontPreferenceStore: FontPreferenceStore
    /// Injected by app; when false, haptic feedback section is hidden (device has no haptics).
    public let supportsHapticFeedback: Bool
    public let hapticController: HapticFeedbackController?
    public let audioCueTutorialPreviewPlayer: AudioCueTutorialPreviewPlayer
    public let speedWarningFeedbackPreviewPlayer: any SpeedIncreaseWarningFeedbackPlaying
    public let controlsDescriptionKey: String
    public let style: SettingsViewStyle
    /// When true, gameplay-critical settings (theme and speed) are read-only.
    public let isGameSessionInProgress: Bool
    /// Optional play limit service for showing remaining rounds.
    public let playLimitService: PlayLimitService?
    /// Optional special-event service for showing the event banner in place of the play limit.
    public let specialEventService: SpecialEventService?
    public let achievementProgressService: AchievementProgressService

    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitService.self) private var storeKit
    @State private var preferencesStore: SettingsPreferencesStore
    @AppStorage(HapticFeedbackPreference.storageKey) private var hapticFeedbackEnabled: Bool = true
    @AppStorage(FriendOvertakeVoiceOverAnnouncementPreference.storageKey)
    private var friendOvertakeVoiceOverAnnouncementEnabled: Bool = FriendOvertakeVoiceOverAnnouncementPreference.defaultEnabled
    @AppStorage(DebugGameplayStorageKeys.forcedAchievementIdentifier)
    private var debugForcedAchievementIdentifierRawValue: String = DebugGameplayStorageKeys.noForcedAchievementIdentifier
    @AppStorage(DebugGameplayStorageKeys.showSpriteKitFrameStats) private var debugShowSpriteKitFrameStats: Bool = false
    @State private var isRestoringPurchases = false
    @State private var restoreMessage: String?
    @State private var showingRestoreAlert = false
    @State private var showingPaywall = false
    @State private var showingOfferCodeRedemption = false
    @State private var showingAudioCueTutorial = false
    #if os(macOS)
    @State private var offerCodeRedemptionHostController: NSViewController?
    @State private var isRedeemingOfferCode = false
    #endif
    public init(
        themeManager: ThemeManager,
        fontPreferenceStore: FontPreferenceStore,
        supportsHapticFeedback: Bool,
        hapticController: HapticFeedbackController?,
        audioCueTutorialPreviewPlayer: AudioCueTutorialPreviewPlayer,
        speedWarningFeedbackPreviewPlayer: any SpeedIncreaseWarningFeedbackPlaying,
        controlsDescriptionKey: String,
        style: SettingsViewStyle,
        achievementProgressService: AchievementProgressService,
        isGameSessionInProgress: Bool = false,
        playLimitService: PlayLimitService? = nil,
        specialEventService: SpecialEventService? = nil
    ) {
        self.themeManager = themeManager
        self.fontPreferenceStore = fontPreferenceStore
        self.supportsHapticFeedback = supportsHapticFeedback
        self.hapticController = hapticController
        self.audioCueTutorialPreviewPlayer = audioCueTutorialPreviewPlayer
        self.speedWarningFeedbackPreviewPlayer = speedWarningFeedbackPreviewPlayer
        self.controlsDescriptionKey = controlsDescriptionKey
        self.style = style
        self.achievementProgressService = achievementProgressService
        self.isGameSessionInProgress = isGameSessionInProgress
        self.playLimitService = playLimitService
        self.specialEventService = specialEventService
        _preferencesStore = State(initialValue: SettingsPreferencesStore(
            userDefaults: InfrastructureDefaults.userDefaults,
            supportsHaptics: supportsHapticFeedback,
            isVoiceOverRunningProvider: { VoiceOverStatus.isVoiceOverRunning }
        ))
    }
    private var fontForLabels: Font {
        fontPreferenceStore.font(textStyle: .body)
    }
    private var secondaryFont: Font {
        fontPreferenceStore.font(textStyle: .caption)
    }
    public var body: some View {
        settingsContent
            #if os(macOS)
            .frame(minWidth: 420, minHeight: 380)
            #endif
            .onAppear {
                preferencesStore.loadIfNeeded()
            }
    }
    private var settingsContent: some View {
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
                    if storeKit.hasPremiumAccess {
                        Picker(selection: Binding(
                            get: { themeManager.currentTheme.id },
                            set: { newID in
                                if let theme = themeManager.availableThemes.first(where: { $0.id == newID }) {
                                    themeManager.setTheme(theme)
                                }
                            }
                        )) {
                            ForEach(themeManager.availableThemes, id: \.id) { theme in
                                Text(theme.name)
                                    .font(fontForLabels)
                                    .tag(theme.id)
                            }
                        } label: {
                            Text(GameLocalizedStrings.string("settings_theme"))
                                .font(fontForLabels)
                        }
                        .disabled(isGameSessionInProgress)
                    } else {
                        HStack {
                            Text(GameLocalizedStrings.string("settings_theme"))
                                .font(fontForLabels)
                            Spacer()
                            Text(themeManager.currentTheme.name)
                                .font(fontForLabels)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(GameLocalizedStrings.string("settings_theme")))
                        .accessibilityValue(Text(themeManager.currentTheme.name))
                    }
                } header: {
                    Text(GameLocalizedStrings.string("settings_theme"))
                        .font(fontForLabels)
                } footer: {
                    if !storeKit.hasPremiumAccess {
                        Text(GameLocalizedStrings.string("settings_theme_unlock_footnote"))
                            .font(secondaryFont)
                            .modifier(SettingsFooterTextStyle())
                    }
                }

                if let playLimitService, !storeKit.hasPremiumAccess {
                    let now = Date()
                    let activeEventInfo = specialEventService?.eventInfo(on: now)

                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            if let eventInfo = activeEventInfo {
                                Text(GameLocalizedStrings.string("event_play_unlimited_title"))
                                    .font(fontForLabels)
                                Text(eventSubtitle(for: eventInfo))
                                    .font(fontForLabels)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(playLimitTitle(for: playLimitService))
                                    .font(fontForLabels)
                                if let subtitle = playLimitSubtitle(for: playLimitService) {
                                    Text(subtitle)
                                        .font(fontForLabels)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    } header: {
                        Text(GameLocalizedStrings.string("play_limit_title"))
                            .font(fontForLabels)
                    } footer: {
                        if activeEventInfo == nil {
                            Text(playLimitFooter(for: playLimitService))
                                .font(secondaryFont)
                                .modifier(SettingsFooterTextStyle())
                        }
                    }
                }

                Section {
                    Text(GameLocalizedStrings.string(controlsDescriptionKey))
                        .font(fontForLabels)
                } header: {
                    Text(GameLocalizedStrings.string("settings_controls"))
                        .font(fontForLabels)
                }

                Section {
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
                    .disabled(isGameSessionInProgress)
                } header: {
                    Text(GameLocalizedStrings.string("settings_speed"))
                        .font(fontForLabels)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
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

                    #if os(tvOS)
                    Picker(selection: volumeSelection) {
                        ForEach(Self.volumeSteps, id: \.self) { value in
                            Text(GameLocalizedStrings.format("settings_percentage_value", Int64(value * 100)))
                                .font(fontForLabels)
                                .tag(value)
                        }
                    } label: {
                        Text(GameLocalizedStrings.string("settings_sound_effects_volume"))
                            .font(fontForLabels)
                    }
                    #else
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
                    #endif
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
                    } header: {
                        Text(GameLocalizedStrings.string("settings_vibration"))
                            .font(fontForLabels)
                    }
                }

                Section {
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

                    Picker(selection: preferencesStore.roadVisualStyleSelection) {
                        ForEach(RoadVisualStyle.allCases, id: \.self) { style in
                            Text(GameLocalizedStrings.string(style.localizedNameKey))
                                .font(fontForLabels)
                                .tag(style)
                        }
                    } label: {
                        Text(GameLocalizedStrings.string("settings_road_visual_style"))
                            .font(fontForLabels)
                    }

                    Toggle(isOn: preferencesStore.bigCarsSelection) {
                        Text(GameLocalizedStrings.string("settings_big_cars"))
                            .font(fontForLabels)
                    }
                    .tint(.accentColor)

                    Toggle(isOn: preferencesStore.directTouchSelection) {
                        Text(GameLocalizedStrings.string("settings_direct_touch"))
                            .font(fontForLabels)
                    }
                    .tint(.accentColor)

                    Toggle(isOn: $friendOvertakeVoiceOverAnnouncementEnabled) {
                        Text(GameLocalizedStrings.string("settings_voiceover_friend_overtake_announcements"))
                            .font(fontForLabels)
                    }
                    .tint(.accentColor)
                } header: {
                    Text(GameLocalizedStrings.string("settings_accessibility"))
                        .font(fontForLabels)
                }

                Section {
                    Picker(selection: preferencesStore.controllerLeftButtonSelection) {
                        ForEach(GameControllerRemapButton.allCases, id: \.self) { button in
                            Text(GameLocalizedStrings.string(button.localizedNameKey))
                                .font(fontForLabels)
                                .tag(button)
                        }
                    } label: {
                        Text(GameLocalizedStrings.string("settings_controller_move_left"))
                            .font(fontForLabels)
                    }
                    Picker(selection: preferencesStore.controllerRightButtonSelection) {
                        ForEach(GameControllerRemapButton.allCases, id: \.self) { button in
                            Text(GameLocalizedStrings.string(button.localizedNameKey))
                                .font(fontForLabels)
                                .tag(button)
                        }
                    } label: {
                        Text(GameLocalizedStrings.string("settings_controller_move_right"))
                            .font(fontForLabels)
                    }
                    Picker(selection: preferencesStore.controllerPauseButtonSelection) {
                        ForEach(GameControllerRemapButton.allCases, id: \.self) { button in
                            Text(GameLocalizedStrings.string(button.localizedNameKey))
                                .font(fontForLabels)
                                .tag(button)
                        }
                    } label: {
                        Text(GameLocalizedStrings.string("settings_controller_pause_resume"))
                            .font(fontForLabels)
                    }
                } header: {
                    Text(GameLocalizedStrings.string("settings_controller"))
                        .font(fontForLabels)
                } footer: {
                    #if os(macOS)
                    inlineSectionFooterRow(text: GameLocalizedStrings.string("settings_controller_footnote"))
                    #else
                    Text(GameLocalizedStrings.string("settings_controller_footnote"))
                        .font(secondaryFont)
                        .modifier(SettingsFooterTextStyle())
                    #endif
                }

                Section {
                    if storeKit.hasPremiumAccess {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.accentColor)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(GameLocalizedStrings.string("settings_premium_active"))
                                    .font(fontForLabels)
                                Text(GameLocalizedStrings.string("settings_premium_active_subtitle"))
                                    .font(secondaryFont)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                    }

                    if !storeKit.hasPremiumAccess {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "star.circle.fill")
                                    .foregroundColor(.accentColor)
                                Text(GameLocalizedStrings.string("settings_learn_premium"))
                                    .font(fontForLabels)
                                    .foregroundColor(.accentColor)
                                Spacer()
                            }
                        }

                        #if os(iOS)
                        Button {
                            showingOfferCodeRedemption = true
                        } label: {
                            HStack {
                                Image(systemName: "giftcard")
                                    .foregroundColor(.accentColor)
                                Text(GameLocalizedStrings.string("redeem_code"))
                                    .font(fontForLabels)
                                    .foregroundColor(.accentColor)
                                Spacer()
                            }
                        }
                        .offerCodeRedemption(isPresented: $showingOfferCodeRedemption) { result in
                            if case .success = result {
                                Task { await storeKit.refreshPurchasedProducts() }
                            }
                        }
                        #elseif os(macOS)
                        Button {
                            Task { await redeemOfferCode() }
                        } label: {
                            HStack {
                                if isRedeemingOfferCode {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                } else {
                                    Image(systemName: "giftcard")
                                        .foregroundColor(.accentColor)
                                }
                                Text(GameLocalizedStrings.string("redeem_code"))
                                    .font(fontForLabels)
                                    .foregroundColor(.accentColor)
                                Spacer()
                            }
                        }
                        .disabled(isRedeemingOfferCode)
                        #endif

                        Button {
                            Task { await restorePurchases() }
                        } label: {
                            HStack {
                                if isRestoringPurchases {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                } else {
                                    Image(systemName: "arrow.clockwise.circle")
                                        .foregroundColor(.accentColor)
                                }
                                Text(GameLocalizedStrings.string("restore_purchases"))
                                    .font(fontForLabels)
                                    .foregroundColor(.accentColor)
                                Spacer()
                            }
                        }
                        .disabled(isRestoringPurchases)
                    }

                    #if os(macOS)
                    if !storeKit.hasPremiumAccess {
                        inlineSectionFooterRow(text: GameLocalizedStrings.string("settings_restore_footer"))
                    }
                    #endif
                } header: {
                    Text(GameLocalizedStrings.string("settings_purchases_title"))
                        .font(fontForLabels)
                } footer: {
                    #if os(macOS)
                    EmptyView()
                    #else
                    if !storeKit.hasPremiumAccess {
                        Text(GameLocalizedStrings.string("settings_restore_footer"))
                            .font(secondaryFont)
                            .modifier(SettingsFooterTextStyle())
                    }
                    #endif
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label(GameLocalizedStrings.string("about_title"), systemImage: "info.circle")
                            .font(fontForLabels)
                    }
                }

                if BuildConfiguration.shouldShowDebugFeatures {
                    Section {
                        Picker(
                            selection: Binding(
                                get: { storeKit.debugPremiumSimulationMode },
                                set: { storeKit.debugPremiumSimulationMode = $0 }
                            )
                        ) {
                            Text(GameLocalizedStrings.string("debug_simulation_mode_default"))
                                .font(fontForLabels)
                                .tag(StoreKitService.DebugPremiumSimulationMode.productionDefault)
                            Text(GameLocalizedStrings.string("debug_simulation_mode_unlimited"))
                                .font(fontForLabels)
                                .tag(StoreKitService.DebugPremiumSimulationMode.unlimitedPlays)
                            Text(GameLocalizedStrings.string("debug_simulation_mode_freemium"))
                                .font(fontForLabels)
                                .tag(StoreKitService.DebugPremiumSimulationMode.freemium)
                        } label: {
                            Text(GameLocalizedStrings.string("debug_simulate_premium"))
                                .font(fontForLabels)
                        }

                        #if os(macOS)
                        inlineSectionFooterRow(text: GameLocalizedStrings.string("debug_simulate_premium_footer"))
                        #endif

                        Picker(selection: $debugForcedAchievementIdentifierRawValue) {
                            Text(GameLocalizedStrings.string("debug_force_achievement_none"))
                                .font(fontForLabels)
                                .tag(DebugGameplayStorageKeys.noForcedAchievementIdentifier)
                            ForEach(debugAchievementPickerOptions, id: \.rawValue) { achievementIdentifier in
                                Text(achievementIdentifier.localizedTitle)
                                    .font(fontForLabels)
                                    .tag(achievementIdentifier.rawValue)
                            }
                        } label: {
                            Text(GameLocalizedStrings.string("debug_force_achievement_picker_title"))
                                .font(fontForLabels)
                        }

                        Text(GameLocalizedStrings.string("debug_force_achievement_picker_footer"))
                            .font(secondaryFont)
                            .foregroundStyle(.secondary)

                        Toggle(isOn: $debugShowSpriteKitFrameStats) {
                            Text(GameLocalizedStrings.string("debug_show_spritekit_frame_stats"))
                                .font(fontForLabels)
                        }
                        .tint(.accentColor)

                        Text(GameLocalizedStrings.string("debug_gaad_panel_title"))
                            .font(fontForLabels)

                        GAADAchievementDebugPanel(
                            achievementProgressService: achievementProgressService,
                            qualificationMode: .voiceOverAndSwitchControl,
                            primaryFont: fontForLabels,
                            secondaryFont: secondaryFont
                        )
                    } header: {
                        Text(GameLocalizedStrings.string("debug_section_title"))
                            .font(fontForLabels)
                    } footer: {
                        #if os(macOS)
                        EmptyView()
                        #else
                        Text(GameLocalizedStrings.string("debug_simulate_premium_footer"))
                            .font(secondaryFont)
                            .modifier(SettingsFooterTextStyle())
                        #endif
                    }
                }
            }
            .navigationTitle(GameLocalizedStrings.string("settings"))
            .modifier(SettingsNavigationTitleStyle())
            .toolbar {
                ToolbarItem(placement: Self.doneToolbarPlacement) {
                    Button(GameLocalizedStrings.string("done")) {
                        dismiss()
                    }
                    .font(fontForLabels)
                }
            }
            .alert(GameLocalizedStrings.string("restore_purchases"), isPresented: $showingRestoreAlert) {
                Button(GameLocalizedStrings.string("ok"), role: .cancel) {}
            } message: {
                if let restoreMessage {
                    Text(restoreMessage)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(playLimitService: playLimitService)
                    .fontPreferenceStore(fontPreferenceStore)
            }
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
                    .modifier(SettingsNavigationTitleStyle())
                    .toolbar {
                        ToolbarItem(placement: Self.doneToolbarPlacement) {
                            Button(GameLocalizedStrings.string("done")) {
                                showingAudioCueTutorial = false
                            }
                            .font(fontForLabels)
                        }
                    }
                }
                .fontPreferenceStore(fontPreferenceStore)
            }
            #if os(macOS)
            .background {
                OfferCodeRedemptionHostView(controller: $offerCodeRedemptionHostController)
                    .frame(width: 0, height: 0)
            }
            #endif
        }
    }
    private static let volumeSteps: [Double] = stride(from: 0.0, through: 1.0, by: 0.05).map {
        Double((($0 * 100).rounded()) / 100)
    }

    private var volumeSelection: Binding<Double> {
        Binding(
            get: { Self.closestVolumeStep(to: preferencesStore.soundEffectsVolumeSelection.wrappedValue) },
            set: { preferencesStore.soundEffectsVolumeSelection.wrappedValue = $0 }
        )
    }

    private static func closestVolumeStep(to value: Double) -> Double {
        let step = 0.05
        let clamped = min(max(value, 0), 1)
        let rounded = (clamped / step).rounded() * step
        return Double(((rounded * 100).rounded()) / 100)
    }

    private var soundEffectsVolumeAccessibilityValue: String {
        let percent = Int64((Self.closestVolumeStep(
            to: preferencesStore.soundEffectsVolumeSelection.wrappedValue
        ) * 100).rounded())
        return GameLocalizedStrings.format("settings_percentage_value", percent)
    }

    private var debugAchievementPickerOptions: [AchievementIdentifier] {
        AchievementIdentifier.allCases.sorted { lhs, rhs in
            lhs.rawValue < rhs.rawValue
        }
    }

    @ViewBuilder
    private func inlineSectionFooterRow(text: String) -> some View {
        Text(text)
            .font(secondaryFont)
            .modifier(SettingsFooterTextStyle())
            .foregroundStyle(.secondary)
    }

    private static var doneToolbarPlacement: ToolbarItemPlacement {
        .confirmationAction
    }

    private static var eventDateDisplayCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .autoupdatingCurrent
        calendar.timeZone = eventDateDisplayTimeZone
        return calendar
    }

    private static var eventDateDisplayTimeZone: TimeZone {
        TimeZone(secondsFromGMT: 0) ?? .autoupdatingCurrent
    }

    private static func formattedEventEndDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = eventDateDisplayCalendar
        formatter.timeZone = eventDateDisplayTimeZone
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func eventSubtitle(for info: SpecialEventInfo) -> String {
        let endString = Self.formattedEventEndDate(info.inclusiveEndDate)
        return GameLocalizedStrings.format("event_play_unlimited_subtitle %@ %@", endString, info.name)
    }

    private func playLimitTitle(for service: PlayLimitService) -> String {
        if service.hasUnlimitedAccess {
            return GameLocalizedStrings.string("play_limit_unlimited")
        }

        let now = Date()
        let remaining = service.remainingPlays(on: now)
        let total = service.maxPlays(on: now)
        return GameLocalizedStrings.format("play_limit_remaining %lld %lld", Int64(remaining), Int64(total))
    }

    private func playLimitFooter(for service: PlayLimitService) -> String {
        let key = service.isFirstPlayDay(on: Date()) ? "play_limit_section_footer_first_day" : "play_limit_section_footer"
        return GameLocalizedStrings.string(key)
    }

    private func playLimitSubtitle(for service: PlayLimitService) -> String? {
        if service.hasUnlimitedAccess {
            return GameLocalizedStrings.string("play_limit_thank_you")
        }

        let now = Date()
        let resetDate = service.nextResetDate(after: now)
        let components = Calendar.current.dateComponents([.hour, .minute], from: now, to: resetDate)
        let rawHours = max(0, components.hour ?? 0)
        let hasRemainingMinutes = (components.minute ?? 0) > 0
        let hours = hasRemainingMinutes ? rawHours + 1 : rawHours

        if hours >= 24 {
            return GameLocalizedStrings.string("play_limit_resets_tomorrow")
        } else if hours == 1 {
            return GameLocalizedStrings.string("play_limit_resets_in_one_hour")
        } else {
            return GameLocalizedStrings.format("play_limit_resets_in_hours %lld", Int64(hours))
        }
    }

    @MainActor
    private func restorePurchases() async {
        isRestoringPurchases = true

        do {
            try await storeKit.restorePurchases()

            if storeKit.hasPremiumAccess {
                restoreMessage = GameLocalizedStrings.string("purchase_restored_success")
            } else {
                restoreMessage = GameLocalizedStrings.string("purchase_restored_none")
            }
            showingRestoreAlert = true
        } catch {
            restoreMessage = GameLocalizedStrings.format("purchase_restored_failed %@", error.localizedDescription)
            showingRestoreAlert = true
        }

        isRestoringPurchases = false
    }

    #if os(macOS)
    @MainActor
    private func redeemOfferCode() async {
        guard let offerCodeRedemptionHostController else {
            AppLog.error(
                AppLog.store + AppLog.lifecycle,
                "OFFER_CODE_REDEEM",
                outcome: .failed,
                fields: [.reason("host_controller_unavailable")]
            )
            return
        }

        isRedeemingOfferCode = true
        defer { isRedeemingOfferCode = false }

        do {
            try await AppStore.presentOfferCodeRedeemSheet(from: offerCodeRedemptionHostController)
            await storeKit.refreshPurchasedProducts()
        } catch {
            AppLog.error(
                AppLog.store + AppLog.lifecycle,
                "OFFER_CODE_REDEEM",
                outcome: .failed,
                fields: [.reason("redeem_sheet_failed")] + AppLog.Field.error(error)
            )
        }
    }
    #endif
}

#if os(iOS)
private struct SettingsNavigationTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationBarTitleDisplayMode(.inline)
    }
}
#else
private struct SettingsNavigationTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}
#endif

private struct SettingsFooterTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        #else
        content
        #endif
    }
}
#Preview {
    let previewTutorialPlayer = AudioCueTutorialPreviewPlayer(
        laneCuePlayer: PlatformFactories.makeLaneCuePlayer()
    )
    let previewSpeedWarningPlayer = SpeedIncreaseWarningFeedbackPlayer(
        announcementPoster: AccessibilityAnnouncementPoster(),
        hapticController: NoOpHapticFeedbackController(),
        playWarningSound: {
            previewTutorialPlayer.playSpeedWarningSound(
                volume: SoundEffectsVolumePreference.currentSelection(from: InfrastructureDefaults.userDefaults)
            )
        },
        announcementTextProvider: {
            GameLocalizedStrings.string("speed_increase_announcement")
        }
    )
    SettingsView(
        themeManager: ThemeManager(
            initialThemes: [LCDTheme(), PocketTheme()],
            defaultThemeID: "lcd",
            userDefaults: UserDefaults.standard
        ),
        fontPreferenceStore: FontPreferenceStore(
            userDefaults: UserDefaults.standard,
            customFontAvailable: true
        ),
        supportsHapticFeedback: true,
        hapticController: NoOpHapticFeedbackController(),
        audioCueTutorialPreviewPlayer: previewTutorialPlayer,
        speedWarningFeedbackPreviewPlayer: previewSpeedWarningPlayer,
        controlsDescriptionKey: "settings_controls_ios",
        style: .universal,
        achievementProgressService: LocalAchievementProgressService(
            store: UserDefaultsAchievementProgressStore(userDefaults: InfrastructureDefaults.userDefaults),
            highestScoreStore: UserDefaultsHighestScoreStore(userDefaults: InfrastructureDefaults.userDefaults),
            reporter: NoOpAchievementProgressReporter()
        ),
        playLimitService: nil
    )
}

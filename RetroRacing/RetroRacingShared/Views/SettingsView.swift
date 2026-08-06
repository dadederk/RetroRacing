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
    public let screenshotFocus: ScreenshotSettingsFocus?
    public let screenshotFriendOvertakeAnnouncementsEnabled: Bool?
    public let screenshotPresentedInSheet: Bool
    public let onScreenshotLayoutReady: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitService.self) private var storeKit
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @State private var preferencesStore: SettingsPreferencesStore
    @AppStorage(HapticFeedbackPreference.storageKey) private var hapticFeedbackEnabled: Bool = true
    @AppStorage(FriendOvertakeVoiceOverAnnouncementPreference.storageKey)
    private var friendOvertakeVoiceOverAnnouncementEnabled: Bool = FriendOvertakeVoiceOverAnnouncementPreference.defaultEnabled
    @AppStorage(DebugGameplayStorageKeys.forcedAchievementIdentifier)
    private var debugForcedAchievementIdentifierRawValue: String = DebugGameplayStorageKeys.noForcedAchievementIdentifier
    @AppStorage(DebugGameplayStorageKeys.showSpriteKitFrameStats) private var debugShowSpriteKitFrameStats: Bool = false
    @AppStorage(DebugGameplayStorageKeys.experimentalThirtyTwoBitThemeEnabled)
    private var debugExperimentalThirtyTwoBitThemeEnabled: Bool = false
    @AppStorage(DebugGameplayStorageKeys.experimentalSixtyFourBitThemeEnabled)
    private var debugExperimentalSixtyFourBitThemeEnabled: Bool = false
    @State private var isRestoringPurchases = false
    @State private var restoreMessage: String?
    @State private var showingRestoreAlert = false
    @State private var showingOfferCodeRedemption = false
    @State private var presentedSettingsSheet: PresentedSettingsSheet?
    @State private var selectedTVSettingsCategory: TVSettingsCategory = .speed
    @Namespace private var tvSettingsCategoryFocusScope
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
        specialEventService: SpecialEventService? = nil,
        screenshotFocus: ScreenshotSettingsFocus? = nil,
        screenshotFriendOvertakeAnnouncementsEnabled: Bool? = nil,
        screenshotPresentedInSheet: Bool = false,
        onScreenshotLayoutReady: (() -> Void)? = nil
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
        self.screenshotFocus = screenshotFocus
        self.screenshotFriendOvertakeAnnouncementsEnabled = screenshotFriendOvertakeAnnouncementsEnabled
        self.screenshotPresentedInSheet = screenshotPresentedInSheet
        self.onScreenshotLayoutReady = onScreenshotLayoutReady
        let initialPreferencesStore = SettingsPreferencesStore(
            userDefaults: InfrastructureDefaults.userDefaults,
            supportsHaptics: supportsHapticFeedback,
            isVoiceOverRunningProvider: {
                screenshotFocus == .accessibility ? true : VoiceOverStatus.isVoiceOverRunning
            }
        )
        if let screenshotFocus {
            initialPreferencesStore.applyScreenshotCapturePreset(focus: screenshotFocus)
        }
        _preferencesStore = State(initialValue: initialPreferencesStore)
    }
    private var fontForLabels: Font {
        fontPreferenceStore.font(textStyle: .body)
    }
    private var secondaryFont: Font {
        fontPreferenceStore.font(textStyle: .caption)
    }
    private var sectionHeaderFont: Font {
        fontPreferenceStore.font(textStyle: .headline)
    }
    private enum PresentedSettingsSheet: Hashable, Identifiable {
        case paywall
        case audioCueTutorial
        case controlsHelp

        var id: Self { self }
    }
    public var body: some View {
        settingsContent
            .modifier(
                ScreenshotSettingsPresentationModifier(
                    isActive: screenshotFocus != nil && screenshotPresentedInSheet == false
                )
            )
            .onAppear {
                preferencesStore.loadIfNeeded()
                if let screenshotFriendOvertakeAnnouncementsEnabled {
                    friendOvertakeVoiceOverAnnouncementEnabled = screenshotFriendOvertakeAnnouncementsEnabled
                }
            }
    }
    @ViewBuilder
    private var settingsContent: some View {
        if style.presentation == .modal {
            NavigationStack {
                settingsRoot
                    .toolbar {
                        ToolbarItem(placement: Self.doneToolbarPlacement) {
                            Button(GameLocalizedStrings.string("done")) {
                                dismiss()
                            }
                            .font(fontForLabels)
                        }
                    }
            }
        } else {
            settingsRoot
        }
    }

    private var settingsRoot: some View {
        settingsRootContent
            .navigationTitle(settingsNavigationTitle)
            .modifier(SettingsNavigationChromeModifier(screenshotFocus: screenshotFocus))
            .alert(GameLocalizedStrings.string("restore_purchases"), isPresented: $showingRestoreAlert) {
                Button(GameLocalizedStrings.string("ok"), role: .cancel) {}
            } message: {
                if let restoreMessage {
                    Text(restoreMessage)
                }
            }
            .sheet(item: $presentedSettingsSheet, onDismiss: {
                preferencesStore.reloadFromStorage()
            }) { sheet in
                sheetContent(for: sheet)
            }
            #if os(macOS)
            .background {
                OfferCodeRedemptionHostView(controller: $offerCodeRedemptionHostController)
                    .frame(width: 0, height: 0)
            }
            #endif
    }

    private var settingsNavigationTitle: String {
        if style.layout == .categories {
            selectedTVSettingsCategory.title
        } else {
            GameLocalizedStrings.string("settings")
        }
    }

    @ViewBuilder
    private var settingsRootContent: some View {
        if style.layout == .categories {
            tvSettingsCategoryTabs
        } else {
            sharedSettingsList
        }
    }

    private var sharedSettingsList: some View {
        ScrollViewReader { scrollProxy in
            List {
                playLimitSection
                topPurchasesSection
                themeSection
                fontSection
                speedSection
                soundSection
                vibrationSection
                controlsSection
                accessibilitySection
                aboutSection
                bottomPurchasesSection
                debugSection
            }
            .modifier(SettingsScreenshotListChromeModifier(screenshotFocus: screenshotFocus))
            .onAppear {
                scrollToScreenshotFocusIfNeeded(using: scrollProxy)
            }
        }
    }

    private var tvSettingsCategoryTabs: some View {
        TabView(selection: $selectedTVSettingsCategory) {
            ForEach(tvSettingsCategories) { category in
                Tab(value: category) {
                    tvSettingsPage(for: category)
                        .accessibilityIdentifier("tv_settings_category_content_\(category.rawValue)")
                } label: {
                    Label(category.title, systemImage: category.systemImage)
                        .accessibilityIdentifier("tv_settings_category_\(category.rawValue)")
                        #if os(tvOS)
                        .prefersDefaultFocus(category == .speed, in: tvSettingsCategoryFocusScope)
                        #endif
                }
            }
        }
        #if os(tvOS)
        .tabViewStyle(.tabBarOnly)
        .focusScope(tvSettingsCategoryFocusScope)
        #endif
    }

    private var tvSettingsCategories: [TVSettingsCategory] {
        TVSettingsCategory.visibleCategories(
            showsDebug: BuildConfiguration.shouldShowDebugFeatures
        )
    }

    private func tvSettingsPage(for category: TVSettingsCategory) -> some View {
        HStack(spacing: 64) {
            TVSettingsCategoryOverview(
                category: category,
                summary: tvSettingsSummary(for: category)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tvSettingsDestination(for: category)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 64)
        .padding(.bottom, 32)
    }

    private func tvSettingsSummary(for category: TVSettingsCategory) -> String {
        switch category {
        case .speed:
            GameLocalizedStrings.string(preferencesStore.selectedDifficulty.localizedNameKey)
        case .theme:
            themeManager.currentTheme.name
        case .sound:
            GameLocalizedStrings.format(
                "settings_percentage_value",
                Int64(preferencesStore.selectedSoundEffectsVolume * 100)
            )
        case .accessibility:
            GameLocalizedStrings.string(preferencesStore.selectedRoadVisualStyle.localizedNameKey)
        case .controls:
            GameLocalizedStrings.string(controlsDescriptionKey)
        case .purchases:
            GameLocalizedStrings.string(
                storeKit.hasPremiumAccessForGating
                    ? "play_limit_thank_you"
                    : "paywall_unlimited_and_themes"
            )
        case .about:
            GameLocalizedStrings.string("about_app_subtitle")
        case .debug:
            GameLocalizedStrings.string("debug_simulate_premium_footer")
        }
    }

    @ViewBuilder
    private func tvSettingsDestination(for category: TVSettingsCategory) -> some View {
        switch category {
        case .speed:
            TVSettingsCategoryDetailView {
                speedSection
            }
        case .theme:
            TVSettingsCategoryDetailView {
                tvThemeGallerySections
                fontSection
                tvAppearanceSection
            }
        case .sound:
            TVSettingsCategoryDetailView {
                soundSection
                tvSpeedWarningSection
            }
        case .accessibility:
            TVSettingsCategoryDetailView {
                tvAccessibilitySection
            }
        case .controls:
            SettingsControlsHelpSheet(
                controlsDescriptionKey: controlsDescriptionKey,
                controllerPreferencesStore: preferencesStore,
                presentation: .navigationDestination
            )
            .tvNavigationLinkPickerStyle()
        case .purchases:
            TVSettingsCategoryDetailView {
                playLimitSection
                purchasesSection
            }
        case .about:
            AboutView()
        case .debug:
            TVSettingsCategoryDetailView {
                debugSection
            }
        }
    }

    private var tvThemeGallerySections: some View {
        ThemeGallerySections(
            previewModels: themeManager.availableThemes.map {
                ThemeGalleryPreviewModel(
                    theme: $0,
                    isIncreaseContrastEnabled: colorSchemeContrast == .increased
                )
            },
            selectedThemeID: themeManager.currentTheme.id,
            showsUnlockSection: storeKit.shouldShowFreeTierAffordances,
            isSelectionDisabled: isGameSessionInProgress,
            sectionHeaderFont: sectionHeaderFont,
            bodyFont: fontForLabels,
            onUnlockRequest: { presentedSettingsSheet = .paywall },
            onPreviewSelection: selectTVTheme
        )
    }

    private func selectTVTheme(_ preview: ThemeGalleryPreviewModel) {
        guard let theme = themeManager.availableThemes.first(where: { $0.id == preview.id }) else {
            return
        }

        switch ThemeGallerySelectionPolicy.action(
            previewID: preview.id,
            currentThemeID: themeManager.currentTheme.id,
            isThemeAvailable: themeManager.isThemeAvailable(theme)
        ) {
        case .none:
            return
        case .selectTheme:
            themeManager.setTheme(theme)
        case .presentPaywall:
            presentedSettingsSheet = .paywall
        }
    }

    private func scrollToScreenshotFocusIfNeeded(using scrollProxy: ScrollViewProxy) {
        guard let screenshotFocus else { return }
        let targetID = screenshotScrollTargetID(for: screenshotFocus)
        DispatchQueue.main.async {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                scrollProxy.scrollTo(targetID, anchor: Self.screenshotSettingsScrollAnchor)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withTransaction(transaction) {
                    scrollProxy.scrollTo(targetID, anchor: Self.screenshotSettingsScrollAnchor)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                onScreenshotLayoutReady?()
            }
        }
    }

    @ViewBuilder
    private var topPurchasesSection: some View {
        if Self.shouldPlacePurchasesSectionAtBottom(
            hasPremiumAccessForGating: storeKit.hasPremiumAccessForGating
        ) == false {
            purchasesSection
        }
    }

    @ViewBuilder
    private var bottomPurchasesSection: some View {
        if Self.shouldPlacePurchasesSectionAtBottom(
            hasPremiumAccessForGating: storeKit.hasPremiumAccessForGating
        ) {
            purchasesSection
        }
    }

    static func shouldPlacePurchasesSectionAtBottom(hasPremiumAccessForGating: Bool) -> Bool {
        hasPremiumAccessForGating
    }

    @ViewBuilder
    private var playLimitSection: some View {
        if let playLimitService, storeKit.shouldShowFreeTierAffordances {
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
                settingsSectionHeader("play_limit_title")
            } footer: {
                if activeEventInfo == nil {
                    Text(playLimitFooter(for: playLimitService))
                        .font(secondaryFont)
                        .modifier(SettingsFooterTextStyle())
                }
            }
        }
    }

    private var purchasesSection: some View {
        Section {
            if storeKit.hasPremiumAccessForGating {
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

            if storeKit.shouldShowFreeTierAffordances {
                Button {
                    presentedSettingsSheet = .paywall
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
            if storeKit.shouldShowFreeTierAffordances {
                inlineSectionFooterRow(text: GameLocalizedStrings.string("settings_restore_footer"))
            }
            #endif
        } header: {
            settingsSectionHeader("settings_purchases_title")
        } footer: {
            #if os(macOS)
            EmptyView()
            #else
            if storeKit.shouldShowFreeTierAffordances {
                Text(GameLocalizedStrings.string("settings_restore_footer"))
                    .font(secondaryFont)
                    .modifier(SettingsFooterTextStyle())
            }
            #endif
        }
    }

    private var themeSection: some View {
        Section {
            if storeKit.hasPremiumAccessForGating {
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
                    Text(GameLocalizedStrings.string("settings_theme_style"))
                        .font(fontForLabels)
                }
                .disabled(isGameSessionInProgress)

                themeGalleryLink
            } else {
                NavigationLink {
                    themeGalleryView
                } label: {
                    HStack {
                        Text(GameLocalizedStrings.string("settings_theme_style"))
                            .font(fontForLabels)
                        Spacer()
                        Text(themeManager.currentTheme.name)
                            .font(fontForLabels)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel(Text(GameLocalizedStrings.string("settings_theme_style")))
                .accessibilityValue(Text(themeManager.currentTheme.name))
            }
        } header: {
            settingsSectionHeader("settings_theme")
                .id(ScreenshotCaptureIdentifiers.settingsThemeSection)
        } footer: {
            if !storeKit.hasPremiumAccessForGating {
                Text(GameLocalizedStrings.string("settings_theme_unlock_footnote"))
                    .font(secondaryFont)
                    .modifier(SettingsFooterTextStyle())
            }
        }
        .accessibilityIdentifier(ScreenshotCaptureIdentifiers.settingsThemeSection)
    }

    private var themeGalleryLink: some View {
        NavigationLink {
            themeGalleryView
        } label: {
            Text(GameLocalizedStrings.string("settings_theme_gallery_preview"))
                .font(fontForLabels)
        }
    }

    private var themeGalleryView: some View {
        ThemeGalleryView(themeManager: themeManager, playLimitService: playLimitService)
            .fontPreferenceStore(fontPreferenceStore)
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
            settingsSectionHeader("settings_speed")
        }
        .id(ScreenshotCaptureIdentifiers.settingsCustomizeSection)
        .accessibilityIdentifier(ScreenshotCaptureIdentifiers.settingsCustomizeSection)
    }

    private var soundSection: some View {
        Section {
            if style.layout == .categories {
                audioFeedbackModePicker
                if preferencesStore.shouldShowAudioCueTutorial {
                    laneMoveCueStylePicker
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    audioFeedbackModePicker
                    if preferencesStore.shouldShowAudioCueTutorial {
                        laneMoveCueStylePicker
                    }
                }
            }

            if preferencesStore.shouldShowAudioCueTutorial {
                if style.presentation == .navigationDestination {
                    NavigationLink {
                        SettingsAudioCueTutorialView(
                            previewPlayer: audioCueTutorialPreviewPlayer,
                            speedWarningFeedbackPreviewPlayer: speedWarningFeedbackPreviewPlayer,
                            supportsHapticFeedback: supportsHapticFeedback,
                            hapticController: hapticController,
                            presentation: .navigationDestination
                        )
                    } label: {
                        Text(GameLocalizedStrings.string("settings_audio_cue_tutorial"))
                            .font(fontForLabels)
                    }
                } else {
                    Button {
                        presentedSettingsSheet = .audioCueTutorial
                    } label: {
                        Text(GameLocalizedStrings.string("settings_audio_cue_tutorial"))
                            .font(fontForLabels)
                    }
                    .buttonStyle(.borderless)
                }
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
            settingsSectionHeader("settings_sound")
        }
    }

    private var audioFeedbackModePicker: some View {
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
    }

    private var laneMoveCueStylePicker: some View {
        Picker(selection: preferencesStore.laneMoveCueStyleSelection) {
            ForEach(preferencesStore.availableLaneMoveCueStyles, id: \.self) { cueStyle in
                Text(GameLocalizedStrings.string(cueStyle.localizedNameKey))
                    .font(fontForLabels)
                    .tag(cueStyle)
            }
        } label: {
            Text(GameLocalizedStrings.string("settings_lane_move_cue_style"))
                .font(fontForLabels)
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
            speedWarningRows
            appearanceRows
            assistiveTechnologyRows
        } header: {
            settingsSectionHeader("settings_accessibility")
                .id(ScreenshotCaptureIdentifiers.settingsAccessibilitySection)
        }
        .accessibilityIdentifier(ScreenshotCaptureIdentifiers.settingsAccessibilitySection)
    }

    private var tvAppearanceSection: some View {
        Section {
            appearanceRows
        }
    }

    private var tvSpeedWarningSection: some View {
        Section {
            speedWarningRows
        } header: {
            settingsSectionHeader("settings_speed_warning_feedback")
        }
    }

    private var tvAccessibilitySection: some View {
        Section {
            assistiveTechnologyRows
        }
    }

    @ViewBuilder
    private var speedWarningRows: some View {
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

    @ViewBuilder
    private var appearanceRows: some View {
        Picker(selection: preferencesStore.roadVisualStyleSelection) {
            ForEach(RoadVisualStyle.allCases, id: \.self) { roadStyle in
                Text(GameLocalizedStrings.string(roadStyle.localizedNameKey))
                    .font(fontForLabels)
                    .tag(roadStyle)
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
    }

    @ViewBuilder
    private var assistiveTechnologyRows: some View {
        #if !os(macOS)
        if style.showsDirectTouch {
            Toggle(isOn: preferencesStore.directTouchSelection) {
                Text(GameLocalizedStrings.string("settings_direct_touch"))
                    .font(fontForLabels)
            }
            .tint(.accentColor)
        }
        #endif

        Toggle(isOn: $friendOvertakeVoiceOverAnnouncementEnabled) {
            Text(GameLocalizedStrings.string("settings_voiceover_friend_overtake_announcements"))
                .font(fontForLabels)
        }
        .tint(.accentColor)
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label(GameLocalizedStrings.string("about_title"), systemImage: "info.circle")
                    .font(fontForLabels)
            }
        } header: {
            settingsSectionHeader("about_title")
        }
    }

    @ViewBuilder
    private var debugSection: some View {
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

                Toggle(isOn: $debugShowSpriteKitFrameStats) {
                    Text(GameLocalizedStrings.string("debug_show_spritekit_frame_stats"))
                        .font(fontForLabels)
                }
                .tint(.accentColor)

                if themeManager.catalogPlatform.showsExperimentalToggle(for: .thirtyTwoBit) {
                    Toggle(isOn: $debugExperimentalThirtyTwoBitThemeEnabled) {
                        Text(GameLocalizedStrings.string("debug_enable_experimental_thirty_two_bit_theme"))
                            .font(fontForLabels)
                    }
                    .tint(.accentColor)
                    .disabled(isGameSessionInProgress)
                    .onChange(of: debugExperimentalThirtyTwoBitThemeEnabled) {
                        applyExperimentalThemes()
                    }
                }

                if themeManager.catalogPlatform.showsExperimentalToggle(for: .sixtyFourBit) {
                    Toggle(isOn: $debugExperimentalSixtyFourBitThemeEnabled) {
                        Text(GameLocalizedStrings.string("debug_enable_experimental_sixty_four_bit_theme"))
                            .font(fontForLabels)
                    }
                    .tint(.accentColor)
                    .disabled(isGameSessionInProgress)
                    .onChange(of: debugExperimentalSixtyFourBitThemeEnabled) {
                        applyExperimentalThemes()
                    }
                }
            } header: {
                settingsSectionHeader("debug_section_title")
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

    private func applyExperimentalThemes() {
        themeManager.applyExperimentalThemes(ExperimentalThemeConfiguration(
            isThirtyTwoBitEnabled: debugExperimentalThirtyTwoBitThemeEnabled,
            isSixtyFourBitEnabled: debugExperimentalSixtyFourBitThemeEnabled
        ))
    }

    @ViewBuilder
    private func sheetContent(for sheet: PresentedSettingsSheet) -> some View {
        switch sheet {
        case .paywall:
            PaywallView(playLimitService: playLimitService)
                .fontPreferenceStore(fontPreferenceStore)
        case .audioCueTutorial:
            SettingsAudioCueTutorialView(
                previewPlayer: audioCueTutorialPreviewPlayer,
                speedWarningFeedbackPreviewPlayer: speedWarningFeedbackPreviewPlayer,
                supportsHapticFeedback: supportsHapticFeedback,
                hapticController: hapticController,
                presentation: .modal
            )
            .fontPreferenceStore(fontPreferenceStore)
        case .controlsHelp:
            SettingsControlsHelpSheet(
                controlsDescriptionKey: controlsDescriptionKey,
                controllerPreferencesStore: preferencesStore,
                presentation: .modal
            )
            .fontPreferenceStore(fontPreferenceStore)
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
    private func settingsSectionHeader(_ key: String) -> some View {
        Text(GameLocalizedStrings.string(key))
            .retroSectionHeader(font: sectionHeaderFont)
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
        let now = Date()
        if service.isFirstPlayDay(on: now) {
            let welcomeMax = Int64(service.maxPlays(on: now))
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
            let dailyMax = Int64(service.maxPlays(on: nextDay))
            return GameLocalizedStrings.format(
                "play_limit_section_footer_first_day %lld %lld",
                dailyMax,
                welcomeMax
            )
        }

        let dailyMax = Int64(service.maxPlays(on: now))
        return GameLocalizedStrings.format("play_limit_section_footer %lld", dailyMax)
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

    private func screenshotScrollTargetID(for focus: ScreenshotSettingsFocus) -> String {
        switch focus {
        case .accessibility:
            ScreenshotCaptureIdentifiers.settingsAccessibilitySection
        case .themeAndFont:
            ScreenshotCaptureIdentifiers.settingsThemeSection
        case .customize:
            ScreenshotCaptureIdentifiers.settingsCustomizeSection
        }
    }

    /// Keeps section headers visible below the inline navigation title during screenshot capture.
    private static let screenshotSettingsScrollAnchor = UnitPoint(x: 0.5, y: 0.12)
}

#if os(iOS)
private struct SettingsNavigationChromeModifier: ViewModifier {
    let screenshotFocus: ScreenshotSettingsFocus?

    func body(content: Content) -> some View {
        if screenshotFocus != nil {
            content
                .navigationBarTitleDisplayMode(
                    UIDevice.current.userInterfaceIdiom == .pad ? .large : .inline
                )
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color(uiColor: .systemGroupedBackground), for: .navigationBar)
        } else {
            content.navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct SettingsScreenshotListChromeModifier: ViewModifier {
    let screenshotFocus: ScreenshotSettingsFocus?

    func body(content: Content) -> some View {
        if screenshotFocus != nil {
            content.scrollEdgeEffectStyle(.hard, for: .top)
        } else {
            content
        }
    }
}
#else
private struct SettingsNavigationChromeModifier: ViewModifier {
    let screenshotFocus: ScreenshotSettingsFocus?

    func body(content: Content) -> some View {
        content
    }
}

private struct SettingsScreenshotListChromeModifier: ViewModifier {
    let screenshotFocus: ScreenshotSettingsFocus?

    func body(content: Content) -> some View {
        content
    }
}
#endif

#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
private struct ScreenshotSettingsPresentationModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        } else {
            content
        }
    }
}
#else
private struct ScreenshotSettingsPresentationModifier: ViewModifier {
    let isActive: Bool

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
            configuration: .iPhone,
            userDefaults: UserDefaults.standard,
            hasPremiumAccess: true
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

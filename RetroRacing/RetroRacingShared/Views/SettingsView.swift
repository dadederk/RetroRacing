//
//  SettingsView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
import StoreKit

/// Settings surface for themes, fonts, audio, optional haptics, purchases, debug, and About.
public struct SettingsView: View {
    public let themeManager: ThemeManager
    public let fontPreferenceStore: FontPreferenceStore
    /// Injected by app; when false, haptic feedback section is hidden (device has no haptics).
    public let supportsHapticFeedback: Bool
    public let controlsDescriptionKey: String
    public let style: SettingsViewStyle
    /// Injected for the About screen (rate button). Required so About is reachable from Settings.
    public let ratingService: RatingService
    /// Optional play limit service for showing remaining rounds.
    public let playLimitService: PlayLimitService?

    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitService.self) private var storeKit
    @AppStorage(HapticFeedbackPreference.storageKey) private var hapticFeedbackEnabled: Bool = true
    @AppStorage(SoundPreferences.volumeKey) private var sfxVolume: Double = SoundPreferences.defaultVolume
    @State private var isRestoringPurchases = false
    @State private var restoreMessage: String?
    @State private var showingRestoreAlert = false
    @State private var showingPaywall = false
    @State private var showingOfferCodeRedemption = false
    public init(
        themeManager: ThemeManager,
        fontPreferenceStore: FontPreferenceStore,
        supportsHapticFeedback: Bool,
        controlsDescriptionKey: String,
        style: SettingsViewStyle,
        ratingService: RatingService,
        playLimitService: PlayLimitService? = nil
    ) {
        self.themeManager = themeManager
        self.fontPreferenceStore = fontPreferenceStore
        self.supportsHapticFeedback = supportsHapticFeedback
        self.controlsDescriptionKey = controlsDescriptionKey
        self.style = style
        self.ratingService = ratingService
        self.playLimitService = playLimitService
    }
    private var fontForLabels: Font {
        fontPreferenceStore.font(size: style.labelFontSize)
    }
    public var body: some View {
        settingsContent
            #if os(macOS)
            .frame(minWidth: 420, minHeight: 380)
            #endif
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
                    } else {
                        HStack {
                            Text(GameLocalizedStrings.string("settings_theme"))
                                .font(fontForLabels)
                            Spacer()
                            Text(themeManager.currentTheme.name)
                                .font(fontForLabels)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(GameLocalizedStrings.string("settings_theme"))
                        .font(fontForLabels)
                }

                if let playLimitService, !storeKit.hasPremiumAccess {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(playLimitTitle(for: playLimitService))
                                .font(fontForLabels)
                            if let subtitle = playLimitSubtitle(for: playLimitService) {
                                Text(subtitle)
                                    .font(fontForLabels)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text(GameLocalizedStrings.string("play_limit_title"))
                            .font(fontForLabels)
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
                    Slider(value: $sfxVolume, in: 0...1, step: 0.05) {
                        Text(GameLocalizedStrings.string("settings_sound_effects_volume"))
                            .font(fontForLabels)
                    } minimumValueLabel: {
                        Text(GameLocalizedStrings.string("0%"))
                            .font(fontForLabels)
                    } maximumValueLabel: {
                        Text(GameLocalizedStrings.string("100%"))
                            .font(fontForLabels)
                    }
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
                    if storeKit.hasPremiumAccess {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(GameLocalizedStrings.string("settings_premium_active"))
                                    .font(fontForLabels)
                                Text(GameLocalizedStrings.string("product_unlimited_plays"))
                                    .font(fontPreferenceStore.font(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
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
                            }
                        }
                        .disabled(isRestoringPurchases)
                    }
                } header: {
                    Text(GameLocalizedStrings.string("settings_purchases_title"))
                        .font(fontForLabels)
                } footer: {
                    if !storeKit.hasPremiumAccess {
                        Text(GameLocalizedStrings.string("settings_restore_footer"))
                            .font(fontPreferenceStore.font(size: 12))
                    }
                }

                if BuildConfiguration.shouldShowDebugFeatures {
                    Section {
                        Toggle(
                            GameLocalizedStrings.string("debug_simulate_premium"),
                            isOn: Binding(
                                get: { storeKit.debugPremiumEnabled },
                                set: { storeKit.debugPremiumEnabled = $0 }
                            )
                        )
                        .tint(.accentColor)
                    } header: {
                        Text(GameLocalizedStrings.string("debug_section_title"))
                            .font(fontForLabels)
                    } footer: {
                        Text(GameLocalizedStrings.string("debug_simulate_premium_footer"))
                            .font(fontPreferenceStore.font(size: 12))
                    }
                }

                Section {
                    NavigationLink {
                        AboutView(ratingService: ratingService)
                    } label: {
                        Label(GameLocalizedStrings.string("about_title"), systemImage: "info.circle")
                            .font(fontForLabels)
                    }
                }
            }
            .navigationTitle(GameLocalizedStrings.string("settings"))
            .modifier(SettingsNavigationTitleStyle())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(GameLocalizedStrings.string("done")) {
                        dismiss()
                    }
                    .font(fontForLabels)
                }
            }
            .alert(GameLocalizedStrings.string("restore_purchases"), isPresented: $showingRestoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if let restoreMessage {
                    Text(restoreMessage)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(playLimitService: playLimitService)
                    .fontPreferenceStore(fontPreferenceStore)
            }
        }
    }
    private static let volumeSteps: [Double] = stride(from: 0.0, through: 1.0, by: 0.05).map {
        Double((($0 * 100).rounded()) / 100)
    }
    private var volumeSelection: Binding<Double> {
        Binding(
            get: { Self.closestVolumeStep(to: sfxVolume) },
            set: { sfxVolume = $0 }
        )
    }

    private static func closestVolumeStep(to value: Double) -> Double {
        let step = 0.05
        let clamped = min(max(value, 0), 1)
        let rounded = (clamped / step).rounded() * step
        return Double(((rounded * 100).rounded()) / 100)
    }

    private func playLimitTitle(for service: PlayLimitService) -> String {
        if service.hasUnlimitedAccess {
            return GameLocalizedStrings.string("play_limit_unlimited")
        }

        let remaining = service.remainingPlays(on: Date())
        return GameLocalizedStrings.format("play_limit_remaining %lld", Int64(remaining))
    }

    private func playLimitSubtitle(for service: PlayLimitService) -> String? {
        if service.hasUnlimitedAccess {
            return GameLocalizedStrings.string("play_limit_thank_you")
        }

        let now = Date()
        let resetDate = service.nextResetDate(after: now)
        let components = Calendar.current.dateComponents([.hour], from: now, to: resetDate)
        let hours = max(0, components.hour ?? 0)

        if hours >= 24 {
            return GameLocalizedStrings.string("play_limit_resets_tomorrow")
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
#Preview {
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
        controlsDescriptionKey: "settings_controls_ios",
        style: .universal,
        ratingService: PreviewRatingServiceForSettings(),
        playLimitService: nil
    )
}

private final class PreviewRatingServiceForSettings: RatingService {
    func requestRating() {}
    func checkAndRequestRating(score: Int) {}
}

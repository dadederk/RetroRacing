import SwiftUI
import RetroRacingShared

struct SettingsView: View {
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    /// Injected by app; watchOS has Taptic Engine, so true.
    let supportsHapticFeedback: Bool
    @Environment(\.dismiss) private var dismiss
    @AppStorage(HapticFeedbackPreference.storageKey) private var hapticFeedbackEnabled: Bool = true
    @AppStorage(SoundPreferences.volumeKey) private var sfxVolume: Double = SoundPreferences.defaultVolume

    private var fontForLabels: Font {
        fontPreferenceStore.font(size: 10)
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
                    Slider(value: $sfxVolume, in: 0...1, step: 0.05) {
                        Text(GameLocalizedStrings.string("settings_sound_effects_volume"))
                            .font(fontForLabels)
                    } minimumValueLabel: {
                        Text("0%").font(fontForLabels)
                    } maximumValueLabel: {
                        Text("100%").font(fontForLabels)
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
                    }
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
        }
    }
}

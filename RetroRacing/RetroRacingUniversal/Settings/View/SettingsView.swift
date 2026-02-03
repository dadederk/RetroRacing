import SwiftUI
import RetroRacingShared

struct SettingsView: View {
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    /// Injected by app; when false, haptic feedback section is hidden (device has no haptics).
    let supportsHapticFeedback: Bool
    @Environment(\.dismiss) private var dismiss
    @AppStorage(HapticFeedbackPreference.storageKey) private var hapticFeedbackEnabled: Bool = true

    private var fontForLabels: Font {
        fontPreferenceStore.font(size: 14)
    }

    private var controlsDescriptionKey: String {
        #if os(macOS)
        return "settings_controls_macos"
        #else
        return "settings_controls_ios"
        #endif
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
                    Text(GameLocalizedStrings.string(controlsDescriptionKey))
                        .font(fontForLabels)
                } header: {
                    Text(GameLocalizedStrings.string("settings_controls"))
                        .font(fontForLabels)
                }

                if supportsHapticFeedback {
                    Section {
                        Toggle(isOn: $hapticFeedbackEnabled) {
                            Text(GameLocalizedStrings.string("settings_haptic_feedback"))
                                .font(fontForLabels)
                        }
                    } header: {
                        Text(GameLocalizedStrings.string("settings_vibration"))
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
        }
    }
}

#if !os(macOS)
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
        themeManager: ThemeManager(initialThemes: [LCDTheme(), GameBoyTheme()]),
        fontPreferenceStore: FontPreferenceStore(),
        supportsHapticFeedback: true
    )
}

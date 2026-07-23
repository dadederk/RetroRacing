//
//  ControlsHelpContentView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 19/02/2026.
//

import SwiftUI

/// Reusable controls explanation block used in Settings and in-game help.
public struct ControlsHelpContentView: View {
    public let controlsDescriptionKey: String
    /// When false, only the description text is shown (e.g. when a parent provides a section header).
    public let showTitle: Bool
    /// When true, the title and body are exposed as one accessibility element.
    public let combinesAccessibilityChildren: Bool
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    public init(
        controlsDescriptionKey: String,
        showTitle: Bool = true,
        combinesAccessibilityChildren: Bool = true
    ) {
        self.controlsDescriptionKey = controlsDescriptionKey
        self.showTitle = showTitle
        self.combinesAccessibilityChildren = combinesAccessibilityChildren
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showTitle {
                Text(GameLocalizedStrings.string("settings_controls"))
                    .retroSectionHeader(font: fontPreferenceStore?.font(textStyle: .headline) ?? .headline)
            }

            Text(GameLocalizedStrings.string(controlsDescriptionKey))
                .font(fontPreferenceStore?.font(textStyle: .body) ?? .body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ControlsHelpAccessibilityGrouping(enabled: combinesAccessibilityChildren))
    }
}

private struct ControlsHelpAccessibilityGrouping: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.accessibilityElement(children: .combine)
        } else {
            content
        }
    }
}

/// Settings help sheet for platform controls and optional controller remapping.
public struct SettingsControlsHelpSheet: View {
    public let controlsDescriptionKey: String
    public let controllerPreferencesStore: SettingsPreferencesStore?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    public init(
        controlsDescriptionKey: String,
        controllerPreferencesStore: SettingsPreferencesStore? = nil
    ) {
        self.controlsDescriptionKey = controlsDescriptionKey
        self.controllerPreferencesStore = controllerPreferencesStore
    }

    private var sectionHeaderFont: Font {
        fontPreferenceStore?.font(textStyle: .headline) ?? .headline
    }

    private var primaryFont: Font {
        fontPreferenceStore?.font(textStyle: .body) ?? .body
    }

    private var secondaryFont: Font {
        fontPreferenceStore?.font(textStyle: .caption) ?? .caption
    }

    public var body: some View {
        NavigationStack {
            Group {
                #if os(macOS)
                scrollContent
                #else
                listContent
                #endif
            }
            .navigationTitle(GameLocalizedStrings.string("settings_controls_how_to_play"))
            .modifier(SettingsControlsHelpNavigationTitleStyle())
            .toolbar {
                ToolbarItem(placement: Self.doneToolbarPlacement) {
                    Button(GameLocalizedStrings.string("done")) {
                        dismiss()
                    }
                    .font(primaryFont)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 380)
        #endif
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                controlsHelpSection

                if let controllerPreferencesStore {
                    SettingsControllerMappingContent(
                        preferencesStore: controllerPreferencesStore,
                        primaryFont: primaryFont,
                        secondaryFont: secondaryFont,
                        sectionHeaderFont: sectionHeaderFont
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

#if !os(macOS)
    private var listContent: some View {
        List {
            Section {
                ControlsHelpContentView(
                    controlsDescriptionKey: controlsDescriptionKey,
                    showTitle: false,
                    combinesAccessibilityChildren: false
                )
            } header: {
                Text(GameLocalizedStrings.string("settings_controls"))
                    .retroSectionHeader(font: sectionHeaderFont)
            }

            if let controllerPreferencesStore {
                SettingsControllerMappingSection(
                    preferencesStore: controllerPreferencesStore,
                    primaryFont: primaryFont,
                    secondaryFont: secondaryFont,
                    sectionHeaderFont: sectionHeaderFont
                )
            }
        }
    }
#endif

    private var controlsHelpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(GameLocalizedStrings.string("settings_controls"))
                .retroSectionHeader(font: sectionHeaderFont)

            ControlsHelpContentView(
                controlsDescriptionKey: controlsDescriptionKey,
                showTitle: false,
                combinesAccessibilityChildren: false
            )
        }
    }

    private static var doneToolbarPlacement: ToolbarItemPlacement {
        .confirmationAction
    }
}

#if !os(macOS)
private struct SettingsControllerMappingSection: View {
    let preferencesStore: SettingsPreferencesStore
    let primaryFont: Font
    let secondaryFont: Font
    let sectionHeaderFont: Font

    var body: some View {
        Section {
            SettingsControllerMappingPickers(
                preferencesStore: preferencesStore,
                primaryFont: primaryFont
            )
        } header: {
            Text(GameLocalizedStrings.string("settings_controller"))
                .retroSectionHeader(font: sectionHeaderFont)
        } footer: {
            controllerFootnote
        }
    }

    private var controllerFootnote: some View {
        Text(GameLocalizedStrings.string("settings_controller_footnote"))
            .font(secondaryFont)
            .foregroundStyle(.secondary)
    }
}
#endif

private struct SettingsControllerMappingContent: View {
    let preferencesStore: SettingsPreferencesStore
    let primaryFont: Font
    let secondaryFont: Font
    let sectionHeaderFont: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(GameLocalizedStrings.string("settings_controller"))
                .retroSectionHeader(font: sectionHeaderFont)

            SettingsControllerMappingPickers(
                preferencesStore: preferencesStore,
                primaryFont: primaryFont
            )

            Text(GameLocalizedStrings.string("settings_controller_footnote"))
                .font(secondaryFont)
                .foregroundStyle(.secondary)
                .modifier(SettingsControlsFooterTextStyle())
        }
    }
}

private struct SettingsControllerMappingPickers: View {
    let preferencesStore: SettingsPreferencesStore
    let primaryFont: Font

    var body: some View {
        Picker(selection: preferencesStore.controllerLeftButtonSelection) {
            controllerButtonOptions
        } label: {
            Text(GameLocalizedStrings.string("settings_controller_move_left"))
                .font(primaryFont)
        }

        Picker(selection: preferencesStore.controllerRightButtonSelection) {
            controllerButtonOptions
        } label: {
            Text(GameLocalizedStrings.string("settings_controller_move_right"))
                .font(primaryFont)
        }

        Picker(selection: preferencesStore.controllerPauseButtonSelection) {
            controllerButtonOptions
        } label: {
            Text(GameLocalizedStrings.string("settings_controller_pause_resume"))
                .font(primaryFont)
        }
    }

    private var controllerButtonOptions: some View {
        ForEach(GameControllerRemapButton.allCases, id: \.self) { button in
            Text(GameLocalizedStrings.string(button.localizedNameKey))
                .font(primaryFont)
                .tag(button)
        }
    }
}

#if os(iOS) || os(watchOS)
private struct SettingsControlsHelpNavigationTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.navigationBarTitleDisplayMode(.inline)
    }
}
#else
private struct SettingsControlsHelpNavigationTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}
#endif

private struct SettingsControlsFooterTextStyle: ViewModifier {
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

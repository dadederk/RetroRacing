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
                    .retroSectionHeader()
            }

            Text(GameLocalizedStrings.string(controlsDescriptionKey))
                .appFont(.body)
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
    public let presentation: NavigationSurfacePresentation

    @Environment(\.dismiss) private var dismiss

    public init(
        controlsDescriptionKey: String,
        controllerPreferencesStore: SettingsPreferencesStore? = nil,
        presentation: NavigationSurfacePresentation = .modal
    ) {
        self.controlsDescriptionKey = controlsDescriptionKey
        self.controllerPreferencesStore = controllerPreferencesStore
        self.presentation = presentation
    }

    public var body: some View {
        presentationContent
        #if os(macOS)
            .frame(minWidth: 420, minHeight: 380)
        #endif
    }

    @ViewBuilder
    private var presentationContent: some View {
        if presentation == .modal {
            NavigationStack {
                helpContent
                    .toolbar {
                        ToolbarItem(placement: Self.doneToolbarPlacement) {
                            Button(GameLocalizedStrings.string("done")) {
                                dismiss()
                            }
                            .appFont(.body)
                        }
                    }
            }
        } else {
            helpContent
        }
    }

    private var helpContent: some View {
        Group {
            #if os(macOS)
            scrollContent
            #else
            listContent
            #endif
        }
        .navigationTitle(GameLocalizedStrings.string("settings_controls_how_to_play"))
        .modifier(SettingsControlsHelpNavigationTitleStyle())
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                controlsHelpSection

                if let controllerPreferencesStore {
                    SettingsControllerMappingContent(
                        preferencesStore: controllerPreferencesStore
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
                    .retroSectionHeader()
            }

            if let controllerPreferencesStore {
                SettingsControllerMappingSection(
                    preferencesStore: controllerPreferencesStore
                )
            }
        }
    }
#endif

    private var controlsHelpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(GameLocalizedStrings.string("settings_controls"))
                .retroSectionHeader()

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

    var body: some View {
        Section {
            SettingsControllerMappingPickers(
                preferencesStore: preferencesStore
            )
        } header: {
            Text(GameLocalizedStrings.string("settings_controller"))
                .retroSectionHeader()
        } footer: {
            controllerFootnote
        }
    }

    private var controllerFootnote: some View {
        Text(GameLocalizedStrings.string(Self.controllerFootnoteKey))
            .appFont(.caption)
            .foregroundStyle(.secondary)
    }

    private static var controllerFootnoteKey: String {
        #if os(tvOS)
        "settings_controller_footnote_tvos"
        #else
        "settings_controller_footnote"
        #endif
    }
}
#endif

private struct SettingsControllerMappingContent: View {
    let preferencesStore: SettingsPreferencesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(GameLocalizedStrings.string("settings_controller"))
                .retroSectionHeader()

            SettingsControllerMappingPickers(
                preferencesStore: preferencesStore
            )

            Text(GameLocalizedStrings.string(Self.controllerFootnoteKey))
                .appFont(.caption)
                .foregroundStyle(.secondary)
                .modifier(SettingsControlsFooterTextStyle())
        }
    }

    private static var controllerFootnoteKey: String {
        #if os(tvOS)
        "settings_controller_footnote_tvos"
        #else
        "settings_controller_footnote"
        #endif
    }
}

private struct SettingsControllerMappingPickers: View {
    let preferencesStore: SettingsPreferencesStore

    var body: some View {
        Picker(selection: controllerButtonSelection(for: .moveLeft)) {
            controllerButtonOptions(for: .moveLeft)
        } label: {
            Text(GameLocalizedStrings.string("settings_controller_move_left"))
                .appFont(.body)
        }

        Picker(selection: controllerButtonSelection(for: .moveRight)) {
            controllerButtonOptions(for: .moveRight)
        } label: {
            Text(GameLocalizedStrings.string("settings_controller_move_right"))
                .appFont(.body)
        }

        Picker(selection: controllerButtonSelection(for: .pauseResume)) {
            controllerButtonOptions(for: .pauseResume)
        } label: {
            Text(GameLocalizedStrings.string("settings_controller_pause_resume"))
                .appFont(.body)
        }
    }

    private func controllerButtonOptions(for action: GameControllerRemapAction) -> some View {
        ForEach(controllerButtons(for: action), id: \.self) { button in
            Text(GameLocalizedStrings.string(button.localizedNameKey))
                .appFont(.body)
                .tag(button)
        }
    }

    private func controllerButtons(for action: GameControllerRemapAction) -> [GameControllerRemapButton] {
        #if os(tvOS)
        GameControllerBindingOptionPolicy.tvOSAdditiveButtons(for: action)
        #else
        GameControllerRemapButton.allCases
        #endif
    }

    private func controllerButtonSelection(
        for action: GameControllerRemapAction
    ) -> Binding<GameControllerRemapButton> {
        #if os(tvOS)
        Binding(
            get: {
                button(
                    for: action,
                    in: GameControllerBindingOptionPolicy.tvOSCompatibleProfile(
                        from: preferencesStore.selectedControllerBindingProfile
                    )
                )
            },
            set: { newButton in
                let profile = GameControllerBindingOptionPolicy.tvOSCompatibleProfile(
                    from: preferencesStore.selectedControllerBindingProfile
                )
                preferencesStore.setControllerBindingProfile(
                    profile.setting(newButton, for: action)
                )
            }
        )
        #else
        switch action {
        case .moveLeft:
            preferencesStore.controllerLeftButtonSelection
        case .moveRight:
            preferencesStore.controllerRightButtonSelection
        case .pauseResume:
            preferencesStore.controllerPauseButtonSelection
        }
        #endif
    }

    private func button(
        for action: GameControllerRemapAction,
        in profile: GameControllerBindingProfile
    ) -> GameControllerRemapButton {
        switch action {
        case .moveLeft:
            profile.leftButton
        case .moveRight:
            profile.rightButton
        case .pauseResume:
            profile.pauseButton
        }
    }
}

private extension GameControllerBindingProfile {
    func setting(
        _ button: GameControllerRemapButton,
        for action: GameControllerRemapAction
    ) -> GameControllerBindingProfile {
        switch action {
        case .moveLeft:
            settingLeft(button)
        case .moveRight:
            settingRight(button)
        case .pauseResume:
            settingPause(button)
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

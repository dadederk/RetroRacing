//
//  TVSettingsCategory.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 06/08/2026.
//

import SwiftUI

enum TVSettingsCategory: String, CaseIterable, Identifiable {
    case game
    case theme
    case sound
    case accessibility
    case controls
    case purchases
    case about
    case debug

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .game:
            "settings_game"
        case .theme:
            "settings_theme"
        case .sound:
            "settings_sound"
        case .accessibility:
            "settings_accessibility"
        case .controls:
            "settings_controls"
        case .purchases:
            "settings_purchases_title"
        case .about:
            "about_title"
        case .debug:
            "debug_section_title"
        }
    }

    var title: String {
        GameLocalizedStrings.string(titleKey)
    }

    var systemImage: String {
        switch self {
        case .game:
            "gearshape"
        case .theme:
            "paintpalette"
        case .sound:
            "speaker.wave.2"
        case .accessibility:
            "accessibility"
        case .controls:
            "gamecontroller"
        case .purchases:
            "cart"
        case .about:
            "info.circle"
        case .debug:
            "hammer"
        }
    }

    static func visibleCategories(
        showsDebug: Bool,
        isScreenshotCapture: Bool = false
    ) -> [TVSettingsCategory] {
        let includesDebug = showsDebug && isScreenshotCapture == false
        return allCases.filter { category in
            category != .debug || includesDebug
        }
    }
}

struct TVSettingsCategoryDetailView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        List {
            content
        }
        .tvNavigationLinkPickerStyle()
        .tvFocusSafeSettingsList()
    }
}

struct GameDifficultySelectionButton: View {
    @Binding private var selection: GameDifficulty
    let difficulty: GameDifficulty
    let isDisabled: Bool

    init(
        selection: Binding<GameDifficulty>,
        difficulty: GameDifficulty,
        isDisabled: Bool
    ) {
        _selection = selection
        self.difficulty = difficulty
        self.isDisabled = isDisabled
    }

    var body: some View {
        Button {
            selection = difficulty
        } label: {
            HStack(spacing: 16) {
                Image(systemName: difficulty.gaugeSystemImageName)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text(GameLocalizedStrings.string(difficulty.localizedNameKey))
                    .appFont(.body)
                    .foregroundStyle(.primary)

                Spacer(minLength: 16)

                if selection == difficulty {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .tvSettingsCardContentPadding()
            .contentShape(Rectangle())
        }
        .modifier(TVSettingsSelectionButtonStyleModifier())
        .tvFocusSafeSettingsRow()
        .disabled(isDisabled)
        .accessibilityAddTraits(selection == difficulty ? .isSelected : [])
        .accessibilityIdentifier("settings_speed_option_\(difficulty.rawValue)")
    }
}

private struct TVSettingsSelectionButtonStyleModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(tvOS)
        content.buttonStyle(.card)
        #else
        content.buttonStyle(.plain)
        #endif
    }
}

extension View {
    @ViewBuilder
    func tvNavigationLinkPickerStyle() -> some View {
        #if os(tvOS)
        pickerStyle(.navigationLink)
        #else
        self
        #endif
    }

    @ViewBuilder
    func tvFocusSafeSettingsList() -> some View {
        #if os(tvOS)
        contentMargins(.horizontal, 56, for: .scrollContent)
            .contentMargins(.vertical, 40, for: .scrollContent)
            .scrollClipDisabled()
        #else
        self
        #endif
    }

    @ViewBuilder
    func tvSettingsCardContentPadding() -> some View {
        #if os(tvOS)
        padding(.horizontal, 24)
            .padding(.vertical, 18)
        #else
        self
        #endif
    }

    @ViewBuilder
    func tvFocusSafeSettingsRow() -> some View {
        #if os(tvOS)
        listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            .listRowBackground(Color.clear)
        #else
        self
        #endif
    }
}

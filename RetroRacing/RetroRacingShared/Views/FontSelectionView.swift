//
//  FontSelectionView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import SwiftUI

/// Shared font preference UI used by every platform settings surface.
public struct FontSelectionView: View {
    private let fontPreferenceStore: FontPreferenceStore

    public init(fontPreferenceStore: FontPreferenceStore) {
        self.fontPreferenceStore = fontPreferenceStore
    }

    public var body: some View {
        List {
            ForEach(AppFontStyle.allCases) { style in
                FontSelectionRow(
                    style: style,
                    selectedStyle: fontPreferenceStore.currentStyle,
                    availability: fontPreferenceStore.availability
                ) {
                    fontPreferenceStore.currentStyle = style
                }
            }

            if fontPreferenceStore.currentStyle != fontPreferenceStore.effectiveStyle {
                Text(GameLocalizedStrings.string("font_selection_system_fallback"))
                    .appFont(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("font_selection_fallback_message")
            }
        }
        .navigationTitle(GameLocalizedStrings.string("settings_font"))
        .fontPreferenceStore(fontPreferenceStore)
        .accessibilityIdentifier("font_selection_list")
    }
}

private struct FontSelectionRow: View {
    let style: AppFontStyle
    let selectedStyle: AppFontStyle
    let availability: AppFontAvailability
    let select: () -> Void

    private var isSelected: Bool { style == selectedStyle }
    private var isAvailable: Bool { availability.isAvailable(style) }
    private var previewTypography: AppTypography {
        AppTypography(selectedStyle: style, availability: availability)
    }

    var body: some View {
        Button(action: select) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.localizedName)
                        .appFont(.body)
                        .appTypography(previewTypography)
                        .foregroundStyle(isAvailable ? .primary : .secondary)
                        .multilineTextAlignment(.leading)

                    if !isAvailable {
                        Text(GameLocalizedStrings.string("font_selection_unavailable"))
                            .appFont(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(accessibilityValue)
        .accessibilityIdentifier("font_selection_\(style.rawValue)")
    }

    private var accessibilityValue: String {
        if !isAvailable && isSelected {
            return GameLocalizedStrings.string("font_selection_selected_unavailable_value")
        }
        if !isAvailable {
            return GameLocalizedStrings.string("font_selection_unavailable")
        }
        return isSelected
            ? GameLocalizedStrings.string("font_selection_selected")
            : ""
    }
}

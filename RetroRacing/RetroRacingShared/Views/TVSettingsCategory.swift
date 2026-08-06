//
//  TVSettingsCategory.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 06/08/2026.
//

import SwiftUI

enum TVSettingsCategory: String, CaseIterable, Identifiable {
    case speed
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
        case .speed:
            "settings_speed"
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
        case .speed:
            "speedometer"
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

    static func visibleCategories(showsDebug: Bool) -> [TVSettingsCategory] {
        allCases.filter { category in
            category != .debug || showsDebug
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
    }
}

struct TVSettingsCategoryOverview: View {
    let category: TVSettingsCategory
    let summary: String

    @ScaledMetric(relativeTo: .title) private var iconContainerSize: CGFloat = 250
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 92

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: category.systemImage)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: iconContainerSize, height: iconContainerSize)
                .background(.secondary.opacity(0.16), in: .rect(cornerRadius: 44))
                .accessibilityHidden(true)

            Text(category.title)
                .font(.title)
                .multilineTextAlignment(.center)

            Text(summary)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 560)
        .accessibilityElement(children: .combine)
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
}

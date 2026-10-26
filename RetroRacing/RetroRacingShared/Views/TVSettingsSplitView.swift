//
//  TVSettingsSplitView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-10-26.
//

import SwiftUI

struct TVSettingsSplitView<Detail: View>: View {
    let categories: [TVSettingsCategory]
    @Binding private var selectedCategory: TVSettingsCategory
    let isScreenshotCapture: Bool
    let focusScope: Namespace.ID
    let onScreenshotLayoutReady: (() -> Void)?
    @ViewBuilder let detail: Detail

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var sidebarIconColumnWidth: CGFloat = 52

    init(
        categories: [TVSettingsCategory],
        selectedCategory: Binding<TVSettingsCategory>,
        isScreenshotCapture: Bool,
        focusScope: Namespace.ID,
        onScreenshotLayoutReady: (() -> Void)?,
        @ViewBuilder detail: () -> Detail
    ) {
        self.categories = categories
        _selectedCategory = selectedCategory
        self.isScreenshotCapture = isScreenshotCapture
        self.focusScope = focusScope
        self.onScreenshotLayoutReady = onScreenshotLayoutReady
        self.detail = detail()
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detailColumn
        }
        #if os(tvOS)
        .focusScope(focusScope)
        #endif
        .onAppear {
            guard isScreenshotCapture else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                onScreenshotLayoutReady?()
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(GameLocalizedStrings.string("settings"))
                .appFont(.title2)
                .lineLimit(2)
                .padding(.horizontal, 48)
                .padding(.top, 40)
                .accessibilityAddTraits(.isHeader)

            List(categories) { category in
                TVSettingsSidebarRow(
                    category: category,
                    selectedCategory: $selectedCategory,
                    iconColumnWidth: sidebarIconColumnWidth,
                    isFocusDisabled: isScreenshotCapture,
                    focusScope: focusScope
                )
            }
            .listStyle(.plain)
            .scrollClipDisabled()
        }
        .frame(width: sidebarWidth)
        .background(.regularMaterial)
        .accessibilityIdentifier("tv_settings_sidebar")
        #if os(tvOS)
        .focusSection()
        #endif
    }

    private var detailColumn: some View {
        VStack(spacing: 0) {
            Text(selectedCategory.title)
                .appFont(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 56)
                .padding(.top, 40)
                .padding(.bottom, 18)
                .accessibilityAddTraits(.isHeader)

            detail
                .accessibilityIdentifier(
                    "tv_settings_category_content_\(selectedCategory.rawValue)"
                )
        }
        #if os(tvOS)
        .focusSection()
        #endif
    }

    private var sidebarWidth: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 820 : 560
    }
}

private struct TVSettingsSidebarRow: View {
    let category: TVSettingsCategory
    @Binding var selectedCategory: TVSettingsCategory
    let iconColumnWidth: CGFloat
    let isFocusDisabled: Bool
    let focusScope: Namespace.ID

    var body: some View {
        Button {
            selectedCategory = category
        } label: {
            HStack(spacing: 16) {
                Image(systemName: category.systemImage)
                    .font(.body)
                    .frame(width: iconColumnWidth)
                    .accessibilityHidden(true)

                Text(category.title)
                    .appFont(.body)
                    .lineLimit(2)
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.28) : Color.clear)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .modifier(TVSettingsSidebarButtonStyleModifier())
        .listRowInsets(EdgeInsets(top: 8, leading: 32, bottom: 8, trailing: 32))
        .listRowBackground(Color.clear)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("tv_settings_category_\(category.rawValue)")
        .modifier(TVSettingsScreenshotFocusModifier(hidesFocusEffect: isFocusDisabled))
        #if os(tvOS)
        .prefersDefaultFocus(isSelected && !isFocusDisabled, in: focusScope)
        #endif
    }

    private var isSelected: Bool {
        category == selectedCategory
    }
}

private struct TVSettingsScreenshotFocusModifier: ViewModifier {
    let hidesFocusEffect: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(tvOS)
        if hidesFocusEffect {
            content
                .focusable(false)
                .focusEffectDisabled()
        } else {
            content
        }
        #else
        content
        #endif
    }
}

private struct TVSettingsSidebarButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(tvOS)
        content.buttonStyle(.card)
        #else
        content.buttonStyle(.plain)
        #endif
    }
}

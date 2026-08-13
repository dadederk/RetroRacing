//
//  FontPreferenceStore+Environment.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 10/02/2026.
//

import SwiftUI

public extension EnvironmentValues {
    /// Preference persistence is exposed only to surfaces that edit the selection.
    @Entry var fontPreferenceStore: FontPreferenceStore? = nil

    /// Presentation-only typography value used by shared and platform views.
    @Entry var appTypography = AppTypography.system
}

private struct AppFontModifier: ViewModifier {
    let textStyle: Font.TextStyle
    let weightTier: AppFontWeightTier?

    @Environment(\.appTypography) private var typography
    @Environment(\.legibilityWeight) private var legibilityWeight

    func body(content: Content) -> some View {
        content.font(
            AppFontResolver.font(
                for: textStyle,
                typography: typography,
                legibilityWeight: legibilityWeight,
                requestedWeightTier: weightTier
            )
        )
    }
}

private struct ScaledAppFontModifier: ViewModifier {
    let scaledSize: CGFloat
    let textStyle: Font.TextStyle
    let weightTier: AppFontWeightTier?

    @Environment(\.appTypography) private var typography
    @Environment(\.legibilityWeight) private var legibilityWeight

    func body(content: Content) -> some View {
        content.font(
            AppFontResolver.font(
                scaledSize: scaledSize,
                relativeTo: textStyle,
                typography: typography,
                legibilityWeight: legibilityWeight,
                requestedWeightTier: weightTier
            )
        )
    }
}

public extension View {
    /// Injects both preference editing and presentation values for descendants.
    func fontPreferenceStore(_ store: FontPreferenceStore?) -> some View {
        environment(\.fontPreferenceStore, store)
            .environment(\.appTypography, store?.typography ?? .system)
    }

    /// Injects typography without exposing preference persistence.
    func appTypography(_ typography: AppTypography) -> some View {
        environment(\.appTypography, typography)
    }

    /// Applies the selected font family using a semantic Dynamic Type text style.
    func appFont(
        _ textStyle: Font.TextStyle,
        weightTier: AppFontWeightTier? = nil
    ) -> some View {
        modifier(AppFontModifier(textStyle: textStyle, weightTier: weightTier))
    }

    /// Applies an already Dynamic-Type-scaled point size, used by oversized game text.
    func appFont(
        scaledSize: CGFloat,
        relativeTo textStyle: Font.TextStyle,
        weightTier: AppFontWeightTier? = nil
    ) -> some View {
        modifier(
            ScaledAppFontModifier(
                scaledSize: scaledSize,
                textStyle: textStyle,
                weightTier: weightTier
            )
        )
    }
}

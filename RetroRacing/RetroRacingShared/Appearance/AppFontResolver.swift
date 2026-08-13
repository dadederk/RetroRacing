//
//  AppFontResolver.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import SwiftUI

public enum AppFontResolver {
    public static func font(
        for textStyle: Font.TextStyle,
        typography: AppTypography,
        legibilityWeight: LegibilityWeight? = nil,
        requestedWeightTier: AppFontWeightTier? = nil
    ) -> Font {
        let style = typography.effectiveStyle
        guard style.availableFaces.isEmpty == false else {
            return systemFont(
                for: textStyle,
                design: style.systemDesign,
                requestedWeightTier: requestedWeightTier
            )
        }

        guard let face = resolvedFace(
            for: style,
            textStyle: textStyle,
            availability: typography.availability,
            legibilityWeight: legibilityWeight,
            requestedWeightTier: requestedWeightTier
        ) else {
            return systemFont(for: textStyle, design: .default, requestedWeightTier: requestedWeightTier)
        }

        return .custom(
            face.postScriptName,
            size: AppFontPlatformSupport.defaultPointSize(for: textStyle),
            relativeTo: textStyle
        )
    }

    public static func font(
        scaledSize: CGFloat,
        relativeTo textStyle: Font.TextStyle,
        typography: AppTypography,
        legibilityWeight: LegibilityWeight? = nil,
        requestedWeightTier: AppFontWeightTier? = nil
    ) -> Font {
        let style = typography.effectiveStyle
        guard style.availableFaces.isEmpty == false else {
            let weightTier = requestedWeightTier ?? (legibilityWeight == .bold ? .bold : .regular)
            return .system(size: scaledSize, weight: weightTier.systemWeight, design: style.systemDesign)
        }

        guard let face = resolvedFace(
            for: style,
            textStyle: textStyle,
            availability: typography.availability,
            legibilityWeight: legibilityWeight,
            requestedWeightTier: requestedWeightTier
        ) else {
            let weightTier = requestedWeightTier ?? (legibilityWeight == .bold ? .bold : .regular)
            return .system(size: scaledSize, weight: weightTier.systemWeight)
        }

        return .custom(face.postScriptName, fixedSize: scaledSize)
    }

    static func resolvedFace(
        for style: AppFontStyle,
        textStyle: Font.TextStyle,
        availability: AppFontAvailability,
        legibilityWeight: LegibilityWeight?,
        requestedWeightTier: AppFontWeightTier? = nil
    ) -> AppFontFace? {
        let desiredWeight = requestedWeightTier ?? semanticWeight(for: textStyle)
        guard let baseFace = style.fallbackFace(for: desiredWeight, availability: availability) else {
            return nil
        }

        guard legibilityWeight == .bold else { return baseFace }
        return style.nextBolderFace(after: baseFace, availability: availability) ?? baseFace
    }

    static func basePointSize(for textStyle: Font.TextStyle) -> CGFloat {
        AppFontPlatformSupport.defaultPointSize(for: textStyle)
    }

    private static func semanticWeight(for textStyle: Font.TextStyle) -> AppFontWeightTier {
        textStyle == .headline ? .semibold : .regular
    }

    private static func systemFont(
        for textStyle: Font.TextStyle,
        design: Font.Design,
        requestedWeightTier: AppFontWeightTier?
    ) -> Font {
        guard let requestedWeightTier else {
            return .system(textStyle, design: design)
        }
        return .system(textStyle, design: design, weight: requestedWeightTier.systemWeight)
    }
}

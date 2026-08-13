//
//  AppFontStyle.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import SwiftUI

/// Coarse weight tiers shared by system and bundled font families.
public enum AppFontWeightTier: Int, Comparable, Sendable {
    case regular = 0
    case semibold = 2
    case bold = 3
    case heavy = 4

    public static func < (lhs: AppFontWeightTier, rhs: AppFontWeightTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var systemWeight: Font.Weight {
        switch self {
        case .regular: .regular
        case .semibold: .semibold
        case .bold: .bold
        case .heavy: .heavy
        }
    }
}

/// One bundled font resource and its PostScript identity.
public struct AppFontFace: Hashable, Sendable {
    public let fileName: String
    public let postScriptName: String
    public let weightTier: AppFontWeightTier

    public init(fileName: String, postScriptName: String, weightTier: AppFontWeightTier) {
        self.fileName = fileName
        self.postScriptName = postScriptName
        self.weightTier = weightTier
    }
}

/// User-selectable font style persisted in UserDefaults for consistent typography.
public enum AppFontStyle: String, CaseIterable, Identifiable, Sendable {
    /// Press Start 2P. The legacy raw value is intentionally retained for preference compatibility.
    case custom = "custom"
    case system = "system"
    case systemMonospaced = "systemMonospaced"
    case openDyslexic = "openDyslexic"
    case atkinsonHyperlegible = "atkinsonHyperlegible"
    case lexend = "lexend"

    public static let storageKey = "selectedFontStyle"

    public var id: String { rawValue }

    public var localizedName: String {
        GameLocalizedStrings.string(localizedNameKey)
    }

    public var localizedNameKey: String {
        switch self {
        case .custom: "about_font_press_start"
        case .system: "font_style_system"
        case .systemMonospaced: "font_style_system_monospaced"
        case .openDyslexic: "font_style_open_dyslexic"
        case .atkinsonHyperlegible: "font_style_atkinson_hyperlegible"
        case .lexend: "font_style_lexend"
        }
    }

    public var availableFaces: [AppFontFace] {
        switch self {
        case .custom:
            [
                AppFontFace(
                    fileName: "PressStart2P-Regular.ttf",
                    postScriptName: "PressStart2P-Regular",
                    weightTier: .regular
                )
            ]
        case .system, .systemMonospaced:
            []
        case .openDyslexic:
            [
                AppFontFace(
                    fileName: "OpenDyslexic-Regular.otf",
                    postScriptName: "OpenDyslexic-Regular",
                    weightTier: .regular
                ),
                AppFontFace(
                    fileName: "OpenDyslexic-Bold.otf",
                    postScriptName: "OpenDyslexic-Bold",
                    weightTier: .bold
                )
            ]
        case .atkinsonHyperlegible:
            [
                AppFontFace(
                    fileName: "AtkinsonHyperlegibleNext-Regular.otf",
                    postScriptName: "AtkinsonHyperlegibleNext-Regular",
                    weightTier: .regular
                ),
                AppFontFace(
                    fileName: "AtkinsonHyperlegibleNext-Bold.otf",
                    postScriptName: "AtkinsonHyperlegibleNext-Bold",
                    weightTier: .bold
                ),
                AppFontFace(
                    fileName: "AtkinsonHyperlegibleNext-ExtraBold.otf",
                    postScriptName: "AtkinsonHyperlegibleNext-ExtraBold",
                    weightTier: .heavy
                )
            ]
        case .lexend:
            [
                AppFontFace(
                    fileName: "Lexend-Regular.ttf",
                    postScriptName: "Lexend-Regular",
                    weightTier: .regular
                ),
                AppFontFace(
                    fileName: "Lexend-Bold.ttf",
                    postScriptName: "Lexend-Bold",
                    weightTier: .bold
                ),
                AppFontFace(
                    fileName: "Lexend-ExtraBold.ttf",
                    postScriptName: "Lexend-ExtraBold",
                    weightTier: .heavy
                )
            ]
        }
    }

    var systemDesign: Font.Design {
        self == .systemMonospaced ? .monospaced : .default
    }

    func availableFaces(in availability: AppFontAvailability) -> [AppFontFace] {
        availableFaces.filter { availability.contains($0.postScriptName) }
    }

    func fallbackFace(
        for requestedWeight: AppFontWeightTier,
        availability: AppFontAvailability
    ) -> AppFontFace? {
        let faces = availableFaces(in: availability).sorted { $0.weightTier < $1.weightTier }
        guard faces.isEmpty == false else { return nil }

        return faces.min { lhs, rhs in
            let lhsDistance = abs(lhs.weightTier.rawValue - requestedWeight.rawValue)
            let rhsDistance = abs(rhs.weightTier.rawValue - requestedWeight.rawValue)
            if lhsDistance == rhsDistance {
                return lhs.weightTier > rhs.weightTier
            }
            return lhsDistance < rhsDistance
        }
    }

    func nextBolderFace(
        after face: AppFontFace,
        availability: AppFontAvailability
    ) -> AppFontFace? {
        let faces = availableFaces(in: availability).sorted { $0.weightTier < $1.weightTier }
        return faces.first(where: { $0.weightTier > face.weightTier })
    }
}

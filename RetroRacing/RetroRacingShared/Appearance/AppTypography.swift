//
//  AppTypography.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import Foundation

/// Snapshot of the font faces available to the current process.
public struct AppFontAvailability: Equatable, Sendable {
    public let availablePostScriptNames: Set<String>

    public init(availablePostScriptNames: Set<String>) {
        self.availablePostScriptNames = availablePostScriptNames
    }

    public static let systemOnly = AppFontAvailability(availablePostScriptNames: [])

    public func contains(_ postScriptName: String) -> Bool {
        availablePostScriptNames.contains(postScriptName)
    }

    public func isAvailable(_ style: AppFontStyle) -> Bool {
        style.availableFaces.isEmpty || style.availableFaces.contains { contains($0.postScriptName) }
    }
}

/// Presentation value injected into SwiftUI independently from preference persistence.
public struct AppTypography: Equatable, Sendable {
    public let selectedStyle: AppFontStyle
    public let availability: AppFontAvailability

    public init(selectedStyle: AppFontStyle, availability: AppFontAvailability) {
        self.selectedStyle = selectedStyle
        self.availability = availability
    }

    public static let system = AppTypography(selectedStyle: .system, availability: .systemOnly)

    public var effectiveStyle: AppFontStyle {
        availability.isAvailable(selectedStyle) ? selectedStyle : .system
    }
}

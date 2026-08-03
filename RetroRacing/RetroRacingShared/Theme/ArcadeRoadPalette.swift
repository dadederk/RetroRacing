//
//  ArcadeRoadPalette.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/08/2026.
//

import SwiftUI

enum ArcadeRoadPalette {
    static let surface = Color(red: 136 / 255, green: 141 / 255, blue: 149 / 255)
    static let line = Color(red: 255 / 255, green: 255 / 255, blue: 0 / 255)
    static let highContrastLine = Color(red: 255 / 255, green: 255 / 255, blue: 102 / 255)
    static let lapMarker = Color(red: 255 / 255, green: 248 / 255, blue: 232 / 255)
    static let highContrastLapMarker = Color.white

    static func line(isIncreaseContrastEnabled: Bool) -> Color {
        isIncreaseContrastEnabled ? highContrastLine : line
    }

    static func lapMarker(isIncreaseContrastEnabled: Bool) -> Color {
        isIncreaseContrastEnabled ? highContrastLapMarker : lapMarker
    }
}

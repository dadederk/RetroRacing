//
//  PlatformButtonStyle.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-03-28.
//

import SwiftUI

extension View {
    @ViewBuilder
    func retroRacingPrimaryButtonStyle() -> some View {
        #if os(visionOS)
        buttonStyle(.borderedProminent)
        #else
        buttonStyle(.glassProminent)
        #endif
    }

    @ViewBuilder
    func retroRacingSecondaryButtonStyle() -> some View {
        #if os(visionOS)
        buttonStyle(.bordered)
        #else
        buttonStyle(.glass)
        #endif
    }
}

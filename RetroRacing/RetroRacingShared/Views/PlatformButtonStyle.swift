//
//  PlatformButtonStyle.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-03-28.
//

import SwiftUI

extension View {
    @ViewBuilder
    public func retroRacingPrimaryButtonStyle() -> some View {
        #if os(tvOS) || os(visionOS)
        buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Color.accentColor)
        #else
        buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .tint(Color.accentColor)
        #endif
    }

    @ViewBuilder
    public func retroRacingSecondaryButtonStyle() -> some View {
        #if os(visionOS)
        buttonStyle(.bordered)
        #else
        buttonStyle(.glass)
            .buttonBorderShape(.capsule)
        #endif
    }
}

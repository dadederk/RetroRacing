//
//  RetroSectionHeaderStyle.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import SwiftUI

/// Shared styling for list and form section headings across Settings, About, and paywall sections.
public struct RetroSectionHeaderStyle: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .appFont(.headline)
            .foregroundStyle(.primary)
    }
}

public extension View {
    func retroSectionHeader() -> some View {
        modifier(RetroSectionHeaderStyle())
    }
}

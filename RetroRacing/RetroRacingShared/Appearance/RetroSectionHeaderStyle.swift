//
//  RetroSectionHeaderStyle.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import SwiftUI

/// Shared styling for list and form section headings across Settings, About, and paywall sections.
public struct RetroSectionHeaderStyle: ViewModifier {
    let font: Font

    public init(font: Font) {
        self.font = font
    }

    public func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(.primary)
    }
}

public extension View {
    func retroSectionHeader(font: Font) -> some View {
        modifier(RetroSectionHeaderStyle(font: font))
    }
}

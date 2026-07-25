//
//  SettingsSheetStyleModifier.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 24/07/2026.
//

import SwiftUI

/// Consistent sheet presentation sizing for settings (matches game-over prominence).
public struct SettingsSheetStyleModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        #if os(macOS)
        content
            .frame(minWidth: 520, minHeight: 640)
        #elseif os(iOS)
        content
            .presentationDetents([.large])
        #else
        content
        #endif
    }
}

extension View {
    public func settingsSheetStyle() -> some View {
        modifier(SettingsSheetStyleModifier())
    }
}

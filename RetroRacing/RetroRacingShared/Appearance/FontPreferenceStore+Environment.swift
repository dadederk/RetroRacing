//
//  FontPreferenceStore+Environment.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 10/02/2026.
//

import SwiftUI

// MARK: - Environment Key

private struct FontPreferenceStoreKey: EnvironmentKey {
    static let defaultValue: FontPreferenceStore? = nil
}

extension EnvironmentValues {
    /// Access the current `FontPreferenceStore` from the environment.
    /// Returns `nil` if not provided; views should fall back to system fonts.
    public var fontPreferenceStore: FontPreferenceStore? {
        get { self[FontPreferenceStoreKey.self] }
        set { self[FontPreferenceStoreKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Injects a `FontPreferenceStore` into the environment for descendant views.
    public func fontPreferenceStore(_ store: FontPreferenceStore?) -> some View {
        environment(\.fontPreferenceStore, store)
    }
}

// MARK: - Helper for Semantic Font Sizes

extension FontPreferenceStore {
    /// Returns a font for caption text (small supplementary text).
    public var captionFont: Font {
        font(textStyle: .caption)
    }
    
    /// Returns a font for caption2 text (extra small supplementary text).
    public var caption2Font: Font {
        font(textStyle: .caption2)
    }
    
    /// Returns a font for subheadline text.
    public var subheadlineFont: Font {
        font(textStyle: .subheadline)
    }
    
    /// Returns a font for headline text.
    public var headlineFont: Font {
        font(textStyle: .headline)
    }
    
    /// Returns a font for body text.
    public var bodyFont: Font {
        font(textStyle: .body)
    }
    
    /// Returns a font for title text.
    public var titleFont: Font {
        font(textStyle: .title)
    }
}

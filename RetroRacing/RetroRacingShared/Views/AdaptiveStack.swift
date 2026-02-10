//
//  AdaptiveStack.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 10/02/2026.
//

import SwiftUI

/// A layout container that adapts between horizontal and vertical arrangements
/// based on the current Dynamic Type size.
///
/// - Regular sizes: Uses `HStack` with standard spacing.
/// - Accessibility sizes: Uses `VStack` with tighter spacing to avoid truncation.
public struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4, content: content)
        } else {
            HStack(alignment: .center, spacing: 12, content: content)
        }
    }
}


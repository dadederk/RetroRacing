//
//  BottomActionBar.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 06/04/2026.
//

import SwiftUI

extension View {
    /// Whether this platform renders action buttons in a floating bottom bar
    /// rather than inline with the scroll content.
    var usesBottomActionBar: Bool {
        #if os(iOS) || os(visionOS)
        true
        #else
        false
        #endif
    }

    /// Renders the view at full opacity and enables interaction when `isVisible` is
    /// true; hides it from layout, hit-testing, and accessibility otherwise while
    /// reserving its space in the layout so sibling views do not shift.
    func conditionallyVisible(_ isVisible: Bool) -> some View {
        self
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(isVisible)
            .accessibilityHidden(!isVisible)
            .disabled(!isVisible)
    }
}

#if os(iOS) || os(visionOS)

/// Floating glass action bar placed via `.safeAreaInset(edge: .bottom)`.
///
/// Modifier order follows the Xarra `FloatingPanel` pattern:
/// content → clip/glass → padding → ignoresSafeArea.
/// The padding insets the glass shape from the screen edges, and
/// `ignoresSafeArea` extends the view into the home-indicator zone so
/// `ConcentricRectangle` can resolve concentric corners against the display.
struct BottomActionBar<Content: View>: View {
    @ViewBuilder let content: () -> Content

    private let edgePadding: CGFloat = 8
    private let contentHorizontalPadding: CGFloat = 20
    private let contentTopPadding: CGFloat = 20
    private let contentBottomPadding: CGFloat = 20

    var body: some View {
        let shape = ConcentricRectangle(corners: .concentric, isUniform: true)

        content()
            .controlSize(.large)
            .padding(.horizontal, contentHorizontalPadding)
            .padding(.top, contentTopPadding)
            .padding(.bottom, contentBottomPadding)
            .frame(maxWidth: .infinity)
            .contentShape(shape)
            .clipShape(shape)
            #if os(iOS)
            .glassEffect(in: shape)
            #elseif os(visionOS)
            .background(.ultraThinMaterial, in: shape)
            #endif
            .padding(edgePadding)
            .ignoresSafeArea(edges: .bottom)
    }
}

#endif

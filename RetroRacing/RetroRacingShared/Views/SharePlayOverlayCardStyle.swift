//
//  SharePlayOverlayCardStyle.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import SwiftUI
#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
import UIKit
#endif

/// Glass or opaque card chrome for SharePlay overlay status cards.
struct SharePlayOverlayCardStyle: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        if reduceTransparency {
            content
                .background(opaqueBackgroundColor, in: shape)
                .overlay {
                    shape.stroke(.secondary.opacity(0.25), lineWidth: 1)
                }
        } else {
            #if os(iOS)
            if #available(iOS 26.0, *) {
                content
                    .glassEffect(.regular, in: shape)
                    .overlay {
                        shape.stroke(.white.opacity(0.18), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.16), radius: 18, y: 8)
            } else {
                content
                    .background(.ultraThinMaterial, in: shape)
                    .overlay {
                        shape.stroke(.white.opacity(0.22), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.16), radius: 14, y: 6)
            }
            #else
            content
                .background(.regularMaterial, in: shape)
                .overlay {
                    shape.stroke(.secondary.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
            #endif
        }
    }

    private var opaqueBackgroundColor: Color {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        Color(uiColor: .secondarySystemBackground)
        #else
        Color.secondary.opacity(0.15)
        #endif
    }
}

extension View {
    func sharePlayOverlayCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(SharePlayOverlayCardStyle(cornerRadius: cornerRadius))
    }
}

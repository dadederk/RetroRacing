//
//  GameInputOverlay.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI

struct GameInputOverlay: View {
    let onLeftTap: () -> Void
    let onRightTap: () -> Void
    let onDrag: (CGSize) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Color.clear
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    onLeftTap()
                }
                .accessibilityLabel(GameLocalizedStrings.string("move_left"))
                .accessibilityHint(GameLocalizedStrings.string("move_left_hint"))
                .accessibilityAddTraits(.isButton)
                #if os(iOS)
                .accessibilityDirectTouch(true, options: [.silentOnTouch])
                #endif
            Color.clear
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    onRightTap()
                }
                .accessibilityLabel(GameLocalizedStrings.string("move_right"))
                .accessibilityHint(GameLocalizedStrings.string("move_right_hint"))
                .accessibilityAddTraits(.isButton)
                #if os(iOS)
                .accessibilityDirectTouch(true, options: [.silentOnTouch])
                #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if !os(tvOS)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    guard value.translation.width != 0 else { return }
                    onDrag(value.translation)
                }
        )
        #endif
    }
}

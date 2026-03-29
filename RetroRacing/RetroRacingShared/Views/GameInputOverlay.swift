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
    let isInputEnabled: Bool
    let isAccessibilityEnabled: Bool
    let isDirectTouchEnabled: Bool

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
                .accessibilityInputLabels([
                    GameLocalizedStrings.string("tutorial_audio_lane_left"),
                    GameLocalizedStrings.string("move_left")
                ])
                .accessibilityAddTraits(.isButton)
                .accessibilityHidden(!isAccessibilityEnabled)
                .accessibilityDirectTouch(isDirectTouchEnabled, options: [.silentOnTouch])
            Color.clear
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    onRightTap()
                }
                .accessibilityLabel(GameLocalizedStrings.string("move_right"))
                .accessibilityHint(GameLocalizedStrings.string("move_right_hint"))
                .accessibilityInputLabels([
                    GameLocalizedStrings.string("tutorial_audio_lane_right"),
                    GameLocalizedStrings.string("move_right")
                ])
                .accessibilityAddTraits(.isButton)
                .accessibilityHidden(!isAccessibilityEnabled)
                .accessibilityDirectTouch(isDirectTouchEnabled, options: [.silentOnTouch])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(isInputEnabled)
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

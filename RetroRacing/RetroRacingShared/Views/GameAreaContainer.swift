//
//  GameAreaContainer.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/08/2026.
//

import SwiftUI

struct GameAreaContainer<Content: View>: View {
    let controls: GameControlInput
    let lifecycle: GameAreaLifecycleCallbacks
    let content: (CGFloat) -> Content

    #if os(macOS) || os(iOS)
    @FocusState private var isFocused: Bool
    #endif

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            content(side)
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(GameAreaKeyboardModifier(
                    inputAdapter: controls.inputAdapter,
                    onMoveLeft: controls.onMoveLeft,
                    onMoveRight: controls.onMoveRight,
                    onKeyboardInput: controls.onKeyboardInput,
                    onSwipeInput: controls.onSwipeInput,
                    onTogglePause: controls.onTogglePause
                ))
                .onAppear {
                    setFocusForGameArea()
                    lifecycle.onAppearSide(side)
                }
                .onChange(of: geometry.size) { _, newSize in
                    let side = min(newSize.width, newSize.height)
                    lifecycle.onAppearSide(side)
                    lifecycle.onResizeSide(side)
                }
        }
        .aspectRatio(1, contentMode: .fit)
        #if os(macOS) || os(iOS)
        .focusable()
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            AppLog.debug(
                AppLog.input + AppLog.game,
                "GAME_AREA_FOCUS_CHANGED",
                outcome: .completed,
                fields: [.bool("isFocused", newValue)]
            )
        }
        #endif
    }

    #if os(macOS) || os(iOS)
    private func setFocusForGameArea() {
        AppLog.debug(
            AppLog.input + AppLog.game,
            "GAME_AREA_FOCUS_SET",
            outcome: .requested
        )
        isFocused = true
    }
    #else
    private func setFocusForGameArea() { }
    #endif
}

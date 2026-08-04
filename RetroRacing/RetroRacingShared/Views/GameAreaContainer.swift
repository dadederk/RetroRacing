//
//  GameAreaContainer.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/08/2026.
//

import SwiftUI

struct GameAreaContainer<Content: View>: View {
    let layoutConfiguration: GameAreaLayoutConfiguration
    let controls: GameControlInput
    let lifecycle: GameAreaLifecycleCallbacks
    let content: (CGFloat) -> Content

    #if os(macOS) || os(iOS)
    @FocusState private var isFocused: Bool
    #endif

    var body: some View {
        measuredContainer
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

    private var measuredContainer: some View {
        GeometryReader { geometry in
            let side = layoutConfiguration.side(for: geometry.size)
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
                    let side = layoutConfiguration.side(for: newSize)
                    lifecycle.onAppearSide(side)
                    lifecycle.onResizeSide(side)
                }
        }
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

struct GameAreaLayoutConfiguration: Equatable {
    static let compactLandscapeExpandedEdgePadding: CGFloat = 8

    static let standard = GameAreaLayoutConfiguration(
        edgePadding: 0,
        topSafeAreaInset: 0
    )

    let edgePadding: CGFloat
    let topSafeAreaInset: CGFloat

    var reappliesTopSafeArea: Bool {
        edgePadding > 0
    }

    static func resolve(
        policy: GameLayoutPolicy,
        topSafeAreaInset: CGFloat
    ) -> GameAreaLayoutConfiguration {
        guard policy.expandsGameAreaIntoTopSafeArea else { return .standard }
        return GameAreaLayoutConfiguration(
            edgePadding: compactLandscapeExpandedEdgePadding,
            topSafeAreaInset: max(0, topSafeAreaInset)
        )
    }

    func side(for availableSize: CGSize) -> CGFloat {
        let availableWidth = max(0, availableSize.width)
        let availableHeight = max(0, availableSize.height)
        let rawSide = min(availableWidth, availableHeight)
        guard reappliesTopSafeArea else { return rawSide }

        let paddedExpandedSide = max(0, rawSide - edgePadding * 2)
        let unexpandedHeight = max(0, availableHeight - topSafeAreaInset)
        let unexpandedSide = min(availableWidth, unexpandedHeight)
        return max(paddedExpandedSide, unexpandedSide)
    }
}

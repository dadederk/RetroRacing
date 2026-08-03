//
//  GameLayoutView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI

struct GameLayoutView<GameArea: View>: View {
    let containerSize: CGSize
    let hud: GameHUDInput
    let controls: GameControlInput
    let lifecycle: GameAreaLifecycleCallbacks
    @ViewBuilder let gameArea: (CGFloat) -> GameArea

    #if os(macOS) || os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if usesCompactLandscapeLayout {
                CompactLandscapeGameLayout(
                    hud: hud,
                    controls: controls,
                    gameArea: gameAreaContainer
                )
            } else if usesRegularWidthWidePlayLayout {
                RegularWidthGameLayout(
                    hud: hud,
                    controls: controls,
                    gameArea: gameAreaContainer
                )
            } else {
                PortraitGameLayout(
                    hud: hud,
                    controls: controls,
                    centersPlayArea: shouldVerticallyCenterPortraitPlayArea,
                    gameArea: gameAreaContainer
                )
            }
            if hud.showsSpeedAlert {
                GameSpeedAlertView(
                    input: hud,
                    usesCompactLandscapeLayout: usesCompactLandscapeLayout
                )
            }
        }
    }

    private var gameAreaContainer: some View {
        GameAreaContainer(
            controls: controls,
            lifecycle: lifecycle,
            content: gameArea
        )
    }

    private var usesCompactLandscapeLayout: Bool {
        #if os(macOS) || os(iOS)
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.regular, .compact):
            true
        case (.regular, _), (.compact, _):
            false
        default:
            containerSize.width > containerSize.height
        }
        #else
        containerSize.width > containerSize.height
        #endif
    }

    private var usesRegularWidthWidePlayLayout: Bool {
        #if os(macOS) || os(iOS)
        horizontalSizeClass == .regular && containerSize.width > containerSize.height
        #else
        false
        #endif
    }

    private var shouldVerticallyCenterPortraitPlayArea: Bool {
        #if os(macOS) || os(iOS)
        horizontalSizeClass == .regular && usesRegularWidthWidePlayLayout == false
        #else
        false
        #endif
    }
}

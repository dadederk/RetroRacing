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
            let resolvedLayoutKind = layoutKind
            switch resolvedLayoutKind {
            case .compactLandscape:
                CompactLandscapeGameLayout(
                    hud: hud,
                    controls: controls,
                    gameArea: gameAreaContainer
                )
            case .regularWidthWidePlay:
                RegularWidthGameLayout(
                    hud: hud,
                    controls: controls,
                    gameArea: gameAreaContainer
                )
            case .portrait, .portraitCentered:
                PortraitGameLayout(
                    hud: hud,
                    controls: controls,
                    centersPlayArea: resolvedLayoutKind == .portraitCentered,
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

    private var layoutKind: GameLayoutKind {
        #if os(macOS) || os(iOS)
        GameLayoutKind.resolve(
            containerSize: containerSize,
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
        #else
        GameLayoutKind.resolve(
            containerSize: containerSize,
            horizontalSizeClass: nil,
            verticalSizeClass: nil
        )
        #endif
    }

    private var usesCompactLandscapeLayout: Bool {
        layoutKind == .compactLandscape
    }
}

enum GameLayoutKind: Equatable {
    case compactLandscape
    case regularWidthWidePlay
    case portrait
    case portraitCentered

    static func resolve(
        containerSize: CGSize,
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> GameLayoutKind {
        let isWide = containerSize.width > containerSize.height
        guard isWide else {
            return horizontalSizeClass == .regular ? .portraitCentered : .portrait
        }

        if verticalSizeClass == .compact {
            return .compactLandscape
        }
        if horizontalSizeClass == .regular {
            return .regularWidthWidePlay
        }
        return .compactLandscape
    }
}

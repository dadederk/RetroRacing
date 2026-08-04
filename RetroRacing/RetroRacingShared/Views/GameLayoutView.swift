//
//  GameLayoutView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI

struct GameLayoutView<GameArea: View>: View {
    let layoutPolicy: GameLayoutPolicy
    let topSafeAreaInset: CGFloat
    let hud: GameHUDInput
    let controls: GameControlInput
    let lifecycle: GameAreaLifecycleCallbacks
    @ViewBuilder let gameArea: (CGFloat) -> GameArea

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            let gameAreaLayoutConfiguration = GameAreaLayoutConfiguration.resolve(
                policy: layoutPolicy,
                topSafeAreaInset: topSafeAreaInset
            )
            switch layoutPolicy.kind {
            case .compactLandscape:
                CompactLandscapeGameLayout(
                    hud: hud,
                    controls: controls,
                    topSafeAreaInset: gameAreaLayoutConfiguration.topSafeAreaInset,
                    gameArea: gameAreaContainer(configuration: gameAreaLayoutConfiguration)
                )
            case .regularWidthWidePlay:
                RegularWidthGameLayout(
                    hud: hud,
                    controls: controls,
                    gameArea: gameAreaContainer(configuration: gameAreaLayoutConfiguration)
                )
            case .portrait, .portraitCentered:
                PortraitGameLayout(
                    hud: hud,
                    controls: controls,
                    centersPlayArea: layoutPolicy.kind == .portraitCentered,
                    gameArea: gameAreaContainer(configuration: gameAreaLayoutConfiguration)
                )
            }
            if hud.showsSpeedAlert {
                GameSpeedAlertView(
                    input: hud,
                    usesCompactLandscapeLayout: layoutPolicy.kind == .compactLandscape
                )
            }
        }
    }

    private func gameAreaContainer(configuration: GameAreaLayoutConfiguration) -> some View {
        GameAreaContainer(
            layoutConfiguration: configuration,
            controls: controls,
            lifecycle: lifecycle,
            content: gameArea
        )
    }
}

struct GameLayoutPolicy: Equatable {
    let kind: GameLayoutKind
    let expandsGameAreaIntoTopSafeArea: Bool

    private init(kind: GameLayoutKind, expandsGameAreaIntoTopSafeArea: Bool) {
        self.kind = kind
        self.expandsGameAreaIntoTopSafeArea = expandsGameAreaIntoTopSafeArea
    }

    static func resolve(
        containerSize: CGSize,
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        platformSupportsTopSafeAreaExpansion: Bool,
        isScreenshotCapture: Bool
    ) -> GameLayoutPolicy {
        let kind = GameLayoutKind.resolve(
            containerSize: containerSize,
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
        let expandsGameAreaIntoTopSafeArea = platformSupportsTopSafeAreaExpansion
            && !isScreenshotCapture
            && kind == .compactLandscape
        return GameLayoutPolicy(
            kind: kind,
            expandsGameAreaIntoTopSafeArea: expandsGameAreaIntoTopSafeArea
        )
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

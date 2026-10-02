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
    let tabletopDivision: GameTabletopDivision?
    let hud: GameHUDInput
    let controls: GameControlInput
    let lifecycle: GameAreaLifecycleCallbacks
    @ViewBuilder let gameArea: (CGFloat) -> GameArea
    let inputOverlay: GameInputOverlay

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            let gameAreaLayoutConfiguration = GameAreaLayoutConfiguration.resolve(
                policy: layoutPolicy,
                topSafeAreaInset: topSafeAreaInset
            )
            if let tabletopDivision {
                GameTabletopLayout(
                    division: tabletopDivision,
                    hud: hud,
                    controls: controls,
                    gameArea: gameAreaContainer(configuration: .standard),
                    inputOverlay: inputOverlay
                )
                if hud.showsSpeedAlert {
                    GameSpeedAlertView(input: hud, usesCompactLandscapeLayout: false)
                        .frame(height: tabletopDivision.topHeight, alignment: .bottomLeading)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            } else {
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
                inputOverlay
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

struct GameTabletopDivision: Equatable {
    let topHeight: CGFloat
    let hingeHeight: CGFloat
    let bottomHeight: CGFloat

    static func resolve(in size: CGSize, divisionFrames: [CGRect]) -> GameTabletopDivision? {
        let bounds = CGRect(origin: .zero, size: size)
        guard size.width > 0, size.height > 0 else { return nil }

        for frame in divisionFrames {
            let intersection = bounds.intersection(frame)
            guard intersection.isNull == false,
                  intersection.height > 0,
                  intersection.width >= size.width * 0.65,
                  intersection.width > intersection.height else { continue }

            let topHeight = intersection.minY
            let bottomHeight = size.height - intersection.maxY
            guard min(topHeight, bottomHeight) >= size.height * 0.2 else { continue }
            return GameTabletopDivision(
                topHeight: topHeight,
                hingeHeight: intersection.height,
                bottomHeight: bottomHeight
            )
        }
        return nil
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
        isScreenshotCapture: Bool,
        usesAccessibilityLayout: Bool = false
    ) -> GameLayoutPolicy {
        let kind = GameLayoutKind.resolve(
            containerSize: containerSize,
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            usesAccessibilityLayout: usesAccessibilityLayout
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
        verticalSizeClass: UserInterfaceSizeClass?,
        usesAccessibilityLayout: Bool = false
    ) -> GameLayoutKind {
        if usesAccessibilityLayout {
            return horizontalSizeClass == .regular ? .portraitCentered : .portrait
        }

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

//
//  GameLayoutInputs.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/08/2026.
//

import SwiftUI

struct GameLayoutSafeAreaInsets: Equatable {
    let top: CGFloat
    let leading: CGFloat
    let bottom: CGFloat
    let trailing: CGFloat

    init(
        top: CGFloat = 0,
        leading: CGFloat = 0,
        bottom: CGFloat = 0,
        trailing: CGFloat = 0
    ) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    init(_ edgeInsets: EdgeInsets) {
        self.init(
            top: edgeInsets.top,
            leading: edgeInsets.leading,
            bottom: edgeInsets.bottom,
            trailing: edgeInsets.trailing
        )
    }
}

struct GameHUDInput {
    let style: GameViewStyle
    let score: Int
    let lives: Int
    let showsSpeedAlert: Bool
    let lifeAssetName: String
    let friendLifeAssetName: String
    let bundle: Bundle
    let hidesFromAccessibility: Bool
    let headerFont: Font
    let speedAlertFont: Font
    let friendHeaderFont: Font
    let sharePlayOpponentName: String?
    let sharePlayOpponentScore: Int?
    let sharePlayOpponentLives: Int?
}

struct GameControlInput {
    let leftButtonDown: Bool
    let rightButtonDown: Bool
    let directionButtonHeight: CGFloat
    let bundle: Bundle
    let inputAdapter: GameInputAdapter?
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void
    let onKeyboardInput: () -> Void
    let onSwipeInput: () -> Void
    let onTogglePause: () -> Void
}

struct GameAreaLifecycleCallbacks {
    let onAppearSide: (CGFloat) -> Void
    let onResizeSide: (CGFloat) -> Void
}

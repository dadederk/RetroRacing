//
//  GameLayoutInputs.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/08/2026.
//

import SwiftUI

enum GameControlLayoutPolicy {
    static let baseDirectionButtonHeight: CGFloat = 120
    static let maximumDirectionButtonDynamicTypeSize: DynamicTypeSize = .xxxLarge
}

struct GameDirectionButtonHeightReader<Content: View>: View {
    @ViewBuilder let content: (CGFloat) -> Content

    @ScaledMetric(relativeTo: .largeTitle)
    private var directionButtonHeight: CGFloat = GameControlLayoutPolicy.baseDirectionButtonHeight

    var body: some View {
        content(directionButtonHeight)
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
    let headerTextStyle: Font.TextStyle
    let speedAlertTextStyle: Font.TextStyle
    let friendHeaderTextStyle: Font.TextStyle
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

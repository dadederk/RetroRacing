//
//  GameLayoutCompositions.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/08/2026.
//

import SwiftUI

struct PortraitGameLayout<GameArea: View>: View {
    let hud: GameHUDInput
    let controls: GameControlInput
    let centersPlayArea: Bool
    let gameArea: GameArea

    var body: some View {
        VStack(spacing: 8) {
            GameHUDHeaderView(input: hud, presentation: .fullWidth)
            if centersPlayArea {
                Spacer(minLength: 0)
                playArea
                Spacer(minLength: 0)
            } else {
                playArea
            }
        }
    }

    private var playArea: some View {
        VStack(spacing: 8) {
            gameArea
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
            GameDirectionControlsView(input: controls, presentation: .row)
                .frame(
                    maxWidth: centersPlayArea ? nil : .infinity,
                    minHeight: centersPlayArea ? nil : controls.directionButtonHeight,
                    maxHeight: centersPlayArea ? nil : .infinity,
                    alignment: .center
                )
        }
    }
}

struct RegularWidthGameLayout<GameArea: View>: View {
    let hud: GameHUDInput
    let controls: GameControlInput
    let gameArea: GameArea

    private let controlsSideRailWidth: CGFloat = 160

    var body: some View {
        VStack(spacing: 8) {
            GameHUDHeaderView(input: hud, presentation: .fullWidth)
            Spacer(minLength: 0)
            HStack(alignment: .center, spacing: 0) {
                railControl(.left)
                gameArea.frame(maxWidth: .infinity)
                railControl(.right)
            }
            Spacer(minLength: 0)
        }
    }

    private func railControl(_ direction: GameDirectionControlsView.Direction) -> some View {
        GameDirectionControlsView(input: controls, presentation: .single(direction))
            .frame(width: controlsSideRailWidth, height: controls.directionButtonHeight)
            .padding(.horizontal, 8)
    }
}

struct CompactLandscapeGameLayout<GameArea: View>: View {
    let hud: GameHUDInput
    let controls: GameControlInput
    let gameArea: GameArea

    private let scoreSideRailWidth: CGFloat = 160
    private let controlsSideRailWidth: CGFloat = 160

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                GameHUDHeaderView(input: hud, presentation: .compactLandscapeScoreRail)
                Spacer(minLength: 8)
                GameDirectionControlsView(input: controls, presentation: .single(.left))
                    .frame(minWidth: 100, minHeight: 80)
                Spacer(minLength: 8)
            }
            .frame(width: scoreSideRailWidth)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            gameArea.frame(maxWidth: .infinity)

            VStack(alignment: .trailing, spacing: 0) {
                GameHUDHeaderView(input: hud, presentation: .compactLandscapeLivesRail)
                Spacer(minLength: 8)
                GameDirectionControlsView(input: controls, presentation: .single(.right))
                    .frame(minWidth: 100, minHeight: 80)
                Spacer(minLength: 8)
            }
            .frame(width: controlsSideRailWidth)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}

//
//  GameDirectionControlsView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/08/2026.
//

import SwiftUI

struct GameDirectionControlsView: View {
    enum Presentation {
        case row
        case single(Direction)
    }

    enum Direction: Equatable {
        case left
        case right
    }

    let input: GameControlInput
    let presentation: Presentation

    var body: some View {
        switch presentation {
        case .row:
            HStack(alignment: .center, spacing: 0) {
                directionButton(.left)
                directionButton(.right)
            }
            .frame(height: input.directionButtonHeight, alignment: .center)
        case let .single(direction):
            directionButton(direction)
        }
    }

    private func directionButton(_ direction: Direction) -> some View {
        let isPressed = direction == .left ? input.leftButtonDown : input.rightButtonDown
        return Image(isPressed ? "ButtonDown" : "ButtonUp", bundle: input.bundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(
                maxWidth: .infinity,
                maxHeight: input.directionButtonHeight,
                alignment: .center
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

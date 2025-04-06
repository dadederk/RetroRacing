//
//  GameView.swift
//  RetroRacing watchOS Watch App
//
//  Created by Dani on 04/04/2025.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @State private var gameScene = GameScene(size: CGSize(width: 800, height: 600))
    @State private var rotationValue: Double = 0.0
    
    var body: some View {
        SpriteView(scene: gameScene)
            .focusable()
            .digitalCrownRotation($rotationValue, from: 0.0, through: 100.0, by: 1.0, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: true)
            .onChange(of: rotationValue, initial: true) { oldValue, newValue in
                print("\(oldValue) - \(newValue)")
                if newValue > oldValue {
                    gameScene.moveRight()
                } else if newValue < oldValue {
                    gameScene.moveLeft()
                }
            }
    }
}

#Preview {
    GameView()
}

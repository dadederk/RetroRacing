//
//  VisionGameControls.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 05/08/2026.
//

import RetroRacingShared
import SwiftUI

struct VisionGameOverPanel: View {
    @Environment(VisionGameSessionCoordinator.self) private var session

    var body: some View {
        VStack(spacing: 14) {
            Text(GameLocalizedStrings.string("vision_game_over"))
                .font(.title.bold())
            Text(GameLocalizedStrings.format("score %lld", session.snapshot.score))
                .font(.title3.monospacedDigit())
            ViewThatFits {
                HStack(spacing: 12) { gameOverButtons }
                VStack(spacing: 10) { gameOverButtons }
            }
        }
        .padding(24)
        .background(.regularMaterial, in: .rect(cornerRadius: 24))
    }

    @ViewBuilder
    private var gameOverButtons: some View {
        Button(
            GameLocalizedStrings.string("restart"),
            systemImage: "arrow.clockwise",
            action: session.restart
        )
        .buttonStyle(.borderedProminent)
        Button(GameLocalizedStrings.string("finish"), action: session.finish)
            .buttonStyle(.bordered)
    }
}

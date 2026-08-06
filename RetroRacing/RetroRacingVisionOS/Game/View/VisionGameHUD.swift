//
//  VisionGameHUD.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 05/08/2026.
//

import RetroRacingShared
import SwiftUI

struct VisionGameHUD: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    let snapshot: GameSnapshot

    var body: some View {
        ViewThatFits {
            HStack(spacing: 28) {
                scoreView
                livesView
                levelView
            }
            VStack(spacing: 10) {
                HStack(spacing: 24) {
                    scoreView
                    levelView
                }
                livesView
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GameLocalizedStrings.string("vision_race_status"))
        .accessibilityValue(
            GameLocalizedStrings.format(
                "vision_hud_status_format",
                snapshot.score,
                snapshot.lives,
                snapshot.level
            )
        )
    }

    private var scoreView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(GameLocalizedStrings.string("score"))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(snapshot.score, format: .number)
                .font(.title.monospacedDigit())
        }
    }

    private var livesView: some View {
        HStack(spacing: 8) {
            ForEach(0..<GameState.initialLives, id: \.self) { lifeIndex in
                Image(systemName: lifeIndex < snapshot.lives
                    ? "person.crop.circle.fill"
                    : "person.crop.circle")
                    .foregroundStyle(.red)
                    .opacity(lifeIndex < snapshot.lives ? 1 : 0.35)
                    .accessibilityHidden(true)
            }
            if differentiateWithoutColor {
                Text(snapshot.lives, format: .number)
                    .font(.headline.monospacedDigit())
            }
        }
    }

    @ViewBuilder
    private var levelView: some View {
        if snapshot.level > 1 {
            Text(GameLocalizedStrings.format("vision_level_format", snapshot.level))
                .font(.headline.monospacedDigit())
        }
    }
}

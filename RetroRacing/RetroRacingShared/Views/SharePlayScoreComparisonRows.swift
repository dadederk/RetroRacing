//
//  SharePlayScoreComparisonRows.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import SwiftUI

/// Named score comparison rows shared between SharePlay result and game-over social layouts.
public struct SharePlayScoreComparisonRows: View {
    let localLabel: String
    let localScore: Int
    let opponentLabel: String
    let opponentScore: Int

    public init(
        localLabel: String,
        localScore: Int,
        opponentLabel: String,
        opponentScore: Int
    ) {
        self.localLabel = localLabel
        self.localScore = localScore
        self.opponentLabel = opponentLabel
        self.opponentScore = opponentScore
    }

    public var body: some View {
        VStack(spacing: 8) {
            comparisonRow(label: localLabel, score: localScore)
            comparisonRow(label: opponentLabel, score: opponentScore)
        }
        .accessibilityElement(children: .combine)
    }

    private func comparisonRow(label: String, score: Int) -> some View {
        Text(GameLocalizedStrings.format("shareplay_score_row %@ %lld", label, Int64(score)))
            .appFont(.headline)
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(
                GameLocalizedStrings.format("shareplay_score_row %@ %lld", label, Int64(score))
            )
    }
}

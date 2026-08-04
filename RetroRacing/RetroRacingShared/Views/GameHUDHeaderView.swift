//
//  GameHUDHeaderView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/08/2026.
//

import SwiftUI

struct GameHUDHeaderView: View {
    enum Presentation {
        case fullWidth
        case compactLandscapeScoreRail
        case compactLandscapeLivesRail
    }

    let input: GameHUDInput
    let presentation: Presentation

    #if os(macOS) || os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title) private var titleLifeIconScale: CGFloat = 1
    @ScaledMetric(relativeTo: .title2) private var titleTwoLifeIconScale: CGFloat = 1

    @ViewBuilder
    var body: some View {
        switch presentation {
        case .fullWidth:
            fullWidthHeader
        case .compactLandscapeScoreRail:
            VStack(alignment: .leading, spacing: 0) {
                scoreLabel
                sharePlayOpponentHeaderRow
            }
            .allowsHitTesting(false)
        case .compactLandscapeLivesRail:
            livesView
                .allowsHitTesting(false)
        }
    }

    private var fullWidthHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if shouldUseVerticalHeader {
                    VStack(alignment: .leading, spacing: 6) {
                        scoreLabel
                        livesView
                    }
                } else {
                    HStack(alignment: .center, spacing: 12) {
                        scoreLabel
                            .layoutPriority(1)
                        Spacer(minLength: 16)
                        livesView
                            .layoutPriority(2)
                    }
                }
            }
            sharePlayOpponentHeaderRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, input.style.headerPadding)
        .padding(.top, input.style.headerPadding)
        .padding(.bottom, 4)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var sharePlayOpponentHeaderRow: some View {
        if let opponentScore = input.sharePlayOpponentScore {
            Group {
                if shouldUseVerticalHeader {
                    VStack(alignment: .leading, spacing: 4) {
                        opponentScoreText(score: opponentScore)
                        if let opponentLives = input.sharePlayOpponentLives {
                            opponentLivesView(lives: opponentLives)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        opponentScoreText(score: opponentScore)
                        Spacer(minLength: 0)
                        if let opponentLives = input.sharePlayOpponentLives {
                            opponentLivesView(lives: opponentLives)
                        }
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                GameLocalizedStrings.format(
                    "shareplay_score_accessibility %@ %lld %lld",
                    opponentScoreLabel,
                    Int64(opponentScore),
                    Int64(input.sharePlayOpponentLives ?? 0)
                )
            )
            .accessibilityHidden(input.hidesFromAccessibility)
        }
    }

    private func opponentScoreText(score: Int) -> some View {
        Text(
            GameLocalizedStrings.format(
                "shareplay_score_row %@ %lld",
                opponentScoreLabel,
                Int64(score)
            )
        )
        .font(input.friendHeaderFont)
        .foregroundStyle(.secondary)
        .lineLimit(shouldUseVerticalHeader ? nil : 1)
        .minimumScaleFactor(shouldUseVerticalHeader ? 1 : 0.75)
    }

    private var opponentScoreLabel: String {
        guard let name = input.sharePlayOpponentName else {
            return GameLocalizedStrings.string("shareplay_opponent_score_fallback_label")
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty
            ? GameLocalizedStrings.string("shareplay_opponent_score_fallback_label")
            : trimmedName
    }

    private func opponentLivesView(lives: Int) -> some View {
        GameLivesStatusView(
            lives: lives,
            lifeAssetName: input.friendLifeAssetName,
            bundle: input.bundle,
            visibleHeight: input.style.friendLifeIconSize * friendLifeIconScale
        )
        .accessibilityHidden(true)
    }

    private var scoreLabel: some View {
        Group {
            if input.sharePlayOpponentScore == nil {
                GameScoreStatusView(score: input.score, font: input.headerFont)
            } else {
                Text(scoreText)
                    .font(input.headerFont)
                    .foregroundStyle(.primary)
                    .shadow(color: Color.primary.opacity(0.35), radius: 0.5)
                    .accessibilityLabel(scoreText)
                    .accessibilityAddTraits(.isStaticText)
                    .accessibilityRespondsToUserInteraction(false)
            }
        }
        .lineLimit(scoreLabelLineLimit)
        .minimumScaleFactor(scoreLabelMinimumScaleFactor)
        .allowsTightening(scoreLabelAllowsTightening)
        .fixedSize(horizontal: false, vertical: usesCompactLandscapeLayout)
        .multilineTextAlignment(.leading)
        .accessibilityHidden(input.hidesFromAccessibility)
    }

    private var scoreText: String {
        guard input.sharePlayOpponentScore != nil else {
            return GameLocalizedStrings.format("score %lld", Int64(input.score))
        }
        return GameLocalizedStrings.format("shareplay_your_score_row %lld", Int64(input.score))
    }

    private var scoreLabelLineLimit: Int? {
        if shouldUseVerticalHeader || usesCompactLandscapeLayout { return nil }
        return 1
    }

    private var scoreLabelMinimumScaleFactor: CGFloat {
        shouldUseVerticalHeader || usesCompactLandscapeLayout ? 1 : 0.75
    }

    private var scoreLabelAllowsTightening: Bool {
        shouldUseVerticalHeader == false && usesCompactLandscapeLayout == false
    }

    private var livesView: some View {
        GameLivesStatusView(
            lives: input.lives,
            lifeAssetName: input.lifeAssetName,
            bundle: input.bundle,
            visibleHeight: input.style.lifeIconSize * lifeIconScale
        )
        .accessibilityHidden(input.hidesFromAccessibility)
    }

    private var lifeIconScale: CGFloat {
        titleLifeIconScale
    }

    private var friendLifeIconScale: CGFloat {
        titleTwoLifeIconScale
    }

    private var shouldUseVerticalHeader: Bool {
        #if os(macOS) || os(iOS)
        if horizontalSizeClass == .regular, verticalSizeClass == .regular {
            return false
        }
        if horizontalSizeClass == .regular {
            return dynamicTypeSize.isAccessibilitySize
        }
        #endif
        return dynamicTypeSize.isAccessibilitySize || dynamicTypeSize >= .xxLarge
    }

    private var usesCompactLandscapeLayout: Bool {
        switch presentation {
        case .fullWidth:
            false
        case .compactLandscapeScoreRail, .compactLandscapeLivesRail:
            true
        }
    }
}

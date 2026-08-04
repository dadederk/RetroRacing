//
//  GameOverView+Content.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import SwiftUI

extension GameOverView {
    var gameOverMainContent: some View {
        VStack(spacing: gameOverContentSpacing) {
            heroImage
            subtitleText
            scoreRows
            speedRow
            socialRows
            if !usesBottomActionBar {
                actionButtons
            }
        }
        .padding(gameOverContentPadding)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    var heroImage: some View {
        Image(isNewRecord ? "NewRecord" : "Finished", bundle: Self.sharedBundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: gameOverHeroImageMaxWidth)
            .accessibilityHidden(true)
    }

    var subtitleText: some View {
        Text(GameLocalizedStrings.string(isNewRecord ? "game_over_new_record_subtitle" : "game_over_encouragement_subtitle"))
            .font(bodyFont)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    var scoreRows: some View {
        VStack(spacing: 8) {
            if isNewRecord {
                #if os(watchOS)
                Text(GameLocalizedStrings.format("game_over_new_record_value %lld", Int64(bestScore)))
                Text(
                    GameLocalizedStrings.format(
                        "game_over_previous_best %lld",
                        Int64(previousBestScore ?? 0)
                    )
                )
                #else
                Text(
                    GameLocalizedStrings.format(
                        "game_over_previous_best %lld",
                        Int64(previousBestScore ?? 0)
                    )
                )
                Text(GameLocalizedStrings.format("game_over_new_record_value %lld", Int64(bestScore)))
                #endif
            } else {
                Text(GameLocalizedStrings.format("score %lld", Int64(score)))
                Text(GameLocalizedStrings.format("game_over_best %lld", Int64(bestScore)))
            }
        }
        .font(scoreFont.monospacedDigit())
        .multilineTextAlignment(.center)
    }

    var speedRow: some View {
        Text(GameLocalizedStrings.format("game_over_speed %@", GameLocalizedStrings.string(difficulty.localizedNameKey)))
            .font(bodyFont)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    var socialRows: some View {
        GameOverSocialStatsSection(
            nextFriendAhead: nextFriendAhead,
            overtakenFriends: overtakenFriends,
            avatarSize: avatarSize,
            bodyFont: bodyFont,
            scoreFont: scoreFont
        )
    }

    var actionButtons: some View {
        actionButtonsContent
            .padding(.top, 4)
    }

    #if os(iOS) || os(visionOS)
    var bottomActionBar: some View {
        BottomActionBar {
            actionButtonsContent
        }
    }
    #endif

    private var actionButtonsContent: some View {
        VStack(spacing: 10) {
            Button(action: onRestart) {
                Text(GameLocalizedStrings.string("restart"))
                    .font(buttonFont)
            }
            .retroRacingPrimaryButtonStyle()

            Button(action: onFinish) {
                Text(GameLocalizedStrings.string("finish"))
                    .font(buttonFont)
            }
            .retroRacingSecondaryButtonStyle()
        }
    }

    var bodyFont: Font {
        fontPreferenceStore?.font(textStyle: .body) ?? .body
    }

    var scoreFont: Font {
        fontPreferenceStore?.font(textStyle: .headline) ?? .headline
    }

    var buttonFont: Font {
        fontPreferenceStore?.font(textStyle: .headline) ?? .headline
    }

    var gameOverContentSpacing: CGFloat {
        #if os(watchOS)
        8
        #else
        18
        #endif
    }

    var gameOverContentPadding: CGFloat {
        #if os(watchOS)
        10
        #else
        20
        #endif
    }

    var gameOverHeroImageMaxWidth: CGFloat {
        #if os(watchOS)
        125
        #else
        220
        #endif
    }
}

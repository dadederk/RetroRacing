//
//  GameOverView+Content.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import SwiftUI

extension GameOverView {
    var gameOverMainContent: some View {
        VStack(spacing: 18) {
            heroImage
            subtitleText
            scoreRows
            speedRow
            socialRows
            actionButtons
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    var heroImage: some View {
        Image(isNewRecord ? "NewRecord" : "Finished", bundle: Self.sharedBundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 220)
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
                Text(
                    GameLocalizedStrings.format(
                        "game_over_previous_best %lld",
                        Int64(previousBestScore ?? 0)
                    )
                )
                Text(GameLocalizedStrings.format("game_over_new_record_value %lld", Int64(bestScore)))
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
        if nextFriendAhead != nil || overtakenFriends.isEmpty == false {
            VStack(spacing: 8) {
                if let nextFriendAhead {
                    Text(GameLocalizedStrings.string("game_over_next_friend_ahead_title"))
                        .font(bodyFont)
                        .foregroundStyle(.secondary)
                    socialFriendScoreRow(
                        displayName: nextFriendAhead.displayName,
                        score: nextFriendAhead.score,
                        avatarPNGData: nextFriendAhead.avatarPNGData
                    )
                }

                if overtakenFriends.isEmpty == false {
                    Text(GameLocalizedStrings.string("game_over_overtaken_friends_title"))
                        .font(bodyFont)
                        .foregroundStyle(.secondary)

                    ForEach(Array(overtakenFriends.prefix(3))) { friend in
                        socialFriendScoreRow(
                            displayName: friend.displayName,
                            score: friend.score,
                            avatarPNGData: friend.avatarPNGData
                        )
                    }

                    let hiddenCount = overtakenFriends.count - 3
                    if hiddenCount > 0 {
                        Text(
                            GameLocalizedStrings.format(
                                "game_over_overtaken_friends_more %lld",
                                Int64(hiddenCount)
                            )
                        )
                        .font(bodyFont)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .multilineTextAlignment(.center)
        }
    }

    var actionButtons: some View {
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
        .padding(.top, 4)
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
}

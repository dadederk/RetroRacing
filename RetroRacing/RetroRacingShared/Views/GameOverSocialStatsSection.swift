//
//  GameOverSocialStatsSection.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import SwiftUI

struct GameOverSocialStatsSection: View {
    let nextFriendAhead: GameOverFriendAheadSummary?
    let overtakenFriends: [GameOverOvertakenFriendSummary]
    let avatarSize: CGFloat
    let bodyFont: Font
    let scoreFont: Font

    var body: some View {
        if nextFriendAhead != nil || overtakenFriends.isEmpty == false {
            VStack(spacing: 8) {
                nextFriendAheadSection
                overtakenFriendsSection
            }
            .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var nextFriendAheadSection: some View {
        if let nextFriendAhead {
            Text(GameLocalizedStrings.string("game_over_next_friend_ahead_title"))
                .font(bodyFont)
                .foregroundStyle(.secondary)
            friendScoreRow(
                displayName: nextFriendAhead.displayName,
                score: nextFriendAhead.score,
                avatarPNGData: nextFriendAhead.avatarPNGData
            )
        }
    }

    @ViewBuilder
    private var overtakenFriendsSection: some View {
        if overtakenFriends.isEmpty == false {
            Text(GameLocalizedStrings.string("game_over_overtaken_friends_title"))
                .font(bodyFont)
                .foregroundStyle(.secondary)

            ForEach(Array(overtakenFriends.prefix(3))) { friend in
                friendScoreRow(
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

    private func friendScoreRow(
        displayName: String,
        score: Int,
        avatarPNGData: Data?
    ) -> some View {
        GameOverSocialFriendScoreRow(
            displayName: displayName,
            score: score,
            avatarPNGData: avatarPNGData,
            avatarSize: avatarSize,
            bodyFont: bodyFont,
            scoreFont: scoreFont
        )
    }
}

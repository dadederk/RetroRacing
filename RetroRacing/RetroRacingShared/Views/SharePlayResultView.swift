//
//  SharePlayResultView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import SwiftUI

/// Presented as a sheet from `GameView` while the SharePlay match is `.finished`,
/// `.retryWaiting`, `.retryTimedOut`, or `.aborted`. Merges match outcome with the personal
/// stats normally shown on the solo game-over screen.
public struct SharePlayResultView: View {
    let state: SharePlayMatchState
    let localRole: SharePlayPlayerRole?
    let opponentDisplayName: String?
    let score: Int
    let bestScore: Int
    let difficulty: GameDifficulty
    let isNewRecord: Bool
    let previousBestScore: Int?
    let nextFriendAhead: GameOverFriendAheadSummary?
    let overtakenFriends: [GameOverOvertakenFriendSummary]
    let newlyAchievedAchievementIDs: [AchievementIdentifier]
    let onRetry: () -> Void
    let onLeave: () -> Void

    @Environment(\.fontPreferenceStore) private var fontPreferenceStore
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 24
    @State private var pendingAchievementIDs: [AchievementIdentifier] = []
    @State private var presentedAchievementID: AchievementIdentifier?

    public init(
        state: SharePlayMatchState,
        localRole: SharePlayPlayerRole?,
        opponentDisplayName: String?,
        score: Int,
        bestScore: Int,
        difficulty: GameDifficulty,
        isNewRecord: Bool,
        previousBestScore: Int?,
        nextFriendAhead: GameOverFriendAheadSummary?,
        overtakenFriends: [GameOverOvertakenFriendSummary],
        newlyAchievedAchievementIDs: [AchievementIdentifier],
        onRetry: @escaping () -> Void,
        onLeave: @escaping () -> Void
    ) {
        self.state = state
        self.localRole = localRole
        self.opponentDisplayName = opponentDisplayName
        self.score = score
        self.bestScore = bestScore
        self.difficulty = difficulty
        self.isNewRecord = isNewRecord
        self.previousBestScore = previousBestScore
        self.nextFriendAhead = nextFriendAhead
        self.overtakenFriends = overtakenFriends
        self.newlyAchievedAchievementIDs = newlyAchievedAchievementIDs
        self.onRetry = onRetry
        self.onLeave = onLeave
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 0)
                    content
                    Spacer(minLength: 0)
                    if !usesBottomActionBar {
                        actions
                    }
                }
                .padding()
            }
            #if os(iOS) || os(visionOS)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if usesBottomActionBar {
                    BottomActionBar { actions }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            #endif
            .navigationTitle(navigationTitle)
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .interactiveDismissDisabled(true)
        .sheet(item: $presentedAchievementID) { achievementID in
            AchievementUnlockView(
                achievementID: achievementID,
                onDone: advanceToNextAchievement
            )
        }
        .onAppear {
            pendingAchievementIDs = Array(newlyAchievedAchievementIDs.dropFirst())
            presentedAchievementID = newlyAchievedAchievementIDs.first
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .finished(let result):
            finishedContent(result: result)
        case .retryWaiting(let localReady, let remoteReady, _):
            retryWaitingContent(localReady: localReady, remoteReady: remoteReady)
        case .retryTimedOut:
            retryTimedOutContent
        case .aborted(let reason):
            abortedContent(reason: reason)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch state {
        case .finished:
            VStack(spacing: 10) {
                Button(action: onRetry) {
                    Text(GameLocalizedStrings.string("shareplay_retry_button"))
                        .font(buttonFont)
                }
                .retroRacingPrimaryButtonStyle()
                Button(action: onLeave) {
                    Text(GameLocalizedStrings.string("shareplay_leave_button"))
                        .font(buttonFont)
                }
                .retroRacingSecondaryButtonStyle()
            }
        case .retryTimedOut:
            Button(action: onLeave) {
                Text(GameLocalizedStrings.string("shareplay_leave_button"))
                    .font(buttonFont)
            }
            .retroRacingPrimaryButtonStyle()
        case .retryWaiting(let localReady, _, _):
            if localReady {
                Button(action: onLeave) {
                    Text(GameLocalizedStrings.string("shareplay_leave_button"))
                        .font(buttonFont)
                }
                    .retroRacingSecondaryButtonStyle()
            } else {
                VStack(spacing: 10) {
                    Button(action: onRetry) {
                        Text(GameLocalizedStrings.string("shareplay_retry_button"))
                            .font(buttonFont)
                    }
                    .retroRacingPrimaryButtonStyle()
                    Button(action: onLeave) {
                        Text(GameLocalizedStrings.string("shareplay_leave_button"))
                            .font(buttonFont)
                    }
                    .retroRacingSecondaryButtonStyle()
                }
            }
        case .aborted:
            Button(action: onLeave) {
                Text(GameLocalizedStrings.string("shareplay_done_button"))
                    .font(buttonFont)
            }
                .retroRacingPrimaryButtonStyle()
        default:
            EmptyView()
        }
    }

    private func finishedContent(result: SharePlayRoundResult) -> some View {
        let outcome = result.localOutcome(for: localRole ?? .host)
        let localScore = result.score(for: localRole ?? .host)
        let opponentScore = result.opponentScore(for: localRole ?? .host)
        let opponentLabel = resolvedOpponentScoreLabel

        return VStack(spacing: 20) {
            outcomeArtwork(outcome)

            Text(outcomeTitle(outcome))
                .font(titleFont)
                .multilineTextAlignment(.center)

            Text(outcomeSubtitle(outcome))
                .font(bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SharePlayScoreComparisonRows(
                localLabel: GameLocalizedStrings.string("shareplay_local_player_name"),
                localScore: localScore,
                opponentLabel: opponentLabel,
                opponentScore: opponentScore,
                scoreFont: scoreFont
            )

            Divider()

            personalStatsSection

            socialStatsSection
        }
    }

    private var personalStatsSection: some View {
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
                Text(GameLocalizedStrings.format("game_over_your_best %lld", Int64(bestScore)))
            }
        }
        .font(scoreFont.monospacedDigit())
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var socialStatsSection: some View {
        VStack(spacing: 8) {
            Text(
                GameLocalizedStrings.format(
                    "game_over_speed %@",
                    GameLocalizedStrings.string(difficulty.localizedNameKey)
                )
            )
            .font(bodyFont)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            GameOverSocialStatsSection(
                nextFriendAhead: nextFriendAhead,
                overtakenFriends: overtakenFriends,
                avatarSize: avatarSize,
                bodyFont: bodyFont,
                scoreFont: scoreFont
            )
        }
        .multilineTextAlignment(.center)
    }

    private func retryWaitingContent(localReady: Bool, remoteReady: Bool) -> some View {
        VStack(spacing: 16) {
            resultAssetImage(named: "Rematch")
            ProgressView().progressViewStyle(.circular)
            Text(GameLocalizedStrings.string("shareplay_retry_waiting_title"))
                .font(headlineFont)
                .multilineTextAlignment(.center)
            Text(
                remoteReady && localReady == false
                    ? GameLocalizedStrings.string("shareplay_retry_waiting_for_you")
                    : GameLocalizedStrings.string("shareplay_retry_waiting_for_opponent")
            )
            .font(bodyFont)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private var retryTimedOutContent: some View {
        VStack(spacing: 16) {
            resultAssetImage(named: "Rematch")
            Text(GameLocalizedStrings.string("shareplay_retry_timed_out_title"))
                .font(titleFont)
                .multilineTextAlignment(.center)
            Text(GameLocalizedStrings.string("shareplay_retry_timed_out_body"))
                .font(bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private func abortedContent(reason: SharePlayAbortReason) -> some View {
        VStack(spacing: 16) {
            resultAssetImage(named: "ConnectionLost")
            Text(abortedTitle(for: reason))
                .font(titleFont)
                .multilineTextAlignment(.center)
            Text(abortedBody(for: reason))
                .font(bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private var navigationTitle: String {
        switch state {
        case .finished:
            return GameLocalizedStrings.string("game_over_encouragement_title")
        case .retryWaiting:
            return GameLocalizedStrings.string("shareplay_retry_waiting_title")
        case .retryTimedOut:
            return GameLocalizedStrings.string("shareplay_retry_timed_out_title")
        case .aborted:
            return GameLocalizedStrings.string("shareplay_aborted_title")
        default:
            return GameLocalizedStrings.string("shareplay_result_title")
        }
    }

    private func abortedTitle(for reason: SharePlayAbortReason) -> String {
        switch reason {
        case .disconnected, .sessionEnded:
            return GameLocalizedStrings.string("shareplay_disconnected_title")
        case .retryTimedOut:
            return GameLocalizedStrings.string("shareplay_aborted_title")
        }
    }

    private func abortedBody(for reason: SharePlayAbortReason) -> String {
        switch reason {
        case .disconnected:
            return GameLocalizedStrings.string("shareplay_aborted_disconnected_body")
        case .retryTimedOut:
            return GameLocalizedStrings.string("shareplay_retry_timed_out_body")
        case .sessionEnded:
            return GameLocalizedStrings.string("shareplay_aborted_session_ended_body")
        }
    }

    private var resolvedOpponentScoreLabel: String {
        if let opponentDisplayName = sanitizedOpponentDisplayName {
            return opponentDisplayName
        }
        return GameLocalizedStrings.string("shareplay_opponent_score_fallback_label")
    }

    private var sanitizedOpponentDisplayName: String? {
        guard let opponentDisplayName else { return nil }
        let trimmedName = opponentDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
    }

    private func outcomeAssetName(_ outcome: SharePlayRoundResult.LocalOutcome) -> String {
        switch outcome {
        case .won: return "WinWithFriend"
        case .lost: return "LoseWithFriend"
        case .tie: return "Tie"
        }
    }

    private func outcomeTitle(_ outcome: SharePlayRoundResult.LocalOutcome) -> String {
        switch outcome {
        case .won: return GameLocalizedStrings.string("shareplay_result_won")
        case .lost: return GameLocalizedStrings.string("shareplay_result_lost")
        case .tie: return GameLocalizedStrings.string("shareplay_result_tie")
        }
    }

    private func outcomeSubtitle(_ outcome: SharePlayRoundResult.LocalOutcome) -> String {
        switch outcome {
        case .won: return GameLocalizedStrings.string("shareplay_result_won_subtitle")
        case .lost: return GameLocalizedStrings.string("shareplay_result_lost_subtitle")
        case .tie: return GameLocalizedStrings.string("shareplay_result_tie_subtitle")
        }
    }

    @ViewBuilder
    private func outcomeArtwork(_ outcome: SharePlayRoundResult.LocalOutcome) -> some View {
        resultAssetImage(named: outcomeAssetName(outcome))
    }

    private func resultAssetImage(named assetName: String) -> some View {
        Image(assetName, bundle: GameOverView.sharedBundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 220)
            .accessibilityHidden(true)
    }

    private func advanceToNextAchievement() {
        if pendingAchievementIDs.isEmpty {
            presentedAchievementID = nil
        } else {
            presentedAchievementID = pendingAchievementIDs.removeFirst()
        }
    }

    private var bodyFont: Font {
        fontPreferenceStore?.font(textStyle: .body) ?? .body
    }

    private var headlineFont: Font {
        fontPreferenceStore?.font(textStyle: .headline) ?? .headline
    }

    private var titleFont: Font {
        fontPreferenceStore?.font(textStyle: .title2) ?? .title2
    }

    private var scoreFont: Font {
        fontPreferenceStore?.font(textStyle: .headline) ?? .headline
    }

    private var buttonFont: Font {
        fontPreferenceStore?.font(textStyle: .headline) ?? .headline
    }
}

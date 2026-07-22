//
//  SharePlayOverlayView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import SwiftUI

/// Transient, non-blocking-sheet SharePlay overlays rendered on top of the game square:
/// waiting for the friend to join, the synchronized countdown, the "friend still racing"
/// waiting screen after the local player loses first, and the disconnect message. Finished/retry
/// states are handled by `SharePlayResultView` instead, presented as a sheet from `GameView`.
struct SharePlayOverlayView: View {
    let state: SharePlayMatchState
    let opponentDisplayName: String?
    let onCountdownSecondChanged: (Int) -> Void

    @Environment(\.fontPreferenceStore) private var fontPreferenceStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var countdownDigitSize: CGFloat = 72
    @State private var lastTriggeredCountdownSecond: Int?

    init(
        state: SharePlayMatchState,
        opponentDisplayName: String?,
        onCountdownSecondChanged: @escaping (Int) -> Void = { _ in }
    ) {
        self.state = state
        self.opponentDisplayName = opponentDisplayName
        self.onCountdownSecondChanged = onCountdownSecondChanged
    }

    var body: some View {
        ZStack {
            switch state {
            case .waitingForFriend:
                statusCard(
                    assetName: "WaitingForFriendToJoin",
                    title: GameLocalizedStrings.string("shareplay_waiting_title"),
                    showsSpinner: true
                )
            case .countdown(let startAt, _):
                countdownCard(startAt: startAt)
            case .waitingAfterLocalLoss(let remoteScore, let localFinalScore):
                statusCard(
                    assetName: "WaitingForFriendToFinish",
                    title: GameLocalizedStrings.string("shareplay_waiting_for_opponent_title"),
                    subtitleLines: [
                        GameLocalizedStrings.format("shareplay_your_score_row %lld", Int64(localFinalScore)),
                        GameLocalizedStrings.format(
                            "shareplay_score_row %@ %lld",
                            sharePlayOpponentScoreLabel,
                            Int64(remoteScore)
                        )
                    ],
                    showsSpinner: true
                )
            case .aborted:
                statusCard(
                    assetName: "ConnectionLost",
                    usesTemplateAsset: false,
                    title: GameLocalizedStrings.string("shareplay_disconnected_title"),
                    showsSpinner: false
                )
            case .idle, .inRound, .finished, .retryWaiting, .retryTimedOut:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func statusCard(
        assetName: String,
        usesTemplateAsset: Bool = true,
        title: String,
        subtitleLines: [String] = [],
        showsSpinner: Bool
    ) -> some View {
        VStack(spacing: 12) {
            overlayAssetImage(named: assetName, usesTemplate: usesTemplateAsset)
            Text(title)
                .font(headlineFont)
                .multilineTextAlignment(.center)
            if subtitleLines.isEmpty == false {
                VStack(spacing: 4) {
                    ForEach(subtitleLines, id: \.self) { subtitle in
                        Text(subtitle)
                            .font(bodyFont)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            if showsSpinner {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .padding(24)
        .sharePlayOverlayCard()
        .accessibilityElement(children: .combine)
    }

    private func countdownCard(startAt: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let remaining = max(0, Int(ceil(startAt.timeIntervalSince(context.date))))
            let displayValue = remaining == 0 ? 1 : remaining

            VStack(spacing: 12) {
                overlayAssetImage(named: "GetReady", usesTemplate: true)
                Text(GameLocalizedStrings.string("shareplay_countdown_title"))
                    .font(headlineFont)
                Text("\(displayValue)")
                    .font(countdownFont)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy, value: displayValue)
            }
            .padding(24)
            .sharePlayOverlayCard()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                GameLocalizedStrings.format("shareplay_countdown_accessibility %lld", Int64(displayValue))
            )
            .onChange(of: displayValue, initial: true) { _, newValue in
                guard newValue > 0, lastTriggeredCountdownSecond != newValue else { return }
                lastTriggeredCountdownSecond = newValue
                onCountdownSecondChanged(newValue)
            }
        }
    }

    private func overlayAssetImage(named assetName: String, usesTemplate: Bool) -> some View {
        Image(assetName, bundle: GameView.sharedBundle)
            .renderingMode(usesTemplate ? .template : .original)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: usesTemplate ? 72 : 140)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }

    private var sharePlayOpponentScoreLabel: String {
        if let opponentName = sanitizedOpponentDisplayName {
            return opponentName
        }
        return GameLocalizedStrings.string("shareplay_opponent_score_fallback_label")
    }

    private var sanitizedOpponentDisplayName: String? {
        guard let opponentDisplayName else { return nil }
        let trimmedName = opponentDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
    }

    private var headlineFont: Font {
        fontPreferenceStore?.font(textStyle: .headline) ?? .headline
    }

    private var bodyFont: Font {
        fontPreferenceStore?.font(textStyle: .subheadline) ?? .subheadline
    }

    private var countdownFont: Font {
        fontPreferenceStore?.font(fixedSize: countdownDigitSize) ?? .system(size: countdownDigitSize, weight: .bold)
    }
}

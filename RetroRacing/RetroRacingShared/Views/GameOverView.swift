//
//  GameOverView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 16/02/2026.
//

import SwiftUI

/// Shared game-over modal shown across platforms.
public struct GameOverView: View {
    public let score: Int
    public let bestScore: Int
    public let difficulty: GameDifficulty
    public let isNewRecord: Bool
    public let previousBestScore: Int?
    public let onRestart: () -> Void
    public let onFinish: () -> Void
    public let onPresented: (() -> Void)?

    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    private static let sharedBundle = Bundle(for: GameScene.self)

    public init(
        score: Int,
        bestScore: Int,
        difficulty: GameDifficulty,
        isNewRecord: Bool,
        previousBestScore: Int?,
        onRestart: @escaping () -> Void,
        onFinish: @escaping () -> Void,
        onPresented: (() -> Void)? = nil
    ) {
        self.score = score
        self.bestScore = bestScore
        self.difficulty = difficulty
        self.isNewRecord = isNewRecord
        self.previousBestScore = previousBestScore
        self.onRestart = onRestart
        self.onFinish = onFinish
        self.onPresented = onPresented
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    heroImage
                    subtitleText
                    scoreRows
                    actionButtons
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.background)
            .navigationTitle(GameLocalizedStrings.string("game_over_encouragement_title"))
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .interactiveDismissDisabled(true)
        .onAppear {
            onPresented?()
        }
    }

    private var heroImage: some View {
        Image(isNewRecord ? "NewRecord" : "Finished", bundle: Self.sharedBundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 220)
            .accessibilityHidden(true)
    }

    private var subtitleText: some View {
        Text(GameLocalizedStrings.string(isNewRecord ? "game_over_new_record_subtitle" : "game_over_encouragement_subtitle"))
            .font(bodyFont)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var scoreRows: some View {
        VStack(spacing: 8) {
            Text(GameLocalizedStrings.format("game_over_speed %@", GameLocalizedStrings.string(difficulty.localizedNameKey)))
            if isNewRecord {
                Text(
                    GameLocalizedStrings.format(
                        "game_over_previous_best %lld",
                        previousBestScore ?? 0
                    )
                )
                Text(GameLocalizedStrings.format("game_over_new_record_value %lld", bestScore))
            } else {
                Text(GameLocalizedStrings.format("score %lld", score))
                Text(GameLocalizedStrings.format("game_over_best %lld", bestScore))
            }
        }
        .font(scoreFont.monospacedDigit())
        .multilineTextAlignment(.center)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(GameLocalizedStrings.string("restart"), action: onRestart)
                .font(buttonFont)
                .buttonStyle(.glassProminent)
            Button(GameLocalizedStrings.string("finish"), action: onFinish)
                .font(buttonFont)
                .buttonStyle(.glass)
        }
        .padding(.top, 4)
    }

    private var bodyFont: Font {
        fontPreferenceStore?.font(textStyle: .body) ?? .body
    }

    private var scoreFont: Font {
        fontPreferenceStore?.font(textStyle: .headline) ?? .headline
    }

    private var buttonFont: Font {
        fontPreferenceStore?.font(textStyle: .headline) ?? .headline
    }
}

#Preview("New Record") {
    GameOverView(
        score: 210,
        bestScore: 210,
        difficulty: .rapid,
        isNewRecord: true,
        previousBestScore: 182,
        onRestart: {},
        onFinish: {}
    )
}

#Preview("Finished") {
    GameOverView(
        score: 96,
        bestScore: 210,
        difficulty: .fast,
        isNewRecord: false,
        previousBestScore: nil,
        onRestart: {},
        onFinish: {}
    )
}

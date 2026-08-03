//
//  GameHUDStatusView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-08-02.
//

import SwiftUI

public struct GameScoreStatusView: View {
    private let score: Int
    private let font: Font

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(score: Int, font: Font) {
        self.score = score
        self.font = font
    }

    public var body: some View {
        Text(displayedScore, format: .number)
            .font(font)
            .monospacedDigit()
            .foregroundStyle(.primary)
            .shadow(color: Color.primary.opacity(0.35), radius: 0.5)
            .contentTransition(scoreContentTransition)
            .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: displayedScore)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                GameLocalizedStrings.format("score %lld", Int64(displayedScore))
            )
            .accessibilityAddTraits([.isStaticText, .updatesFrequently])
            .accessibilityRespondsToUserInteraction(false)
    }

    private var displayedScore: Int {
        max(0, score)
    }

    private var scoreContentTransition: ContentTransition {
        reduceMotion ? .identity : .numericText(countsDown: false)
    }
}

public struct GameLivesStatusView: View {
    private let lives: Int
    private let lifeAssetName: String
    private let bundle: Bundle
    private let visibleHeight: CGFloat
    private let spacing: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        lives: Int,
        lifeAssetName: String,
        bundle: Bundle,
        visibleHeight: CGFloat,
        spacing: CGFloat = 4
    ) {
        self.lives = lives
        self.lifeAssetName = lifeAssetName
        self.bundle = bundle
        self.visibleHeight = visibleHeight
        self.spacing = spacing
    }

    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<GameState.initialLives, id: \.self) { position in
                Image(decorative: lifeAssetName, bundle: bundle)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(
                        width: helmetCanvasHeight * Self.helmetCanvasAspectRatio,
                        height: helmetCanvasHeight
                    )
                    .opacity(Self.isConsumed(position, lives: lives) ? 0.3 : 1)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: displayedLives)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLivesLabel)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityRespondsToUserInteraction(false)
    }

    private var displayedLives: Int {
        Self.displayedLives(for: lives)
    }

    private var helmetCanvasHeight: CGFloat {
        Self.canvasHeight(forVisibleHeight: visibleHeight)
    }

    static func canvasHeight(forVisibleHeight visibleHeight: CGFloat) -> CGFloat {
        visibleHeight / helmetVisibleHeightRatio
    }

    private static var helmetCanvasAspectRatio: CGFloat {
        #if os(watchOS)
        64 / 55
        #else
        256 / 222
        #endif
    }

    private static var helmetVisibleHeightRatio: CGFloat {
        #if os(watchOS)
        53 / 55
        #else
        210 / 222
        #endif
    }

    static func isConsumed(_ position: Int, lives: Int) -> Bool {
        guard (0..<GameState.initialLives).contains(position) else { return false }
        return position < GameState.initialLives - displayedLives(for: lives)
    }

    private static func displayedLives(for lives: Int) -> Int {
        min(max(0, lives), GameState.initialLives)
    }

    private var accessibilityLivesLabel: String {
        if displayedLives == 1 {
            return GameLocalizedStrings.format("%lld life remaining", Int64(displayedLives))
        }
        return GameLocalizedStrings.format("%lld lives remaining", Int64(displayedLives))
    }
}

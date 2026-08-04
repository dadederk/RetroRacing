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
                LifeHelmetIconView(
                    assetName: lifeAssetName,
                    bundle: bundle,
                    canvasSize: helmetCanvasSize,
                    outlineColor: Self.consumedOutlineColor,
                    isConsumed: Self.isConsumed(position, lives: lives)
                )
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

    private var helmetCanvasSize: CGSize {
        CGSize(
            width: helmetCanvasHeight * Self.helmetCanvasAspectRatio,
            height: helmetCanvasHeight
        )
    }

    static func canvasHeight(forVisibleHeight visibleHeight: CGFloat) -> CGFloat {
        visibleHeight / helmetVisibleHeightRatio
    }

    static func consumedOutlineOffset(forCanvasHeight canvasHeight: CGFloat) -> CGFloat {
        min(2, max(0.75, canvasHeight * 0.035))
    }

    private static let consumedOutlineColor = Color.primary

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

private struct LifeHelmetIconView: View {
    let assetName: String
    let bundle: Bundle
    let canvasSize: CGSize
    let outlineColor: Color
    let isConsumed: Bool

    private static let consumedOpacity: Double = 0.3
    private static let outlineDirections: [OutlineDirection] = [
        OutlineDirection(id: 0, xMultiplier: -1, yMultiplier: 0),
        OutlineDirection(id: 1, xMultiplier: 1, yMultiplier: 0),
        OutlineDirection(id: 2, xMultiplier: 0, yMultiplier: -1),
        OutlineDirection(id: 3, xMultiplier: 0, yMultiplier: 1),
        OutlineDirection(id: 4, xMultiplier: -1, yMultiplier: -1),
        OutlineDirection(id: 5, xMultiplier: -1, yMultiplier: 1),
        OutlineDirection(id: 6, xMultiplier: 1, yMultiplier: -1),
        OutlineDirection(id: 7, xMultiplier: 1, yMultiplier: 1),
    ]

    var body: some View {
        ZStack {
            if isConsumed {
                outlineLayer
                    .transition(.opacity)
            }
            helmetImage()
                .opacity(isConsumed ? Self.consumedOpacity : 1)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private var outlineLayer: some View {
        let offset = GameLivesStatusView.consumedOutlineOffset(forCanvasHeight: canvasSize.height)

        return ForEach(Self.outlineDirections) { direction in
            helmetImage(renderingMode: .template)
                .foregroundStyle(outlineColor)
                .offset(
                    x: offset * direction.xMultiplier,
                    y: offset * direction.yMultiplier
                )
        }
        .overlay {
            helmetImage(renderingMode: .template)
                .foregroundStyle(.black)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }

    private func helmetImage(renderingMode: Image.TemplateRenderingMode? = nil) -> some View {
        Image(decorative: assetName, bundle: bundle)
            .renderingMode(renderingMode)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private struct OutlineDirection: Identifiable {
        let id: Int
        let xMultiplier: CGFloat
        let yMultiplier: CGFloat
    }
}

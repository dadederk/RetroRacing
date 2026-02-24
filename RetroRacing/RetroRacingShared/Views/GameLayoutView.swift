//
//  GameLayoutView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI

struct GameLayoutView<GameArea: View>: View {
    let containerSize: CGSize
    let style: GameViewStyle
    let score: Int
    let lives: Int
    let showSpeedAlert: Bool
    let lifeAssetName: String
    let bundle: Bundle
    let leftButtonDown: Bool
    let rightButtonDown: Bool
    let directionButtonHeight: CGFloat
    let headerFont: Font
    let inputAdapter: GameInputAdapter?
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void
    let onTogglePause: () -> Void
    let onAppearSide: (CGFloat) -> Void
    let onResizeSide: (CGFloat) -> Void
    @ViewBuilder let gameArea: (CGFloat) -> GameArea

    #if os(macOS) || os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    @ScaledMetric(relativeTo: .body) private var speedAlertIconMinHeight: CGFloat = 56

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if useLandscapeLayout(containerSize: containerSize) {
                landscapeLayout
            } else {
                portraitLayout
            }
            if showSpeedAlert {
                speedAlertView
            }
        }
    }

    private func useLandscapeLayout(containerSize: CGSize) -> Bool {
        #if os(macOS) || os(iOS)
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.regular, _): return true
        case (_, .compact): return true
        case (.compact, .regular): return false
        default: return containerSize.width > containerSize.height
        }
        #else
        return containerSize.width > containerSize.height
        #endif
    }

    private var portraitLayout: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Spacer()
                gameAreaWithFullScreenTouch
                directionButtonsRow
                Spacer()
            }
            HStack {
                headerScoreLabel
                Spacer()
                headerLivesView
            }
            .padding(style.headerPadding)
        }
    }

    private var landscapeLayout: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                headerScoreLabel
                Spacer(minLength: 8)
                directionButtonImage(isLeft: true)
                    .frame(minWidth: 100, minHeight: 80)
                Spacer(minLength: 8)
            }
            .frame(width: 160)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            gameAreaWithFullScreenTouch
                .frame(maxWidth: .infinity)
            VStack(alignment: .trailing, spacing: 0) {
                headerLivesView
                Spacer(minLength: 8)
                directionButtonImage(isLeft: false)
                    .frame(minWidth: 100, minHeight: 80)
                Spacer(minLength: 8)
            }
            .frame(width: 160)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    private var gameAreaWithFullScreenTouch: some View {
        GameAreaContainer(
            inputAdapter: inputAdapter,
            onMoveLeft: onMoveLeft,
            onMoveRight: onMoveRight,
            onTogglePause: onTogglePause,
            onAppearSide: onAppearSide,
            onResizeSide: onResizeSide,
            content: gameArea
        )
    }

    private var headerScoreLabel: some View {
        Text(GameLocalizedStrings.format("score %lld", score))
            .font(headerFont)
            .foregroundStyle(.primary)
            .shadow(color: Color.primary.opacity(0.35), radius: 0.5)
            .accessibilityLabel(GameLocalizedStrings.format("score %lld", score))
    }

    private var headerLivesView: some View {
        HStack(spacing: 4) {
            Image(lifeAssetName, bundle: bundle)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: style.lifeIconSize, height: style.lifeIconSize)
                .accessibilityHidden(true)
            Text(GameLocalizedStrings.format("lives_count", lives))
                .font(headerFont)
                .foregroundStyle(.primary)
                .shadow(color: Color.primary.opacity(0.35), radius: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLivesLabel)
    }

    private func directionButtonImage(isLeft: Bool) -> some View {
        let isPressed = isLeft ? leftButtonDown : rightButtonDown
        let name = isPressed ? "ButtonDown" : "ButtonUp"
        return Image(name, bundle: bundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: directionButtonHeight)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var directionButtonsRow: some View {
        HStack(spacing: 0) {
            directionButtonImage(isLeft: true)
            directionButtonImage(isLeft: false)
        }
    }

    private var speedAlertView: some View {
        Group {
            if useLandscapeLayout(containerSize: containerSize) {
                VStack(alignment: .leading, spacing: 8) {
                    speedAlertImage
                    speedAlertText
                }
            } else {
                HStack(alignment: .center, spacing: 8) {
                    speedAlertImage
                    speedAlertText
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(combinedSpeedAlertAccessibilityLabel)
    }

    private var speedAlertImage: some View {
        Image("HeyHo", bundle: bundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: speedAlertIconMinHeight)
            .accessibilityLabel(GameLocalizedStrings.string("speed_alert_hey_ho"))
    }

    private var speedAlertText: some View {
        Text(GameLocalizedStrings.string("speed_increasing_alert"))
            .font(headerFont)
            .foregroundStyle(.primary)
            .shadow(color: Color.primary.opacity(0.35), radius: 0.5)
    }

    private var combinedSpeedAlertAccessibilityLabel: String {
        GameLocalizedStrings.string("speed_increase_announcement")
    }

    private var accessibilityLivesLabel: String {
        if lives == 1 {
            return GameLocalizedStrings.format("%lld life remaining", lives)
        }
        return GameLocalizedStrings.format("%lld lives remaining", lives)
    }
}

private struct GameAreaContainer<Content: View>: View {
    let inputAdapter: GameInputAdapter?
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void
    let onTogglePause: () -> Void
    let onAppearSide: (CGFloat) -> Void
    let onResizeSide: (CGFloat) -> Void
    let content: (CGFloat) -> Content

    #if os(macOS) || os(iOS)
    @FocusState private var isFocused: Bool
    #endif

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            content(side)
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(GameAreaKeyboardModifier(
                    inputAdapter: inputAdapter,
                    onMoveLeft: onMoveLeft,
                    onMoveRight: onMoveRight,
                    onTogglePause: onTogglePause
                ))
                .onAppear {
                    setFocusForGameArea()
                    onAppearSide(side)
                }
                .onChange(of: geo.size) { _, newSize in
                    let side = min(newSize.width, newSize.height)
                    onAppearSide(side)
                    onResizeSide(side)
                }
        }
        .aspectRatio(1, contentMode: .fit)
        #if os(macOS) || os(iOS)
        .focusable()
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
            AppLog.info(AppLog.game, "🎮 GameAreaContainer focus changed: \(newValue)")
        }
        #endif
    }

    #if os(macOS) || os(iOS)
    private func setFocusForGameArea() {
        AppLog.info(AppLog.game, "🎮 Setting focus for GameAreaContainer")
        isFocused = true
    }
    #else
    private func setFocusForGameArea() { }
    #endif
}

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
    let hideHUDFromAccessibility: Bool
    let leftButtonDown: Bool
    let rightButtonDown: Bool
    let directionButtonHeight: CGFloat
    let headerFont: Font
    let sharePlayOpponentName: String?
    let sharePlayOpponentScore: Int?
    let sharePlayOpponentLives: Int?
    let inputAdapter: GameInputAdapter?
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void
    let onKeyboardInput: () -> Void
    let onSwipeInput: () -> Void
    let onTogglePause: () -> Void
    let onAppearSide: (CGFloat) -> Void
    let onResizeSide: (CGFloat) -> Void
    @ViewBuilder let gameArea: (CGFloat) -> GameArea

    #if os(macOS) || os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var speedAlertIconMinHeight: CGFloat = 56
    @ScaledMetric(relativeTo: .body) private var lifeIconScale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if usesLandscapeLayout {
                landscapeLayout
            } else if usesRegularWidthWidePlayLayout {
                regularWidthWidePlayLayout
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
        case (.regular, .compact):
            // Wide but short (e.g. larger iPhone landscape): side-rail HUD + controls.
            return true
        case (.regular, _), (.compact, _):
            // Regular×regular (iPad/Mac) and any compact-width size: full-width top HUD.
            return false
        default:
            return containerSize.width > containerSize.height
        }
        #else
        return containerSize.width > containerSize.height
        #endif
    }

    /// Regular-width and wider-than-tall (iPad landscape / wide Mac): full-width HUD with
    /// direction buttons flanking the game square.
    private var usesRegularWidthWidePlayLayout: Bool {
        #if os(macOS) || os(iOS)
        horizontalSizeClass == .regular && containerSize.width > containerSize.height
        #else
        false
        #endif
    }

    private var portraitLayout: some View {
        VStack(spacing: 8) {
            gameHUDHeader

            if shouldVerticallyCenterPortraitPlayArea {
                Spacer(minLength: 0)
                portraitPlayArea
                Spacer(minLength: 0)
            } else {
                portraitPlayArea
            }
        }
    }

    private var portraitPlayArea: some View {
        VStack(spacing: 8) {
            gameAreaWithFullScreenTouch
                .frame(maxWidth: .infinity)
                .layoutPriority(1)

            if shouldVerticallyCenterPortraitPlayArea {
                directionButtonsRow
            } else {
                directionButtonsArea
            }
        }
    }

    /// Full-width score/lives header, with left/right controls centered beside the game square.
    private var regularWidthWidePlayLayout: some View {
        VStack(spacing: 8) {
            gameHUDHeader
            Spacer(minLength: 0)
            HStack(alignment: .center, spacing: 0) {
                directionButtonImage(isLeft: true)
                    .frame(width: landscapeControlsSideRailWidth, height: directionButtonHeight)
                    .padding(.horizontal, 8)
                gameAreaWithFullScreenTouch
                    .frame(maxWidth: .infinity)
                directionButtonImage(isLeft: false)
                    .frame(width: landscapeControlsSideRailWidth, height: directionButtonHeight)
                    .padding(.horizontal, 8)
            }
            Spacer(minLength: 0)
        }
    }

    private var gameHUDHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if shouldUseVerticalPortraitHeader {
                    VStack(alignment: .leading, spacing: 6) {
                        headerScoreLabel
                        headerLivesView
                    }
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        headerScoreLabel
                            .layoutPriority(1)
                        Spacer(minLength: 16)
                        headerLivesView
                            .layoutPriority(2)
                    }
                }
            }
            sharePlayOpponentHeaderRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, style.headerPadding)
        .padding(.top, style.headerPadding)
        .padding(.bottom, 4)
        .allowsHitTesting(false)
    }

    private var landscapeLayout: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                headerScoreLabel
                sharePlayOpponentHeaderRow
                Spacer(minLength: 8)
                directionButtonImage(isLeft: true)
                    .frame(minWidth: 100, minHeight: 80)
                Spacer(minLength: 8)
            }
            .frame(width: landscapeScoreSideRailWidth)
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
            .frame(width: landscapeControlsSideRailWidth)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    /// iPhone landscape side rails stay compact; regular-width layouts no longer use side rails.
    private var landscapeScoreSideRailWidth: CGFloat {
        160
    }

    private var landscapeControlsSideRailWidth: CGFloat {
        160
    }

    private var gameAreaWithFullScreenTouch: some View {
        GameAreaContainer(
            inputAdapter: inputAdapter,
            onMoveLeft: onMoveLeft,
            onMoveRight: onMoveRight,
            onKeyboardInput: onKeyboardInput,
            onSwipeInput: onSwipeInput,
            onTogglePause: onTogglePause,
            onAppearSide: onAppearSide,
            onResizeSide: onResizeSide,
            content: gameArea
        )
    }

    @ViewBuilder
    private var sharePlayOpponentHeaderRow: some View {
        if let sharePlayOpponentScore {
            HStack(spacing: 8) {
                Text(
                    GameLocalizedStrings.format(
                        "shareplay_score_row %@ %lld",
                        sharePlayOpponentScoreLabel,
                        Int64(sharePlayOpponentScore)
                    )
                )
                .font(headerFont)
                .foregroundStyle(.secondary)
                .lineLimit(shouldUseVerticalPortraitHeader ? nil : 1)
                .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                if let sharePlayOpponentLives {
                    sharePlayOpponentLivesView(lives: sharePlayOpponentLives)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                GameLocalizedStrings.format(
                    "shareplay_score_accessibility %@ %lld %lld",
                    sharePlayOpponentScoreLabel,
                    Int64(sharePlayOpponentScore),
                    Int64(sharePlayOpponentLives ?? 0)
                )
            )
            .accessibilityHidden(hideHUDFromAccessibility)
        }
    }

    private var sharePlayOpponentScoreLabel: String {
        if let sharePlayOpponentName = sanitizedSharePlayOpponentName {
            return sharePlayOpponentName
        }
        return GameLocalizedStrings.string("shareplay_opponent_score_fallback_label")
    }

    private var sanitizedSharePlayOpponentName: String? {
        guard let sharePlayOpponentName else { return nil }
        let trimmedName = sharePlayOpponentName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
    }

    private func sharePlayOpponentLivesView(lives: Int) -> some View {
        HStack(spacing: 4) {
            Image(lifeAssetName, bundle: bundle)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: style.lifeIconSize * lifeIconScale,
                    height: style.lifeIconSize * lifeIconScale
                )
                .saturation(0)
                .contrast(0.85)
                .opacity(0.72)
                .accessibilityHidden(true)
            Text(GameLocalizedStrings.format("lives_count", Int64(lives)))
                .font(headerFont)
                .foregroundStyle(.secondary)
        }
    }

    private var headerScoreLabel: some View {
        Text(headerScoreText)
            .font(headerFont)
            .foregroundStyle(.primary)
            .shadow(color: Color.primary.opacity(0.35), radius: 0.5)
            .lineLimit(scoreLabelLineLimit)
            .minimumScaleFactor(scoreLabelMinimumScaleFactor)
            .allowsTightening(scoreLabelAllowsTightening)
            .fixedSize(horizontal: false, vertical: scoreLabelAllowsVerticalExpansion)
            .multilineTextAlignment(.leading)
            .accessibilityLabel(headerScoreText)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityRespondsToUserInteraction(false)
            .accessibilityHidden(hideHUDFromAccessibility)
    }

    private var scoreLabelLineLimit: Int? {
        if shouldUseVerticalPortraitHeader { return nil }
        if usesLandscapeLayout { return nil }
        return 1
    }

    private var scoreLabelMinimumScaleFactor: CGFloat {
        if shouldUseVerticalPortraitHeader { return 1.0 }
        if usesLandscapeLayout { return 1.0 }
        return 0.75
    }

    private var scoreLabelAllowsTightening: Bool {
        if shouldUseVerticalPortraitHeader { return false }
        return !usesLandscapeLayout
    }

    private var scoreLabelAllowsVerticalExpansion: Bool {
        usesLandscapeLayout
    }

    private var headerScoreText: String {
        guard sharePlayOpponentScore != nil else {
            return GameLocalizedStrings.format("score %lld", Int64(score))
        }
        return GameLocalizedStrings.format("shareplay_your_score_row %lld", Int64(score))
    }

    private var headerLivesView: some View {
        HStack(spacing: 4) {
            Image(lifeAssetName, bundle: bundle)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: style.lifeIconSize * lifeIconScale,
                    height: style.lifeIconSize * lifeIconScale
                )
                .accessibilityHidden(true)
            Text(GameLocalizedStrings.format("lives_count", Int64(lives)))
                .font(headerFont)
                .foregroundStyle(.primary)
                .shadow(color: Color.primary.opacity(0.35), radius: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLivesLabel)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityRespondsToUserInteraction(false)
        .accessibilityHidden(hideHUDFromAccessibility)
    }

    private func directionButtonImage(isLeft: Bool) -> some View {
        let isPressed = isLeft ? leftButtonDown : rightButtonDown
        let name = isPressed ? "ButtonDown" : "ButtonUp"
        return Image(name, bundle: bundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: directionButtonHeight, alignment: .center)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var directionButtonsArea: some View {
        directionButtonsRow
            .frame(
                maxWidth: .infinity,
                minHeight: directionButtonHeight,
                maxHeight: .infinity,
                alignment: .center
            )
    }

    private var directionButtonsRow: some View {
        HStack(alignment: .center, spacing: 0) {
            directionButtonImage(isLeft: true)
            directionButtonImage(isLeft: false)
        }
        .frame(height: directionButtonHeight, alignment: .center)
    }

    private var speedAlertView: some View {
        Group {
            if usesLandscapeLayout {
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
        .accessibilityRespondsToUserInteraction(false)
        .accessibilityHidden(hideHUDFromAccessibility)
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

    private var shouldUseVerticalPortraitHeader: Bool {
        // Regular × regular (iPad / typical Mac): always keep score and lives on one full-width
        // row. Compact-width layouts may still stack at large Dynamic Type.
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

    private var usesLandscapeLayout: Bool {
        useLandscapeLayout(containerSize: containerSize)
    }

    /// Regular-width taller-than-wide (iPad portrait / tall Mac): pin the full-width HUD and
    /// vertically center the game square + direction buttons underneath.
    private var shouldVerticallyCenterPortraitPlayArea: Bool {
        #if os(macOS) || os(iOS)
        horizontalSizeClass == .regular && usesRegularWidthWidePlayLayout == false
        #else
        false
        #endif
    }

    private var accessibilityLivesLabel: String {
        if lives == 1 {
            return GameLocalizedStrings.format("%lld life remaining", Int64(lives))
        }
        return GameLocalizedStrings.format("%lld lives remaining", Int64(lives))
    }
}

private struct GameAreaContainer<Content: View>: View {
    let inputAdapter: GameInputAdapter?
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void
    let onKeyboardInput: () -> Void
    let onSwipeInput: () -> Void
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
                    onKeyboardInput: onKeyboardInput,
                    onSwipeInput: onSwipeInput,
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
            AppLog.debug(
                AppLog.input + AppLog.game,
                "GAME_AREA_FOCUS_CHANGED",
                outcome: .completed,
                fields: [.bool("isFocused", newValue)]
            )
        }
        #endif
    }

    #if os(macOS) || os(iOS)
    private func setFocusForGameArea() {
        AppLog.debug(
            AppLog.input + AppLog.game,
            "GAME_AREA_FOCUS_SET",
            outcome: .requested
        )
        isFocused = true
    }
    #else
    private func setFocusForGameArea() { }
    #endif
}

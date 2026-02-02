//
//  GameView+Layout.swift
//  RetroRacing
//

import SwiftUI
import RetroRacingShared

extension GameView {

    /// Uses size classes when available (iPad split screen, multi-window); falls back to size comparison (e.g. macOS).
    func useLandscapeLayout(containerSize: CGSize) -> Bool {
        #if os(macOS) || os(iOS)
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.regular, _): return true   // Wide: use side-by-side layout (e.g. iPad, split view)
        case (_, .compact): return true    // Short: use side-by-side (e.g. landscape, slide over)
        case (.compact, .regular): return false  // Tall and narrow: use stacked layout (e.g. phone portrait)
        default: return containerSize.width > containerSize.height  // Fallback when size classes unavailable
        }
        #else
        return containerSize.width > containerSize.height
        #endif
    }

    func headerFont(size: CGFloat = 14) -> Font {
        fontPreferenceStore?.font(size: size) ?? .custom("PressStart2P-Regular", size: size)
    }

    func headerScoreLabel() -> some View {
        Text(GameLocalizedStrings.format("score %lld", score))
            .font(headerFont(size: 14))
            .foregroundStyle(.primary)
            .shadow(color: Color.primary.opacity(0.35), radius: 0.5)
            .accessibilityLabel(GameLocalizedStrings.format("score %lld", score))
    }

    func headerLivesView() -> some View {
        let lifeAsset = theme?.lifeSprite() ?? "life"
        return HStack(spacing: 4) {
            Image(lifeAsset, bundle: Self.sharedBundle)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
            Text(GameLocalizedStrings.format("lives_count", lives))
                .font(headerFont(size: 14))
                .foregroundStyle(.primary)
                .shadow(color: Color.primary.opacity(0.35), radius: 0.5)
                .accessibilityLabel(GameLocalizedStrings.format("%lld lives remaining", lives))
        }
    }

    @ViewBuilder
    func portraitLayout(containerSize: CGSize) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Spacer()
                gameAreaWithFullScreenTouch()
                directionButtonsRow()
                Spacer()
            }
            HStack {
                headerScoreLabel()
                Spacer()
                headerLivesView()
            }
            .padding()
        }
    }

    @ViewBuilder
    func landscapeLayout(containerSize: CGSize) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                headerScoreLabel()
                Spacer(minLength: 8)
                directionButtonImage(isLeft: true)
                    .frame(minWidth: 100, minHeight: 80)
                Spacer(minLength: 8)
            }
            .frame(width: 160)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            gameAreaWithFullScreenTouch()
                .frame(maxWidth: .infinity)
            VStack(alignment: .trailing, spacing: 0) {
                headerLivesView()
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

    private func directionButtonImage(isLeft: Bool) -> some View {
        let name = (isLeft ? leftButtonDown : rightButtonDown) ? "ButtonDown" : "ButtonUp"
        return Image(name, bundle: Self.sharedBundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: directionButtonHeight)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func directionButtonsRow() -> some View {
        HStack(spacing: 0) {
            directionButtonImage(isLeft: true)
            directionButtonImage(isLeft: false)
        }
    }
}

//
//  MenuContentView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI

struct MenuContentView: View {
    let style: MenuViewStyle
    let fontPreferenceStore: FontPreferenceStore
    let showRateButton: Bool
    let showSupportButton: Bool
    let isLeaderboardEnabled: Bool
    @Binding var authError: String?
    let onPlay: () -> Void
    let onLeaderboard: () -> Void
    let onRate: () -> Void
    let onSupport: () -> Void

    var body: some View {
        VStack(spacing: style.menuSpacing) {
            titleView
            buttonsStack
        }
    }

    @ViewBuilder
    private var titleView: some View {
        if style.allowsDynamicType {
            Text(GameLocalizedStrings.string("gameName"))
                .font(fontPreferenceStore.font(textStyle: .largeTitle))
                .dynamicTypeSize(.xSmall ... .xxxLarge)
                .padding(.top, style.titleTopPadding)
                .padding(.bottom, style.titleBottomPadding)
                .accessibilityAddTraits(.isHeader)
        } else {
            Text(GameLocalizedStrings.string("gameName"))
                .font(fontPreferenceStore.font(fixedSize: style.titleFontSize))
                .padding(.top, style.titleTopPadding)
                .padding(.bottom, style.titleBottomPadding)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var buttonsStack: some View {
        VStack(spacing: style.buttonSpacing) {
            menuPlayButton
            menuLeaderboardButton
            if showRateButton || showSupportButton {
                engagementButtons
            }
        }
    }

    private var engagementButtons: some View {
        VStack(spacing: style.buttonSpacing) {
            Divider()
                .padding([.top, .leading, .trailing])
            Text(GameLocalizedStrings.string(showSupportButton ? "menu_engagement_prompt" : "menu_engagement_prompt_rate_only"))
                .font(promptFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            if showRateButton {
                menuRateButton
            }
            if showSupportButton {
                menuSupportButton
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSupportButton)
    }

    private var buttonFont: Font {
        style.allowsDynamicType
            ? fontPreferenceStore.font(textStyle: .headline)
            : fontPreferenceStore.font(fixedSize: style.buttonFontSize)
    }

    private var promptFont: Font {
        style.allowsDynamicType
            ? fontPreferenceStore.font(textStyle: .footnote)
            : fontPreferenceStore.font(fixedSize: max(12, style.buttonFontSize - 4))
    }

    private var menuPlayButton: some View {
        Button {
            onPlay()
        } label: {
            Text(GameLocalizedStrings.string("play"))
                .font(buttonFont)
        }
        .retroRacingPrimaryButtonStyle()
        .controlSize(.large)
    }

    private var menuLeaderboardButton: some View {
        Button {
            authError = nil
            onLeaderboard()
        } label: {
            Text(GameLocalizedStrings.string("leaderboard"))
                .font(buttonFont)
        }
        .retroRacingSecondaryButtonStyle()
        .disabled(!isLeaderboardEnabled)
        .alert(authError ?? "", isPresented: Binding(
            get: { authError != nil },
            set: { _ in authError = nil }
        )) {
            Button(GameLocalizedStrings.string("ok"), role: .cancel) {}
        }
    }

    private var menuRateButton: some View {
        Button {
            onRate()
        } label: {
            Text(GameLocalizedStrings.string("menu_rate_game"))
                .font(buttonFont)
        }
        .retroRacingSecondaryButtonStyle()
    }

    private var menuSupportButton: some View {
        Button {
            onSupport()
        } label: {
            Text(GameLocalizedStrings.string("menu_support_game"))
                .font(buttonFont)
        }
        .retroRacingSecondaryButtonStyle()
    }
}

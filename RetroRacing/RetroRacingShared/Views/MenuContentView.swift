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
    let isLeaderboardEnabled: Bool
    @Binding var authError: String?
    let onPlay: () -> Void
    let onLeaderboard: () -> Void
    let onRate: () -> Void

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
                .padding(.bottom, style.titleBottomPadding)
                .accessibilityAddTraits(.isHeader)
        } else {
            Text(GameLocalizedStrings.string("gameName"))
                .font(fontPreferenceStore.font(fixedSize: style.titleFontSize))
                .padding(.bottom, style.titleBottomPadding)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var buttonsStack: some View {
        VStack(spacing: style.buttonSpacing) {
            menuPlayButton
            menuLeaderboardButton
            if showRateButton {
                menuRateButton
            }
        }
    }

    private var buttonFont: Font {
        style.allowsDynamicType
            ? fontPreferenceStore.font(textStyle: .headline)
            : fontPreferenceStore.font(fixedSize: style.buttonFontSize)
    }

    private var menuPlayButton: some View {
        Button {
            onPlay()
        } label: {
            Text(GameLocalizedStrings.string("play"))
                .font(buttonFont)
        }
        .buttonStyle(.glassProminent)
    }

    private var menuLeaderboardButton: some View {
        Button {
            authError = nil
            onLeaderboard()
        } label: {
            Text(GameLocalizedStrings.string("leaderboard"))
                .font(buttonFont)
        }
        .buttonStyle(.glass)
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
            Text(GameLocalizedStrings.string("rateApp"))
                .font(buttonFont)
        }
        .buttonStyle(.glass)
    }
}

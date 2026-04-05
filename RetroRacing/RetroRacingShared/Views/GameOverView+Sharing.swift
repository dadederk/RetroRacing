//
//  GameOverView+Sharing.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import SwiftUI

#if !os(watchOS)
extension GameOverView {
    @ViewBuilder
    var shareToolbarItem: some View {
        if let gameOverShareImageURL {
            ShareLink(item: gameOverShareImageURL) {
                Label(GameLocalizedStrings.string("share_action"), systemImage: "square.and.arrow.up")
                    .font(bodyFont)
            }
            .accessibilityLabel(GameLocalizedStrings.string("share_action"))
        } else {
            Button(action: refreshShareImage) {
                Label(GameLocalizedStrings.string("share_action"), systemImage: "square.and.arrow.up")
                    .font(bodyFont)
            }
            .disabled(true)
        }
    }

    var shareContentView: some View {
        ShareCardCanvas(colorScheme: colorScheme) {
            VStack(spacing: 28) {
                ShareCardGameTitle(font: fontPreferenceStore?.font(textStyle: .largeTitle) ?? .largeTitle)
                gameOverShareCard
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 1200, height: 900)
    }

    var gameOverShareCard: some View {
        VStack(spacing: 20) {
            Image(isNewRecord ? "NewRecord" : "Finished", bundle: Self.sharedBundle)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 560)
                .accessibilityHidden(true)

            subtitleText
            scoreRows
            speedRow
            socialRows
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    func refreshShareImage() {
        gameOverShareImageURL = ShareImageSnapshotService.renderToTemporaryPNGURL(
            fileName: Self.shareImageFileName,
            colorScheme: colorScheme
        ) {
            shareContentView
        }
    }
}
#endif

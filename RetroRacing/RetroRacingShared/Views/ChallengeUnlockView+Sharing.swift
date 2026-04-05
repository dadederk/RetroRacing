//
//  ChallengeUnlockView+Sharing.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import SwiftUI

#if !os(watchOS)
extension ChallengeUnlockView {
    @ViewBuilder
    var shareToolbarItem: some View {
        if let shareImageURL {
            ShareLink(item: shareImageURL) {
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
                challengeShareCard
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 1200, height: 900)
    }

    var challengeShareCard: some View {
        VStack(spacing: 16) {
            challengeArtwork(maxWidth: 460)

            Text(GameLocalizedStrings.string("challenge_modal_title"))
                .font(scoreFont)
                .multilineTextAlignment(.center)

            Text(GameLocalizedStrings.string("challenge_modal_subtitle"))
                .font(bodyFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            challengeUnlockedRows
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    func refreshShareImage() {
        shareImageURL = ShareImageSnapshotService.renderToTemporaryPNGURL(
            fileName: Self.shareImageFileName,
            colorScheme: colorScheme
        ) {
            shareContentView
        }
    }
}
#endif

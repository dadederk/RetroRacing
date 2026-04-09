//
//  AchievementUnlockView+Sharing.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import SwiftUI

#if !os(watchOS) && !os(tvOS)
extension AchievementUnlockView {
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
            .accessibilityLabel(GameLocalizedStrings.string("share_action"))
        }
    }

    var shareContentView: some View {
        ShareCardCanvas(colorScheme: colorScheme) {
            VStack(spacing: 28) {
                ShareCardGameTitle(font: fontPreferenceStore?.font(textStyle: .largeTitle) ?? .largeTitle)
                achievementShareCard
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 1200, height: 900)
    }

    var achievementShareCard: some View {
        VStack(spacing: 16) {
            achievementArtwork(maxWidth: 460)

            Text(GameLocalizedStrings.string("achievement_modal_title"))
                .font(scoreFont)
                .multilineTextAlignment(.center)

            Text(primaryAchievementSubtitle)
                .font(bodyFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            achievementUnlockedRows
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

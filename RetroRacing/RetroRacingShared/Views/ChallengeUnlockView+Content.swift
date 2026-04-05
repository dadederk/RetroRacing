//
//  ChallengeUnlockView+Content.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import SwiftUI

extension ChallengeUnlockView {
    var challengeMainContent: some View {
        VStack(spacing: 18) {
            challengeArtwork(maxWidth: 250)

            Text(GameLocalizedStrings.string("challenge_modal_title"))
                .font(scoreFont)
                .multilineTextAlignment(.center)

            Text(GameLocalizedStrings.string("challenge_modal_subtitle"))
                .font(bodyFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            challengeUnlockedRows

            Button(action: onDone) {
                Text(GameLocalizedStrings.string("done"))
                    .font(buttonFont)
            }
            .retroRacingPrimaryButtonStyle()
            .padding(.top, 2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    var challengeUnlockedRows: some View {
        VStack(spacing: 6) {
            ForEach(Array(challengeIDs.prefix(3)), id: \.rawValue) { challengeID in
                Text(challengeID.localizedTitle)
                    .font(bodyFont)
                    .multilineTextAlignment(.center)
            }

            let hiddenCount = challengeIDs.count - 3
            if hiddenCount > 0 {
                Text(GameLocalizedStrings.format("challenge_modal_more %lld", Int64(hiddenCount)))
                    .font(bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    func challengeArtwork(maxWidth: CGFloat) -> some View {
        Image(challengeArtworkAssetName, bundle: Self.sharedBundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: maxWidth)
            .accessibilityHidden(true)
    }

    var challengeArtworkAssetName: String {
        ChallengeArtworkCatalog.assetName(for: challengeIDs.first, bundle: Self.sharedBundle)
    }

    var bodyFont: Font {
        fontPreferenceStore?.font(textStyle: .body) ?? .body
    }

    var scoreFont: Font {
        fontPreferenceStore?.font(textStyle: .headline) ?? .headline
    }

    var buttonFont: Font {
        fontPreferenceStore?.font(textStyle: .headline) ?? .headline
    }
}

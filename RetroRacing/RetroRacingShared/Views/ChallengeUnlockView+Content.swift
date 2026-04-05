//
//  ChallengeUnlockView+Content.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import SwiftUI
#if canImport(GameKit) && (os(iOS) || os(macOS))
import GameKit
#endif

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
            challengeActionButtons
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

    var challengeActionButtons: some View {
        VStack(spacing: 10) {
            Button(action: onDone) {
                Text(GameLocalizedStrings.string("done"))
                    .font(buttonFont)
            }
            .retroRacingPrimaryButtonStyle()

            if canOpenGameCenterChallenges {
                Button(action: openGameCenterChallenges) {
                    Text(GameLocalizedStrings.string("challenge_modal_other_challenges"))
                        .font(buttonFont)
                }
                .retroRacingSecondaryButtonStyle()
            }
        }
        .padding(.top, 2)
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

    var canOpenGameCenterChallenges: Bool {
        #if os(iOS) || os(macOS)
        true
        #else
        false
        #endif
    }

    func openGameCenterChallenges() {
        #if canImport(GameKit) && (os(iOS) || os(macOS))
        if #available(iOS 26.0, macOS 26.0, *) {
            GKAccessPoint.shared.triggerForChallenges {
                AppLog.info(AppLog.game + AppLog.challenge + AppLog.leaderboard, "🏅 Opened Game Center challenges from challenge modal")
            }
        }
        #endif
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

//
//  AchievementUnlockView+Content.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import SwiftUI
#if canImport(GameKit) && (os(iOS) || os(macOS))
import GameKit
#endif

extension AchievementUnlockView {
    var achievementMainContent: some View {
        VStack(spacing: 18) {
            achievementArtwork(maxWidth: 250)

            Text(GameLocalizedStrings.string("achievement_modal_title"))
                .font(scoreFont)
                .multilineTextAlignment(.center)

            Text(primaryAchievementSubtitle)
                .font(bodyFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            achievementUnlockedRows
            if !usesBottomActionBar {
                achievementActionButtons
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    /// Uses the Game Center achieved description for the first unlocked achievement when available,
    /// falling back to the generic modal subtitle if GC metadata has not loaded yet.
    var primaryAchievementSubtitle: String {
        if let first = achievementIDs.first,
           let description = gcMetadata[first.rawValue]?.achievedDescription,
           description.isEmpty == false {
            return description
        }
        return GameLocalizedStrings.string("achievement_modal_subtitle")
    }

    var achievementUnlockedRows: some View {
        VStack(spacing: 6) {
            ForEach(Array(achievementIDs.prefix(3)), id: \.rawValue) { achievementID in
                Text(gcMetadata[achievementID.rawValue]?.title ?? achievementID.localizedTitle)
                    .font(bodyFont)
                    .multilineTextAlignment(.center)
            }

            let hiddenCount = achievementIDs.count - 3
            if hiddenCount > 0 {
                Text(GameLocalizedStrings.format("achievement_modal_more %lld", Int64(hiddenCount)))
                    .font(bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    var achievementActionButtons: some View {
        achievementActionButtonsContent
            .padding(.top, 2)
    }

    #if os(iOS) || os(visionOS)
    var bottomActionBar: some View {
        BottomActionBar {
            achievementActionButtonsContent
        }
    }
    #endif

    private var achievementActionButtonsContent: some View {
        VStack(spacing: 10) {
            Button(action: onDone) {
                Text(GameLocalizedStrings.string("done"))
                    .font(buttonFont)
            }
            .retroRacingPrimaryButtonStyle()

            if canOpenGameCenterAchievements {
                Button(action: openGameCenterAchievements) {
                    Text(GameLocalizedStrings.string("achievement_modal_other_achievements"))
                        .font(buttonFont)
                }
                .retroRacingSecondaryButtonStyle()
            }
        }
    }

    func achievementArtwork(maxWidth: CGFloat) -> some View {
        Image(achievementArtworkAssetName, bundle: Self.sharedBundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: maxWidth)
            .accessibilityHidden(true)
    }

    var achievementArtworkAssetName: String {
        AchievementArtworkCatalog.assetName(for: achievementIDs.first, bundle: Self.sharedBundle)
    }

    var canOpenGameCenterAchievements: Bool {
        #if os(iOS) || os(macOS)
        true
        #else
        false
        #endif
    }

    func openGameCenterAchievements() {
        #if canImport(GameKit) && (os(iOS) || os(macOS))
        if #available(iOS 26.0, macOS 26.0, *) {
            GKAccessPoint.shared.trigger(state: .achievements) {
                AppLog.info(AppLog.game + AppLog.achievement + AppLog.leaderboard, "🏅 Opened Game Center achievements from achievement modal")
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
        fontPreferenceStore?.font(textStyle: .body) ?? .body
    }
}

//
//  AchievementUnlockView+Content.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
#if canImport(GameKit) && (os(iOS) || os(macOS))
import GameKit
#endif

extension AchievementUnlockView {
    var achievementMainContent: some View {
        VStack(spacing: achievementContentSpacing) {
            achievementArtwork(maxWidth: achievementArtworkMaxWidth)

            #if os(watchOS)
            Text(GameLocalizedStrings.string("achievement_modal_title"))
                .font(bodyFont)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
            #endif

            Text(achievementTitle)
                .font(scoreFont)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.65)

            Text(achievementDescription)
                .font(bodyFont)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .minimumScaleFactor(0.65)

            if !usesBottomActionBar {
                achievementActionButtons
            }
        }
        .padding(achievementContentPadding)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    /// Uses the Game Center title when available, falling back to the local computed title.
    var achievementTitle: String {
        gcMetadata[achievementID.rawValue]?.title ?? achievementID.localizedTitle
    }

    /// Uses the Game Center achieved description when available,
    /// falling back to the local ASC-aligned achieved description.
    var achievementDescription: String {
        if let description = gcMetadata[achievementID.rawValue]?.achievedDescription,
           description.isEmpty == false {
            return description
        }
        return achievementID.localizedAchievedDescription
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
        Group {
            if let artworkImage = achievementArtworkImage(from: gcArtworkPNGData) {
                artworkImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(achievementArtworkAssetName, bundle: Self.sharedBundle)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .frame(maxWidth: maxWidth)
        .accessibilityHidden(true)
        .animation(.easeInOut(duration: 0.2), value: gcArtworkPNGData != nil)
    }

    func achievementArtworkImage(from pngData: Data?) -> Image? {
        guard let pngData else { return nil }
        #if os(iOS) || os(tvOS) || os(visionOS)
        guard let image = UIImage(data: pngData) else { return nil }
        return Image(uiImage: image)
        #elseif os(macOS)
        guard let image = NSImage(data: pngData) else { return nil }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }

    var achievementArtworkAssetName: String {
        AchievementArtworkCatalog.assetName(for: achievementID, bundle: Self.sharedBundle)
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
                AppLog.info(
                    AppLog.achievement + AppLog.leaderboard,
                    "ACHIEVEMENT_MODAL_OPEN_GAME_CENTER",
                    outcome: .requested
                )
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

    var achievementContentSpacing: CGFloat {
        #if os(watchOS)
        8
        #else
        18
        #endif
    }

    var achievementContentPadding: CGFloat {
        #if os(watchOS)
        10
        #else
        20
        #endif
    }

    var achievementArtworkMaxWidth: CGFloat {
        #if os(watchOS)
        125
        #else
        250
        #endif
    }
}

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
            #if os(watchOS)
            Text(GameLocalizedStrings.string("achievement_modal_title"))
                .appFont(.body)
                .multilineTextAlignment(.center)
            #elseif os(tvOS)
            Text(GameLocalizedStrings.string("achievement_modal_title"))
                .appFont(.largeTitle)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .accessibilityAddTraits(.isHeader)
            #endif

            achievementArtwork(maxWidth: achievementArtworkMaxWidth)

            Text(achievementTitle)
                .appFont(achievementTitleTextStyle)
                .multilineTextAlignment(.center)

            Text(achievementDescription)
                .appFont(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if !usesBottomActionBar {
                achievementActionButtons
            }
        }
        .padding(.horizontal, achievementHorizontalContentPadding)
        .padding(.vertical, achievementVerticalContentPadding)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    /// Uses the Game Center title when available, falling back to the local computed title.
    var achievementTitle: String {
        gcMetadata[achievementID.rawValue]?.title ?? achievementID.localizedTitle
    }

    var achievementTitleTextStyle: Font.TextStyle {
        #if os(tvOS)
        .title2
        #else
        .headline
        #endif
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

    #if os(iOS) || os(tvOS) || os(visionOS)
    var bottomActionBar: some View {
        BottomActionBar {
            achievementActionButtonsContent
        }
    }
    #endif

    @ViewBuilder
    private var achievementActionButtonsContent: some View {
        #if os(tvOS)
        doneButton
            .frame(maxWidth: 520)
        #else
        VStack(spacing: 10) {
            doneButton

            if canOpenGameCenterAchievements {
                Button(action: openGameCenterAchievements) {
                    Text(GameLocalizedStrings.string("achievement_modal_other_achievements"))
                        .appFont(.body)
                }
                .retroRacingSecondaryButtonStyle()
                .bottomActionBarLargeContentViewer()
            }
        }
        #endif
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text(GameLocalizedStrings.string("done"))
                .appFont(.body)
                .frame(maxWidth: .infinity)
        }
        .retroRacingPrimaryButtonStyle()
        .bottomActionBarLargeContentViewer()
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

    var achievementContentSpacing: CGFloat {
        #if os(watchOS)
        8
        #else
        18
        #endif
    }

    var achievementHorizontalContentPadding: CGFloat {
        #if os(tvOS)
        72
        #elseif os(watchOS)
        10
        #else
        20
        #endif
    }

    var achievementVerticalContentPadding: CGFloat {
        #if os(watchOS)
        10
        #elseif os(tvOS)
        32
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

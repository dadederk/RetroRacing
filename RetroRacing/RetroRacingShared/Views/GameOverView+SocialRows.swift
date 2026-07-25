//
//  GameOverView+SocialRows.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 05/04/2026.
//

import SwiftUI
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct GameOverSocialFriendScoreRow: View {
    let displayName: String
    let score: Int
    let avatarPNGData: Data?
    let avatarSize: CGFloat
    let bodyFont: Font
    let scoreFont: Font
    /// Matches the in-race friend-milestone badge: grey road-line ring around the avatar.
    var showsMilestoneRing: Bool = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Warm gray matching the default LCD road-line tint used by in-race friend markers.
    private static let milestoneRingColor = Color(
        red: 140 / 255,
        green: 134 / 255,
        blue: 121 / 255
    )

    var body: some View {
        let layout: AnyLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 6))
            : AnyLayout(HStackLayout(spacing: 8))

        return layout {
            avatar
            Text(GameLocalizedStrings.format("game_over_friend_score %@ %lld", displayName, Int64(score)))
                .font(scoreFont.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GameLocalizedStrings.format("game_over_friend_score %@ %lld", displayName, Int64(score)))
    }

    private var avatar: some View {
        let content = avatarContent
            .frame(width: avatarContentSize, height: avatarContentSize)
            .clipShape(Circle())

        return Group {
            if showsMilestoneRing {
                ZStack {
                    Circle()
                        .fill(Self.milestoneRingColor)
                    content
                }
                .frame(width: avatarSize, height: avatarSize)
            } else {
                content
                    .frame(width: avatarSize, height: avatarSize)
            }
        }
        .accessibilityHidden(true)
    }

    private var avatarContentSize: CGFloat {
        guard showsMilestoneRing else { return avatarSize }
        return avatarSize * (1 - (FriendMilestoneConfiguration.avatarInsetFactor * 2))
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let avatarImage = avatarImage(from: avatarPNGData) {
            avatarImage
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Circle()
                .fill(Color.secondary.opacity(0.18))
                .overlay {
                    Text(initials(for: displayName))
                        .font(bodyFont)
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func avatarImage(from avatarPNGData: Data?) -> Image? {
        guard let avatarPNGData else { return nil }
        #if os(iOS) || os(tvOS) || os(visionOS)
        guard let image = UIImage(data: avatarPNGData) else { return nil }
        return Image(uiImage: image)
        #elseif os(macOS)
        guard let image = NSImage(data: avatarPNGData) else { return nil }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }

    private func initials(for displayName: String) -> String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return "?" }
        let parts = trimmed.split(separator: " ").filter { $0.isEmpty == false }
        if parts.count >= 2,
           let first = parts.first?.first,
           let second = parts.dropFirst().first?.first {
            return String([first, second]).uppercased()
        }
        if let first = parts.first?.first {
            return String(first).uppercased()
        }
        return "?"
    }
}

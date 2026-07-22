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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        Group {
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
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())
        .accessibilityHidden(true)
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

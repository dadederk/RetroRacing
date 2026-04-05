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

extension GameOverView {
    func socialFriendScoreRow(
        displayName: String,
        score: Int,
        avatarPNGData: Data?
    ) -> some View {
        HStack(spacing: 8) {
            socialFriendAvatar(avatarPNGData: avatarPNGData, displayName: displayName)
            Text(GameLocalizedStrings.format("game_over_friend_score %@ %lld", displayName, Int64(score)))
                .font(scoreFont.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GameLocalizedStrings.format("game_over_friend_score %@ %lld", displayName, Int64(score)))
    }

    func socialFriendAvatar(avatarPNGData: Data?, displayName: String) -> some View {
        Group {
            if let avatarImage = socialFriendAvatarImage(from: avatarPNGData) {
                avatarImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Circle()
                    .fill(Color.secondary.opacity(0.18))
                    .overlay {
                        Text(friendAvatarInitials(for: displayName))
                            .font(bodyFont)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 24, height: 24)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    func socialFriendAvatarImage(from avatarPNGData: Data?) -> Image? {
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

    func friendAvatarInitials(for displayName: String) -> String {
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

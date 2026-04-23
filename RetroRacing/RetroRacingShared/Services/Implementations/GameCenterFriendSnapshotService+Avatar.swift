//
//  GameCenterFriendSnapshotService+Avatar.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 05/04/2026.
//

import Foundation
import GameKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension GameCenterFriendSnapshotService {
#if !os(watchOS)
    @available(iOS 14.0, tvOS 14.0, macOS 11.0, *)
    func loadAvatarDataIfAvailable(for player: GKPlayer, playerID: String) async -> Data? {
        let data: Data? = await withCheckedContinuation { continuation in
            player.loadPhoto(for: .normal, withCompletionHandler: { photo, error in
                if let error {
                    AppLog.error(
                        AppLog.leaderboard + AppLog.game,
                        "FRIEND_AVATAR_LOAD",
                        outcome: .failed,
                        fields: [
                            .reason("gamekit_error"),
                            .string("playerID", AppLog.redactedPlayer(playerID))
                        ] + AppLog.Field.error(error)
                    )
                    continuation.resume(returning: nil)
                    return
                }

                guard let photo else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: Self.serializedAvatarData(from: photo))
            })
        }

        guard let data else {
            return nil
        }

        await avatarCache.cache(data, for: playerID)
        return data
    }
#endif

#if canImport(UIKit)
    static func serializedAvatarData(from image: UIImage) -> Data? {
        image.pngData()
    }
#elseif canImport(AppKit)
    static func serializedAvatarData(from image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
#else
    static func serializedAvatarData(from image: Any) -> Data? {
        nil
    }
#endif
}

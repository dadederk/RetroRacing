//
//  AchievementArtworkCatalog.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

enum AchievementArtworkCatalog {
    static let fallbackAssetName = "AchievementDefault"

    static func assetName(
        for achievementID: AchievementIdentifier?,
        bundle: Bundle = Bundle(for: GameScene.self)
    ) -> String {
        guard let achievementID else { return fallbackAssetName }

        let candidates: [String] = [
            achievementID.rawValue,
            achievementID.rawValue.replacingOccurrences(of: ".", with: "_"),
            achievementID.rawValue.replacingOccurrences(of: ".", with: "-"),
            "Achievement_\(achievementID.rawValue)",
            fallbackAssetName
        ]

        for candidate in candidates where hasImageAsset(named: candidate, bundle: bundle) {
            return candidate
        }

        return fallbackAssetName
    }

    private static func hasImageAsset(named name: String, bundle: Bundle) -> Bool {
        #if os(macOS)
        return bundle.image(forResource: NSImage.Name(name)) != nil
        #elseif os(watchOS)
        return UIImage(named: name) != nil
        #elseif canImport(UIKit)
        return UIImage(named: name, in: bundle, compatibleWith: nil) != nil
        #else
        return false
        #endif
    }
}

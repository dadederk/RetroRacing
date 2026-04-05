//
//  ChallengeArtworkCatalog.swift
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

enum ChallengeArtworkCatalog {
    static let fallbackAssetName = "ChallengeDefault"

    static func assetName(
        for challengeID: ChallengeIdentifier?,
        bundle: Bundle = Bundle(for: GameScene.self)
    ) -> String {
        guard let challengeID else { return fallbackAssetName }

        let candidates: [String] = [
            challengeID.rawValue,
            challengeID.rawValue.replacingOccurrences(of: ".", with: "_"),
            challengeID.rawValue.replacingOccurrences(of: ".", with: "-"),
            "Challenge_\(challengeID.rawValue)",
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

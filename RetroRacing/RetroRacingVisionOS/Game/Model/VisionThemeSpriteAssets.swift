//
//  VisionThemeSpriteAssets.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation
import RetroRacingShared

enum VisionThemeSpriteAssets {
    static let bundle = Bundle(for: GameScene.self)

    static func crashAssetName(for theme: any GameTheme) -> String {
        return theme.crashSprite() ?? "crash-LCD"
    }
}

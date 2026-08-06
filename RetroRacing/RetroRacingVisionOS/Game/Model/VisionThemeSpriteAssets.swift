//
//  VisionThemeSpriteAssets.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation
import RetroRacingShared

enum VisionThemeSpriteAssets {
    static func bundle(for theme: any GameTheme) -> Bundle {
        theme.id == .sixtyFourBit ? .main : Bundle(for: GameScene.self)
    }

    static func crashAssetName(for theme: any GameTheme) -> String {
        guard theme.id != .sixtyFourBit else {
            return theme.playerCarSprite() ?? "playersCar-LCD"
        }
        return theme.crashSprite() ?? "crash-LCD"
    }
}

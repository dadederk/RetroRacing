//
//  PlatformFactories.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 17/02/2026.
//

import Foundation

/// Central place for allowed process-wide singletons. Use only at composition roots.
public enum InfrastructureDefaults {
    public static let userDefaults: UserDefaults = .standard
    public static let randomSource: RandomSource = SystemRandomSource()
}

/// Composition-root factories for shared services used across platforms.
public enum PlatformFactories {
    public static func makeImageLoader() -> any ImageLoader {
        #if canImport(AppKit) && !os(iOS)
        return AppKitImageLoader()
        #else
        return UIKitImageLoader()
        #endif
    }

    public static func makeSoundPlayer() -> SoundEffectPlayer {
        AVSoundEffectPlayer(bundle: Bundle(for: GameScene.self))
    }

    public static func makeLaneCuePlayer() -> LaneCuePlayer {
        AVLaneCuePlayer()
    }
}

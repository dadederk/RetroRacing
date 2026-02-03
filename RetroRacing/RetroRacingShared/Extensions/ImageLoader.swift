//
//  ImageLoader.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import SpriteKit
import AVFoundation

/// Loads sprite textures from bundles while hiding UIKit/AppKit differences from shared game code.
public protocol ImageLoader {
    func loadTexture(imageNamed name: String, bundle: Bundle) -> SKTexture
}

#if canImport(UIKit)
import UIKit

/// Image loader for UIKit platforms.
/// - Note: `init()` uses `NSCacheTextureCache.shared` as a process-wide default cache.
public final class UIKitImageLoader: ImageLoader {
    private let textureCache: TextureCache

    public init(textureCache: TextureCache) {
        self.textureCache = textureCache
    }

    public convenience init() {
        self.init(textureCache: NSCacheTextureCache.shared)
    }

    public func loadTexture(imageNamed name: String, bundle: Bundle) -> SKTexture {
        if let cached = textureCache.texture(forKey: name) {
            AppLog.log(AppLog.assets, "texture '\(name)' loaded from cache")
            return cached
        }
        // Prefer asset catalog (playersCar, rivalsCar, crash) — url(forResource:...) does not find .xcassets images.
        // UIImage(named:in:compatibleWith:) is unavailable on watchOS, so we only use it on iOS/tvOS.
        #if !os(watchOS)
        if let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
            AppLog.log(AppLog.assets, "texture '\(name)' loaded from asset catalog")
            let texture = SKTexture(image: image)
            textureCache.store(texture, forKey: name)
            return texture
        }
        #endif
        // Fallback: flat PNG in bundle (e.g. Resources/Sprites/).
        guard let url = urlForSprite(named: name, in: bundle) else {
            AppLog.error(AppLog.assets, "texture '\(name)' NOT FOUND in bundle \(bundle.bundleURL.lastPathComponent)")
            return SKTexture()
        }
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            AppLog.error(AppLog.assets, "texture '\(name)' failed to load from \(url.path)")
            return SKTexture()
        }
        AppLog.log(AppLog.assets, "texture '\(name)' loaded from bundle file")
        let texture = SKTexture(image: image)
        textureCache.store(texture, forKey: name)
        return texture
    }

    private func urlForSprite(named name: String, in bundle: Bundle) -> URL? {
        bundle.url(forResource: name, withExtension: "png", subdirectory: "Sprites")
            ?? bundle.url(forResource: name, withExtension: "png", subdirectory: "Resources/Sprites")
            ?? bundle.url(forResource: name, withExtension: "png")
    }
}
#elseif canImport(AppKit)
import AppKit

/// Image loader for AppKit platforms.
/// - Note: `init()` uses `NSCacheTextureCache.shared` as a process-wide default cache.
public final class AppKitImageLoader: ImageLoader {
    private let textureCache: TextureCache

    public init(textureCache: TextureCache) {
        self.textureCache = textureCache
    }

    public convenience init() {
        self.init(textureCache: NSCacheTextureCache.shared)
    }

    public func loadTexture(imageNamed name: String, bundle: Bundle) -> SKTexture {
        if let cached = textureCache.texture(forKey: name) {
            AppLog.log(AppLog.assets, "texture '\(name)' loaded from cache")
            return cached
        }
        if let image = bundle.image(forResource: NSImage.Name(name)) {
            AppLog.log(AppLog.assets, "texture '\(name)' loaded from asset catalog")
            let texture = SKTexture(image: image)
            textureCache.store(texture, forKey: name)
            return texture
        }
        // Fallback: flat PNG in bundle (e.g. Resources/Sprites/).
        guard let url = urlForSprite(named: name, in: bundle) else {
            AppLog.error(AppLog.assets, "texture '\(name)' NOT FOUND in bundle \(bundle.bundleURL.lastPathComponent)")
            return SKTexture()
        }
        guard let image = NSImage(contentsOf: url) else {
            AppLog.error(AppLog.assets, "texture '\(name)' failed to load from \(url.path)")
            return SKTexture()
        }
        AppLog.log(AppLog.assets, "texture '\(name)' loaded from bundle file")
        let texture = SKTexture(image: image)
        textureCache.store(texture, forKey: name)
        return texture
    }

    private func urlForSprite(named name: String, in bundle: Bundle) -> URL? {
        bundle.url(forResource: name, withExtension: "png", subdirectory: "Sprites")
            ?? bundle.url(forResource: name, withExtension: "png", subdirectory: "Resources/Sprites")
            ?? bundle.url(forResource: name, withExtension: "png")
    }
}
#endif

// MARK: - Infrastructure defaults and factories

/// Central place for allowed process-wide singletons. Use only at composition roots.
public enum InfrastructureDefaults {
    public static let userDefaults: UserDefaults = .standard
    public static let randomSource: RandomSource = SystemRandomSource()
}

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
}

//
//  ImageLoader.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import SpriteKit

/// Loads sprite textures from bundles while hiding UIKit/AppKit differences from shared game code.
public protocol ImageLoader {
    func loadTexture(imageNamed name: String, bundle: Bundle) -> SKTexture?
}

private func textureCacheKey(name: String, bundle: Bundle) -> String {
    let bundleIdentity = bundle.bundleIdentifier ?? bundle.bundleURL.standardizedFileURL.path
    return "\(bundleIdentity)::\(name)"
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

    public func loadTexture(imageNamed name: String, bundle: Bundle) -> SKTexture? {
        let cacheKey = textureCacheKey(name: name, bundle: bundle)
        if let cached = textureCache.texture(forKey: cacheKey) {
            AppLog.debug(AppLog.assets, "TEXTURE_LOAD", outcome: .succeeded, fields: [.string("source", "cache"), .string("assetName", name)])
            return cached
        }
        if let image = UIImage(named: name, in: bundle, with: nil) {
            AppLog.debug(AppLog.assets, "TEXTURE_LOAD", outcome: .succeeded, fields: [.string("source", "asset_catalog"), .string("assetName", name)])
            let texture = SKTexture(image: image)
            textureCache.store(texture, forKey: cacheKey)
            return texture
        }
        AppLog.error(AppLog.assets, "TEXTURE_LOAD", outcome: .failed, fields: [.reason("asset_not_found"), .string("assetName", name), .string("bundle", bundle.bundleURL.lastPathComponent)])
        return nil
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

    public func loadTexture(imageNamed name: String, bundle: Bundle) -> SKTexture? {
        let cacheKey = textureCacheKey(name: name, bundle: bundle)
        if let cached = textureCache.texture(forKey: cacheKey) {
            AppLog.debug(AppLog.assets, "TEXTURE_LOAD", outcome: .succeeded, fields: [.string("source", "cache"), .string("assetName", name)])
            return cached
        }
        if let image = bundle.image(forResource: NSImage.Name(name)) {
            AppLog.debug(AppLog.assets, "TEXTURE_LOAD", outcome: .succeeded, fields: [.string("source", "asset_catalog"), .string("assetName", name)])
            let texture = SKTexture(image: image)
            textureCache.store(texture, forKey: cacheKey)
            return texture
        }
        AppLog.error(AppLog.assets, "TEXTURE_LOAD", outcome: .failed, fields: [.reason("asset_not_found"), .string("assetName", name), .string("bundle", bundle.bundleURL.lastPathComponent)])
        return nil
    }
}
#endif

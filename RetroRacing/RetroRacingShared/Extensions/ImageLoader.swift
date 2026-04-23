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
            AppLog.debug(AppLog.assets, "TEXTURE_LOAD", outcome: .succeeded, fields: [.string("source", "cache"), .string("assetName", name)])
            return cached
        }
        // Prefer asset catalog (playersCar, rivalsCar, crash) — url(forResource:...) does not find .xcassets images.
        #if os(watchOS)
        // On watchOS, use UIKit's available name-based lookup.
        if let image = UIImage(named: name) {
            AppLog.debug(AppLog.assets, "TEXTURE_LOAD", outcome: .succeeded, fields: [.string("source", "asset_catalog_watch"), .string("assetName", name)])
            let texture = SKTexture(image: image)
            textureCache.store(texture, forKey: name)
            return texture
        }
        #else
        if let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
            AppLog.debug(AppLog.assets, "TEXTURE_LOAD", outcome: .succeeded, fields: [.string("source", "asset_catalog"), .string("assetName", name)])
            let texture = SKTexture(image: image)
            textureCache.store(texture, forKey: name)
            return texture
        }
        #endif
        // Fallback: flat PNG in bundle (e.g. Resources/Sprites/).
        guard let url = urlForSprite(named: name, in: bundle) else {
            AppLog.error(AppLog.assets, "TEXTURE_LOAD", outcome: .failed, fields: [.reason("asset_not_found"), .string("assetName", name), .string("bundle", bundle.bundleURL.lastPathComponent)])
            return SKTexture()
        }
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            AppLog.error(AppLog.assets, "TEXTURE_LOAD", outcome: .failed, fields: [.reason("bundle_file_decode_failed"), .string("assetName", name), .string("path", AppLog.redactedPath(url.path))])
            return SKTexture()
        }
        AppLog.debug(AppLog.assets, "TEXTURE_LOAD", outcome: .succeeded, fields: [.string("source", "bundle_file"), .string("assetName", name)])
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
            AppLog.debug(AppLog.assets, "TEXTURE_LOAD", outcome: .succeeded, fields: [.string("source", "cache"), .string("assetName", name)])
            return cached
        }
        if let image = bundle.image(forResource: NSImage.Name(name)) {
            AppLog.debug(AppLog.assets, "TEXTURE_LOAD", outcome: .succeeded, fields: [.string("source", "asset_catalog"), .string("assetName", name)])
            let texture = SKTexture(image: image)
            textureCache.store(texture, forKey: name)
            return texture
        }
        // Fallback: flat PNG in bundle (e.g. Resources/Sprites/).
        guard let url = urlForSprite(named: name, in: bundle) else {
            AppLog.error(AppLog.assets, "TEXTURE_LOAD", outcome: .failed, fields: [.reason("asset_not_found"), .string("assetName", name), .string("bundle", bundle.bundleURL.lastPathComponent)])
            return SKTexture()
        }
        guard let image = NSImage(contentsOf: url) else {
            AppLog.error(AppLog.assets, "TEXTURE_LOAD", outcome: .failed, fields: [.reason("bundle_file_decode_failed"), .string("assetName", name), .string("path", AppLog.redactedPath(url.path))])
            return SKTexture()
        }
        AppLog.debug(AppLog.assets, "TEXTURE_LOAD", outcome: .succeeded, fields: [.string("source", "bundle_file"), .string("assetName", name)])
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

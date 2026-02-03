//
//  TextureCache.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import SpriteKit

public protocol TextureCache {
    func texture(forKey key: String) -> SKTexture?
    func store(_ texture: SKTexture, forKey key: String)
    func removeAll()
}

/// NSCache-backed texture cache.
/// - Note: `shared` is a process-wide default cache and is an allowed infrastructure singleton.
public final class NSCacheTextureCache: TextureCache {
    private let cache: NSCache<NSString, SKTexture>

    public static let shared: NSCacheTextureCache = {
        let cache = NSCache<NSString, SKTexture>()
        cache.countLimit = 32
        return NSCacheTextureCache(cache: cache)
    }()

    public init(cache: NSCache<NSString, SKTexture>) {
        self.cache = cache
    }

    public convenience init(countLimit: Int) {
        let cache = NSCache<NSString, SKTexture>()
        cache.countLimit = countLimit
        self.init(cache: cache)
    }

    public func texture(forKey key: String) -> SKTexture? {
        cache.object(forKey: NSString(string: key))
    }

    public func store(_ texture: SKTexture, forKey key: String) {
        cache.setObject(texture, forKey: NSString(string: key))
    }

    public func removeAll() {
        cache.removeAllObjects()
    }
}

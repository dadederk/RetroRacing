//
//  GameSceneTextureFallbackTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 03/08/2026.
//

import SpriteKit
import XCTest
@testable import RetroRacingShared

@MainActor
final class GameSceneTextureFallbackTests: XCTestCase {
    func testGivenMissingRequestedTextureWhenFallbackExistsThenLCDTextureIsReturned() {
        // Given
        let fallbackTexture = SKTexture()
        let loader = TextureFallbackImageLoader(textures: ["playersCar-LCD": fallbackTexture])
        let scene = GameScene(size: CGSize(width: 100, height: 100))
        scene.imageLoader = loader

        // When
        let result = scene.texture(
            imageNamed: "missing-theme-player",
            fallbackImageNamed: "playersCar-LCD"
        )

        // Then
        XCTAssertTrue(result === fallbackTexture)
        XCTAssertEqual(loader.requestedNames, ["missing-theme-player", "playersCar-LCD"])
    }

    func testGivenFallbackResolutionWhenLoadingAgainThenSceneDoesNotRepeatMissingLookup() {
        // Given
        let fallbackTexture = SKTexture()
        let loader = TextureFallbackImageLoader(textures: ["playersCar-LCD": fallbackTexture])
        let scene = GameScene(size: CGSize(width: 100, height: 100))
        scene.imageLoader = loader

        // When
        let first = scene.texture(
            imageNamed: "missing-theme-player",
            fallbackImageNamed: "playersCar-LCD"
        )
        let second = scene.texture(
            imageNamed: "missing-theme-player",
            fallbackImageNamed: "playersCar-LCD"
        )

        // Then
        XCTAssertTrue(first === fallbackTexture)
        XCTAssertTrue(second === fallbackTexture)
        XCTAssertEqual(loader.requestedNames, ["missing-theme-player", "playersCar-LCD"])
    }

    func testGivenRequestedTextureExistsWhenLoadingThenFallbackIsNotRequested() {
        // Given
        let requestedTexture = SKTexture()
        let loader = TextureFallbackImageLoader(textures: ["custom-player": requestedTexture])
        let scene = GameScene(size: CGSize(width: 100, height: 100))
        scene.imageLoader = loader

        // When
        let result = scene.texture(
            imageNamed: "custom-player",
            fallbackImageNamed: "playersCar-LCD"
        )

        // Then
        XCTAssertTrue(result === requestedTexture)
        XCTAssertEqual(loader.requestedNames, ["custom-player"])
    }

    func testGivenRequestedAndFallbackTexturesAreMissingWhenLoadingThenEmptyTextureIsReturned() {
        // Given
        let loader = TextureFallbackImageLoader(textures: [:])
        let scene = GameScene(size: CGSize(width: 100, height: 100))
        scene.imageLoader = loader

        // When
        let result = scene.texture(
            imageNamed: "missing-theme-crash",
            fallbackImageNamed: "crash-LCD"
        )

        // Then
        XCTAssertEqual(result.size(), .zero)
        XCTAssertEqual(loader.requestedNames, ["missing-theme-crash", "crash-LCD"])
    }

    func testGivenFailedResolutionWhenAssetBecomesAvailableThenSceneRetriesAndSucceeds() {
        // Given
        let recoveredTexture = SKTexture()
        let loader = TextureFallbackImageLoader(textures: [:])
        let scene = GameScene(size: CGSize(width: 100, height: 100))
        scene.imageLoader = loader
        _ = scene.texture(
            imageNamed: "recovering-theme-crash",
            fallbackImageNamed: "crash-LCD"
        )

        // When
        loader.setTexture(recoveredTexture, for: "recovering-theme-crash")
        let recovered = scene.texture(
            imageNamed: "recovering-theme-crash",
            fallbackImageNamed: "crash-LCD"
        )

        // Then
        XCTAssertTrue(recovered === recoveredTexture)
        XCTAssertEqual(
            loader.requestedNames,
            ["recovering-theme-crash", "crash-LCD", "recovering-theme-crash"]
        )
    }

    func testGivenSuccessfulPlatformLoadWhenLoadingAgainThenTextureComesFromBundleScopedCache() throws {
        // Given
        let cache = RecordingTextureCache()
        #if canImport(UIKit)
        let loader = UIKitImageLoader(textureCache: cache)
        #elseif canImport(AppKit)
        let loader = AppKitImageLoader(textureCache: cache)
        #endif
        let bundle = Bundle(for: GameScene.self)

        // When
        let first = try XCTUnwrap(loader.loadTexture(imageNamed: "playersCar-LCD", bundle: bundle))
        let second = try XCTUnwrap(loader.loadTexture(imageNamed: "playersCar-LCD", bundle: bundle))

        // Then
        XCTAssertTrue(first === second)
        XCTAssertEqual(cache.storedKeys.count, 1)
        XCTAssertEqual(Set(cache.requestedKeys).count, 1)
        XCTAssertTrue(cache.requestedKeys[0].contains("playersCar-LCD"))
    }

    func testGivenFailedPlatformLoadWhenLoadingAgainThenFailureIsNotCached() {
        // Given
        let cache = RecordingTextureCache()
        #if canImport(UIKit)
        let loader = UIKitImageLoader(textureCache: cache)
        #elseif canImport(AppKit)
        let loader = AppKitImageLoader(textureCache: cache)
        #endif
        let missingName = "texture-that-does-not-exist"

        // When
        let first = loader.loadTexture(imageNamed: missingName, bundle: Bundle(for: GameScene.self))
        let second = loader.loadTexture(imageNamed: missingName, bundle: Bundle(for: GameScene.self))

        // Then
        XCTAssertNil(first)
        XCTAssertNil(second)
        XCTAssertTrue(cache.storedKeys.isEmpty)
        XCTAssertEqual(cache.requestedKeys.count, 2)
    }
}

private final class TextureFallbackImageLoader: ImageLoader {
    private var textures: [String: SKTexture]
    private(set) var requestedNames: [String] = []

    init(textures: [String: SKTexture]) {
        self.textures = textures
    }

    func loadTexture(imageNamed name: String, bundle: Bundle) -> SKTexture? {
        requestedNames.append(name)
        return textures[name]
    }

    func setTexture(_ texture: SKTexture, for name: String) {
        textures[name] = texture
    }
}

private final class RecordingTextureCache: TextureCache {
    private var textures: [String: SKTexture] = [:]
    private(set) var requestedKeys: [String] = []
    private(set) var storedKeys: [String] = []

    func texture(forKey key: String) -> SKTexture? {
        requestedKeys.append(key)
        return textures[key]
    }

    func store(_ texture: SKTexture, forKey key: String) {
        storedKeys.append(key)
        textures[key] = texture
    }

    func removeAll() {
        textures.removeAll()
    }
}

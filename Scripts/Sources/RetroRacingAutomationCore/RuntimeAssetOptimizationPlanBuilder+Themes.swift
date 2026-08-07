//
//  RuntimeAssetOptimizationPlanBuilder+Themes.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

extension RuntimeAssetOptimizationActionBuilder {
    mutating func addThemeSprites() {
        let spriteVariants = platformSpriteVariants(standard: 768, mac: 1_024, watch: 256, tv: 512)
        let lifeVariants = platformSpriteVariants(standard: 256, mac: 256, watch: 64, tv: 256)
        for definition in spriteDefinitions {
            var variants = definition.isLife ? lifeVariants : spriteVariants
            if definition.sources["vision"] != nil {
                variants.append(visionSpriteVariant(maximumLongEdge: definition.isLife ? 256 : 768))
            }
            addSpriteImageset(
                path: definition.path,
                sources: definition.sources,
                variants: variants
            )
        }
    }

    private mutating func addSpriteImageset(
        path: String,
        sources: [String: URL],
        variants: [RuntimeAssetOptimizationVariant]
    ) {
        let destinationDirectory = destinationDirectory(for: path)
        actions.append(.clearPNGs(directory: destinationDirectory))
        let baseName = assetBaseName(for: path)
        let images = variants.compactMap { variant -> AssetCatalogImage? in
            guard let sourceKey = variant.sourceKey,
                  let source = sources[sourceKey] else { return nil }
            let filename = "\(baseName)-\(variant.name).png"
            actions.append(
                .render(
                    source: source,
                    destination: "\(destinationDirectory)/\(filename)",
                    maximumLongEdge: variant.maximumLongEdge
                )
            )
            return AssetCatalogImage(
                filename: filename,
                idiom: variant.idiom,
                platform: variant.platform,
                scale: variant.scale
            )
        }
        actions.append(
            .writeContents(
                destination: "\(destinationDirectory)/Contents.json",
                contents: AssetCatalogContents(
                    images: images,
                    info: AssetCatalogInfo(author: "xcode", version: 1)
                )
            )
        )
    }

    private func platformSpriteVariants(
        standard: Int,
        mac: Int,
        watch: Int,
        tv: Int
    ) -> [RuntimeAssetOptimizationVariant] {
        [
            RuntimeAssetOptimizationVariant(name: "iphone", idiom: "iphone", sourceKey: "iphone", maximumLongEdge: standard),
            RuntimeAssetOptimizationVariant(name: "ipad", idiom: "ipad", sourceKey: "ipad", maximumLongEdge: standard),
            RuntimeAssetOptimizationVariant(name: "mac", idiom: "mac", sourceKey: "mac", maximumLongEdge: mac),
            RuntimeAssetOptimizationVariant(name: "tv", idiom: "tv", sourceKey: "tv", maximumLongEdge: tv),
            RuntimeAssetOptimizationVariant(name: "watch", idiom: "watch", sourceKey: "watch", maximumLongEdge: watch),
        ]
    }

    private func visionSpriteVariant(maximumLongEdge: Int) -> RuntimeAssetOptimizationVariant {
        RuntimeAssetOptimizationVariant(
            name: "vision",
            idiom: "universal",
            platform: "visionos",
            sourceKey: "vision",
            maximumLongEdge: maximumLongEdge
        )
    }

    private var spriteDefinitions: [(path: String, sources: [String: URL], isLife: Bool)] {
        [
            ("Sprites/LCD/playersCar-LCD.imageset", currentPlayerSources(theme: "LCD", baseName: "playersCar-LCD"), false),
            ("Sprites/LCD/rivalsCar-LCD.imageset", legacySpriteSources(path: "Sprites/LCD/rivalsCar-LCD.imageset", universal: "RivalCar2.png", watch: "RivalCar2 1.png", tv: "RivalCar2 2.png"), false),
            ("Sprites/LCD/crash-LCD.imageset", legacySpriteSources(path: "Sprites/LCD/crash-LCD.imageset", universal: "CRASH.png", watch: "CRASH 1.png", tv: "CRASH 2.png"), false),
            ("Sprites/LCD/life-LCD.imageset", legacySpriteSources(path: "Sprites/LCD/life-LCD.imageset", universal: "LIVES.png", watch: "LIVES 1.png", tv: "LIVES 2.png", currentWatch: "LCD/life-LCD-watch.png"), true),
            ("Sprites/LCD/friendLife-LCD.imageset", curatedCatalogSources(path: "Sprites/LCD/friendLife-LCD.imageset"), true),
            ("Sprites/GameBoy/playersCar-GameBoy.imageset", currentPlayerSources(theme: "GameBoy", baseName: "playersCar-GameBoy"), false),
            ("Sprites/GameBoy/rivalsCar-GameBoy.imageset", legacySpriteSources(path: "Sprites/GameBoy/rivalsCar-GameBoy.imageset", universal: "rivalsCar-GameBoy.png", watch: "rivalsCar-GameBoy 1.png", tv: "rivalsCar-GameBoy 2.png"), false),
            ("Sprites/GameBoy/crash-GameBoy.imageset", legacySpriteSources(path: "Sprites/GameBoy/crash-GameBoy.imageset", universal: "crash-GameBoy.png", watch: "crash-GameBoy 1.png", tv: "crash-GameBoy 2.png"), false),
            ("Sprites/GameBoy/life-GameBoy.imageset", legacySpriteSources(path: "Sprites/GameBoy/life-GameBoy.imageset", universal: "life-GameBoy.png", watch: "life-GameBoy 1.png", tv: "life-GameBoy 2.png", currentWatch: "GameBoy/life-GameBoy-watch.png"), true),
            ("Sprites/GameBoy/friendLife-GameBoy.imageset", curatedCatalogSources(path: "Sprites/GameBoy/friendLife-GameBoy.imageset"), true),
            ("Sprites/8Bit/playersCar-8Bit.imageset", eightBitPlayerSources(), false),
            ("Sprites/8Bit/rivalsCar-8Bit.imageset", legacySpriteSources(path: "Sprites/8Bit/rivalsCar-8Bit.imageset", universal: "rivalsCar-8Bit.png", watch: "rivalsCar-8Bit 1.png", tv: "rivalsCar-8Bit 2.png"), false),
            ("Sprites/8Bit/crash-8Bit.imageset", legacySpriteSources(path: "Sprites/8Bit/crash-8Bit.imageset", universal: "crash-8Bit.png", watch: "crash-8Bit 1.png", tv: "crash-8Bit 2.png"), false),
            ("Sprites/8Bit/life-8Bit.imageset", legacySpriteSources(path: "Sprites/8Bit/life-8Bit.imageset", universal: "life-8Bit.png", watch: "life-8Bit 1.png", tv: "life-8Bit 2.png", currentWatch: "8Bit/life-8Bit-watch.png"), true),
            ("Sprites/8Bit/friendLife-8Bit.imageset", curatedCatalogSources(path: "Sprites/8Bit/friendLife-8Bit.imageset"), true),
            ("Sprites/16Bit/playersCar-16Bit.imageset", curatedCatalogSources(path: "Sprites/16Bit/playersCar-16Bit.imageset"), false),
            ("Sprites/16Bit/rivalsCar-16Bit.imageset", curatedCatalogSources(path: "Sprites/16Bit/rivalsCar-16Bit.imageset"), false),
            ("Sprites/16Bit/crash-16Bit.imageset", curatedCatalogSources(path: "Sprites/16Bit/crash-16Bit.imageset"), false),
            ("Sprites/16Bit/life-16Bit.imageset", curatedCatalogSources(path: "Sprites/16Bit/life-16Bit.imageset"), true),
            ("Sprites/16Bit/friendLife-16Bit.imageset", curatedCatalogSources(path: "Sprites/16Bit/friendLife-16Bit.imageset"), true),
            ("Sprites/32Bit/playersCar-32Bit.imageset", thirtyTwoBitCatalogSources(path: "Sprites/32Bit/playersCar-32Bit.imageset"), false),
            ("Sprites/32Bit/rivalsCar-32Bit.imageset", thirtyTwoBitCatalogSources(path: "Sprites/32Bit/rivalsCar-32Bit.imageset"), false),
            ("Sprites/32Bit/crash-32Bit.imageset", thirtyTwoBitCatalogSources(path: "Sprites/32Bit/crash-32Bit.imageset"), false),
            ("Sprites/32Bit/life-32Bit.imageset", thirtyTwoBitCatalogSources(path: "Sprites/32Bit/life-32Bit.imageset"), true),
            ("Sprites/32Bit/friendLife-32Bit.imageset", thirtyTwoBitCatalogSources(path: "Sprites/32Bit/friendLife-32Bit.imageset"), true),
            ("Sprites/64Bit/playersCar-64Bit.imageset", sixtyFourBitCatalogSources(path: "Sprites/64Bit/playersCar-64Bit.imageset"), false),
            ("Sprites/64Bit/rivalsCar-64Bit.imageset", sixtyFourBitCatalogSources(path: "Sprites/64Bit/rivalsCar-64Bit.imageset"), false),
            ("Sprites/64Bit/crash-64Bit.imageset", sixtyFourBitCatalogSources(path: "Sprites/64Bit/crash-64Bit.imageset"), false),
            ("Sprites/64Bit/life-64Bit.imageset", sixtyFourBitCatalogSources(path: "Sprites/64Bit/life-64Bit.imageset"), true),
            ("Sprites/64Bit/friendLife-64Bit.imageset", sixtyFourBitCatalogSources(path: "Sprites/64Bit/friendLife-64Bit.imageset"), true),
        ]
    }

    private func currentPlayerSources(theme: String, baseName: String) -> [String: URL] {
        let root = runtimeMasters20260803Root.appending(path: theme)
        return playerSources(root: root, baseName: baseName)
    }

    private func eightBitPlayerSources() -> [String: URL] {
        playerSources(
            root: runtimeMasters20260804Root.appending(path: "8Bit"),
            baseName: "playersCar-8Bit"
        )
    }

    private func playerSources(root: URL, baseName: String) -> [String: URL] {
        reusingIPadSourceOnVision([
            "iphone": root.appending(path: "\(baseName)-iphone.png"),
            "ipad": root.appending(path: "\(baseName)-iphone.png"),
            "mac": root.appending(path: "\(baseName)-mac.png"),
            "tv": root.appending(path: "\(baseName)-tv.png"),
            "watch": root.appending(path: "\(baseName)-watch.png"),
        ])
    }

    private func curatedCatalogSources(path: String) -> [String: URL] {
        let root = runtimeMasters20260803Root.appending(path: "CuratedCatalog/\(path)")
        let baseName = assetBaseName(for: path)
        let sources = Dictionary(uniqueKeysWithValues: ["iphone", "ipad", "mac", "tv", "watch"].map {
            ($0, root.appending(path: "\(baseName)-\($0).png"))
        })
        return reusingIPadSourceOnVision(sources)
    }

    private func thirtyTwoBitCatalogSources(path: String) -> [String: URL] {
        let root = runtimeMasters20260805Root.appending(path: "CuratedCatalog/\(path)")
        let baseName = assetBaseName(for: path)
        let sources = Dictionary(uniqueKeysWithValues: ["iphone", "ipad", "mac", "tv", "watch"].map {
            ($0, root.appending(path: "\(baseName)-\($0).png"))
        })
        return reusingIPadSourceOnVision(sources)
    }

    private func sixtyFourBitCatalogSources(path: String) -> [String: URL] {
        let root = runtimeMasters20260806Root.appending(path: "CuratedCatalog/\(path)")
        let baseName = assetBaseName(for: path)
        var sources = reusingIPadSourceOnVision(Dictionary(
            uniqueKeysWithValues: ["iphone", "ipad", "mac", "tv", "watch"].map {
                ($0, root.appending(path: "\(baseName)-\($0).png"))
            }
        ))
        switch baseName {
        case "playersCar-64Bit":
            sources["vision"] = repositoryRoot.appending(
                path: "AssetSources/VisionOS64BitPrototype2026-08-05/PlayerCar/Previews/player-car-64bit-sprite.png"
            )
        case "rivalsCar-64Bit":
            sources["vision"] = runtimeMasters20260806Root.appending(
                path: "CuratedVisionOS/rivalsCar-64Bit.png"
            )
        default:
            // Polygon's crash and helmet art is renderer-neutral. Reusing the curated iPad
            // master gives visionOS an explicit asset-catalog idiom without runtime fallback.
            sources["vision"] = sources["ipad"]
        }
        return sources
    }

    private func legacySpriteSources(
        path: String,
        universal: String,
        watch: String,
        tv: String,
        currentWatch: String? = nil
    ) -> [String: URL] {
        let root = sourceCatalog.appending(path: path)
        let universalURL = root.appending(path: universal)
        return reusingIPadSourceOnVision([
            "iphone": universalURL,
            "ipad": universalURL,
            "mac": universalURL,
            "tv": root.appending(path: tv),
            "watch": currentWatch.map { runtimeMasters20260803Root.appending(path: $0) }
                ?? root.appending(path: watch),
        ])
    }

    private func reusingIPadSourceOnVision(_ sources: [String: URL]) -> [String: URL] {
        var platformSources = sources
        // Classic visionOS uses the shared fixed-camera renderer. Reuse the curated iPad
        // source unless a theme supplies a dedicated visionOS projection.
        platformSources["vision"] = sources["ipad"]
        return platformSources
    }
}

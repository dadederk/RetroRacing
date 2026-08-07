//
//  RuntimeAssetOptimizationPlanBuilder+Catalog.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

extension RuntimeAssetOptimizationActionBuilder {
    mutating func addSharedResultAssets() {
        let variants = [
            RuntimeAssetOptimizationVariant(name: "iphone-2x", idiom: "iphone", scale: "2x", maximumLongEdge: 512),
            RuntimeAssetOptimizationVariant(name: "iphone-3x", idiom: "iphone", scale: "3x", maximumLongEdge: 768),
            RuntimeAssetOptimizationVariant(name: "ipad-2x", idiom: "ipad", scale: "2x", maximumLongEdge: 512),
            RuntimeAssetOptimizationVariant(name: "mac-1x", idiom: "mac", scale: "1x", maximumLongEdge: 256),
            RuntimeAssetOptimizationVariant(name: "mac-2x", idiom: "mac", scale: "2x", maximumLongEdge: 512),
        ]
        for name in ["WinWithFriend", "LoseWithFriend", "Tie", "Rematch", "ConnectionLost"] {
            addImageset(
                path: "\(name).imageset",
                sourceFilename: "\(name).png",
                variants: variants,
                properties: ["template-rendering-intent": "original"]
            )
        }
    }

    mutating func addTemplateIcons() {
        let variants = [
            RuntimeAssetOptimizationVariant(name: "iphone-1x", idiom: "iphone", scale: "1x", maximumLongEdge: 96),
            RuntimeAssetOptimizationVariant(name: "iphone-2x", idiom: "iphone", scale: "2x", maximumLongEdge: 192),
            RuntimeAssetOptimizationVariant(name: "iphone-3x", idiom: "iphone", scale: "3x", maximumLongEdge: 256),
            RuntimeAssetOptimizationVariant(name: "ipad-1x", idiom: "ipad", scale: "1x", maximumLongEdge: 96),
            RuntimeAssetOptimizationVariant(name: "ipad-2x", idiom: "ipad", scale: "2x", maximumLongEdge: 192),
            RuntimeAssetOptimizationVariant(name: "mac-1x", idiom: "mac", scale: "1x", maximumLongEdge: 96),
            RuntimeAssetOptimizationVariant(name: "mac-2x", idiom: "mac", scale: "2x", maximumLongEdge: 192),
        ]
        for name in ["GetReady", "WaitingForFriendToFinish", "WaitingForFriendToJoin"] {
            addImageset(
                path: "Icons/\(name).imageset",
                sourceFilename: "\(name).png",
                variants: variants
            )
        }
    }

    mutating func addProfileAndControlAssets() {
        addImageset(
            path: "profilePicRetroRapid.imageset",
            sourceFilename: "profilePicRetroRapid.png",
            variants: scaledVariants(baseLongEdge: 160, maximum3xLongEdge: 480, includesTV: true)
        )
        let variants = scaledVariants(baseLongEdge: 256, maximum3xLongEdge: 768, includesTV: true)
        for (path, source) in [
            ("Sprites/ButtonUp.imageset", "ButtonUp.png"),
            ("Sprites/ButtonDown.imageset", "ButtonDown.png"),
            ("Sprites/HeyHo.imageset", "HeyHo.png"),
        ] {
            addImageset(path: path, sourceFilename: source, variants: variants)
        }
    }

    mutating func addUnscaledPlatformAssets() {
        for (name, maximumLongEdge) in [
            ("Finished", 858),
            ("NewRecord", 710),
            ("AchievementDefault", 842),
        ] {
            addImageset(
                path: "\(name).imageset",
                sourceFilename: "\(name).png",
                variants: unscaledPlatformVariants(maximumLongEdge: maximumLongEdge)
            )
        }
    }

    mutating func addScreenshotFixture() {
        addImageset(
            path: "ScreenshotFixtures/johnAppleseedAvatar.imageset",
            sourceFilename: "johnAppleseedAvatar.png",
            variants: [
                RuntimeAssetOptimizationVariant(name: "iphone", idiom: "iphone", maximumLongEdge: 226),
                RuntimeAssetOptimizationVariant(name: "ipad", idiom: "ipad", maximumLongEdge: 226),
                RuntimeAssetOptimizationVariant(name: "mac", idiom: "mac", maximumLongEdge: 226),
            ]
        )
    }

    mutating func addObsoleteRemovals() {
        for path in [
            "Sprites/Volume.imageset",
            "Sprites/laneInnerMask.imageset",
            "Sprites/laneOuterMask.imageset",
        ] {
            actions.append(.remove(path: "\(RuntimeAssetOptimizationPlanBuilder.catalogRoot)/\(path)"))
        }
    }

    mutating func addAppIconConversions() {
        for path in [
            "RetroRacing/RetroRacingUniversal/Assets/RetroRapid.icon/Assets/appstore1024.png",
            "RetroRacing/RetroRacingWatchOS/Assets.xcassets/AppIcon.appiconset/appstore1024.png",
        ] {
            actions.append(
                .convertTo8Bit(source: repositoryRoot.appending(path: path), destination: path)
            )
        }
    }

    mutating func addImageset(
        path: String,
        sourceFilename: String,
        variants: [RuntimeAssetOptimizationVariant],
        properties: [String: String]? = nil
    ) {
        let destinationDirectory = destinationDirectory(for: path)
        actions.append(.clearPNGs(directory: destinationDirectory))
        let baseName = assetBaseName(for: path)
        let images = variants.map { variant -> AssetCatalogImage in
            let filename = "\(baseName)-\(variant.name).png"
            actions.append(
                .render(
                    source: sourceCatalog.appending(path: "\(path)/\(sourceFilename)"),
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
                    info: AssetCatalogInfo(author: "xcode", version: 1),
                    properties: properties
                )
            )
        )
    }

    private func unscaledPlatformVariants(maximumLongEdge: Int) -> [RuntimeAssetOptimizationVariant] {
        [
            RuntimeAssetOptimizationVariant(name: "iphone", idiom: "iphone", maximumLongEdge: maximumLongEdge),
            RuntimeAssetOptimizationVariant(name: "ipad", idiom: "ipad", maximumLongEdge: maximumLongEdge),
            RuntimeAssetOptimizationVariant(name: "mac", idiom: "mac", maximumLongEdge: maximumLongEdge),
            RuntimeAssetOptimizationVariant(name: "watch", idiom: "watch", maximumLongEdge: 512),
            RuntimeAssetOptimizationVariant(name: "tv", idiom: "tv", maximumLongEdge: 384),
        ]
    }

    private func scaledVariants(
        baseLongEdge: Int,
        maximum3xLongEdge: Int,
        includesTV: Bool
    ) -> [RuntimeAssetOptimizationVariant] {
        var variants = [
            RuntimeAssetOptimizationVariant(name: "iphone-1x", idiom: "iphone", scale: "1x", maximumLongEdge: baseLongEdge),
            RuntimeAssetOptimizationVariant(name: "iphone-2x", idiom: "iphone", scale: "2x", maximumLongEdge: baseLongEdge * 2),
            RuntimeAssetOptimizationVariant(name: "iphone-3x", idiom: "iphone", scale: "3x", maximumLongEdge: maximum3xLongEdge),
            RuntimeAssetOptimizationVariant(name: "ipad-1x", idiom: "ipad", scale: "1x", maximumLongEdge: baseLongEdge),
            RuntimeAssetOptimizationVariant(name: "ipad-2x", idiom: "ipad", scale: "2x", maximumLongEdge: baseLongEdge * 2),
            RuntimeAssetOptimizationVariant(name: "mac-1x", idiom: "mac", scale: "1x", maximumLongEdge: baseLongEdge),
            RuntimeAssetOptimizationVariant(name: "mac-2x", idiom: "mac", scale: "2x", maximumLongEdge: baseLongEdge * 2),
        ]
        if includesTV {
            variants.append(
                RuntimeAssetOptimizationVariant(
                    name: "tv",
                    idiom: "tv",
                    scale: "1x",
                    maximumLongEdge: baseLongEdge == 160 ? 480 : 512
                )
            )
        }
        return variants
    }
}

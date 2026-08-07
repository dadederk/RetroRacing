//
//  RuntimeAssetOptimizationPlanBuilder.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

struct RuntimeAssetOptimizationVariant {
    let name: String
    let idiom: String
    let platform: String?
    let scale: String?
    let sourceKey: String?
    let maximumLongEdge: Int

    init(
        name: String,
        idiom: String,
        platform: String? = nil,
        scale: String? = nil,
        sourceKey: String? = nil,
        maximumLongEdge: Int
    ) {
        self.name = name
        self.idiom = idiom
        self.platform = platform
        self.scale = scale
        self.sourceKey = sourceKey
        self.maximumLongEdge = maximumLongEdge
    }
}

enum RuntimeAssetOptimizationPlanBuilder {
    static let catalogRoot = "RetroRacing/RetroRacingShared/Assets.xcassets"

    static func make(repositoryRoot: URL) -> RuntimeAssetOptimizationPlan {
        var builder = RuntimeAssetOptimizationActionBuilder(repositoryRoot: repositoryRoot)
        builder.addSharedResultAssets()
        builder.addTemplateIcons()
        builder.addProfileAndControlAssets()
        builder.addThemeSprites()
        builder.addUnscaledPlatformAssets()
        builder.addScreenshotFixture()
        builder.addObsoleteRemovals()
        builder.addAppIconConversions()
        return RuntimeAssetOptimizationPlan(actions: builder.actions)
    }
}

struct RuntimeAssetOptimizationActionBuilder {
    let repositoryRoot: URL
    var actions: [RuntimeAssetOptimizationPlan.Action] = []

    var sourceCatalog: URL {
        repositoryRoot.appending(
            path: "AssetSources/RuntimeFootprint2026-08-02/RetroRacingShared/Assets.xcassets"
        )
    }

    var runtimeMasters20260803Root: URL {
        repositoryRoot.appending(path: "AssetSources/RuntimeMasters2026-08-03")
    }

    var runtimeMasters20260804Root: URL {
        repositoryRoot.appending(path: "AssetSources/RuntimeMasters2026-08-04")
    }

    var runtimeMasters20260805Root: URL {
        repositoryRoot.appending(path: "AssetSources/RuntimeMasters2026-08-05")
    }

    var runtimeMasters20260806Root: URL {
        repositoryRoot.appending(path: "AssetSources/RuntimeMasters2026-08-06")
    }

    func destinationDirectory(for imageSetPath: String) -> String {
        "\(RuntimeAssetOptimizationPlanBuilder.catalogRoot)/\(imageSetPath)"
    }

    func assetBaseName(for imageSetPath: String) -> String {
        URL(fileURLWithPath: imageSetPath).deletingPathExtension().lastPathComponent
    }
}

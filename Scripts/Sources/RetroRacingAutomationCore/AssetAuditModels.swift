//
//  AssetAuditModels.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

public struct AssetAuditOptions: Sendable, Equatable {
    public let check: Bool
    public let full: Bool

    public init(check: Bool = false, full: Bool = false) {
        self.check = check
        self.full = full
    }
}

public struct RuntimeAssetManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let compiledCatalogBudgets: [CompiledCatalogBudget]
    public let assets: [RuntimeAssetRule]

    public init(
        schemaVersion: Int,
        compiledCatalogBudgets: [CompiledCatalogBudget],
        assets: [RuntimeAssetRule]
    ) {
        self.schemaVersion = schemaVersion
        self.compiledCatalogBudgets = compiledCatalogBudgets
        self.assets = assets
    }
}

public struct CompiledCatalogBudget: Codable, Equatable, Sendable {
    public let platform: String
    public let displayName: String
    public let actoolPlatform: String
    public let targetDevices: [String]
    public let maximumAssetsCarBytes: Int

    public init(
        platform: String,
        displayName: String,
        actoolPlatform: String,
        targetDevices: [String],
        maximumAssetsCarBytes: Int
    ) {
        self.platform = platform
        self.displayName = displayName
        self.actoolPlatform = actoolPlatform
        self.targetDevices = targetDevices
        self.maximumAssetsCarBytes = maximumAssetsCarBytes
    }
}

public struct RuntimeAssetRule: Codable, Equatable, Sendable {
    public let path: String
    public let allowedIdioms: [String]
    public let requiredIdioms: [String]
    public let maximumLongEdge: [String: Int]
    public let scalesByIdiom: [String: [String]]?
    public let geometryProfile: RuntimeAssetGeometryProfile?

    public init(
        path: String,
        allowedIdioms: [String],
        requiredIdioms: [String],
        maximumLongEdge: [String: Int],
        scalesByIdiom: [String: [String]]? = nil,
        geometryProfile: RuntimeAssetGeometryProfile? = nil
    ) {
        self.path = path
        self.allowedIdioms = allowedIdioms
        self.requiredIdioms = requiredIdioms
        self.maximumLongEdge = maximumLongEdge
        self.scalesByIdiom = scalesByIdiom
        self.geometryProfile = geometryProfile
    }
}

public enum RuntimeAssetGeometryProfile: String, Codable, Equatable, Sendable {
    case helmet
    case sixteenBitPlayerCar
    case sixteenBitRivalCar
    case sixteenBitCrash
    case sixteenBitHelmet
}

public struct AssetCatalogCompileReport: Equatable, Sendable {
    public let platform: String
    public let assetsCarBytes: Int
    public let largestRenditions: [String]

    public init(platform: String, assetsCarBytes: Int, largestRenditions: [String]) {
        self.platform = platform
        self.assetsCarBytes = assetsCarBytes
        self.largestRenditions = largestRenditions
    }
}

struct AssetCatalogContents: Codable, Equatable, Sendable {
    let images: [AssetCatalogImage]
    let info: AssetCatalogInfo?
    let properties: [String: String]?

    init(
        images: [AssetCatalogImage],
        info: AssetCatalogInfo? = nil,
        properties: [String: String]? = nil
    ) {
        self.images = images
        self.info = info
        self.properties = properties
    }
}

struct AssetCatalogImage: Codable, Equatable, Hashable, Sendable {
    let filename: String?
    let idiom: String
    let scale: String?

    init(filename: String? = nil, idiom: String, scale: String? = nil) {
        self.filename = filename
        self.idiom = idiom
        self.scale = scale
    }
}

struct AssetCatalogInfo: Codable, Equatable, Sendable {
    let author: String
    let version: Int
}

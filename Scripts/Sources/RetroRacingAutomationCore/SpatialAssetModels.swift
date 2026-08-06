//
//  SpatialAssetModels.swift
//  RetroRacing
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation
import ScriptSupport

public struct SpatialAssetOptions: Equatable, Sendable {
    public enum Mode: Equatable, Sendable { case apply, check, dryRun }
    public let mode: Mode

    public static func parse(_ arguments: CLIArguments) throws -> SpatialAssetOptions {
        try arguments.rejectUnknownFlags(allowing: ["--check", "--dry-run"])
        if arguments.contains("--check"), arguments.contains("--dry-run") {
            throw SpatialAssetError.incompatibleModes
        }
        if arguments.contains("--check") { return SpatialAssetOptions(mode: .check) }
        if arguments.contains("--dry-run") { return SpatialAssetOptions(mode: .dryRun) }
        return SpatialAssetOptions(mode: .apply)
    }
}

struct SpatialAssetConfiguration: Decodable, Sendable {
    struct Model: Decodable, Sendable {
        let sourceUSDA: String
        let output: String
        let validation: ModelValidation
    }
    struct Models: Decodable, Sendable {
        let player: Model
        let rival: Model
    }
    struct Outputs: Decodable, Sendable {
        let playerSprite: String
        let rivalSprite: String
        let rivalSpriteMaster: String
        let rivalCuratedVisionOS: String
        let rivalCuratedCatalog: String
    }
    struct Camera: Decodable, Sendable {
        let projection: String
        let position: [Double]
        let target: [Double]
        let orthographicScale: Double
        let pixelWidth: Int
        let pixelHeight: Int
        let nearestNeighbor: Bool
    }
    struct ModelValidation: Decodable, Sendable {
        let rootNode: String
        let requiredNodes: [String]
        let forbiddenNodes: [String]
        let requiredMaterials: [String]
        let minimumBounds: [Double]
        let maximumBounds: [Double]
        let maximumTriangles: Int
        let maximumModelBytes: Int
    }
    struct Validation: Decodable, Sendable {
        let maximumSpriteBytes: Int
        let archiveTimestamp: String
    }

    let schemaVersion: Int
    let sourcePlayerSprite: String
    let models: Models
    let outputs: Outputs
    let camera: Camera
    let validation: Validation
}

public enum SpatialAssetError: LocalizedError, Equatable {
    case incompatibleModes
    case invalidConfiguration(String)
    case invalidSource([String])
    case invalidOutput([String])
    case outputDrift([String])

    public var errorDescription: String? {
        switch self {
        case .incompatibleModes:
            return "--check and --dry-run cannot be used together."
        case .invalidConfiguration(let message):
            return "Invalid spatial asset configuration: \(message)"
        case .invalidSource(let issues):
            return "Spatial model source validation failed:\n" + issues.map { "  - \($0)" }.joined(separator: "\n")
        case .invalidOutput(let issues):
            return "Generated spatial asset validation failed:\n" + issues.map { "  - \($0)" }.joined(separator: "\n")
        case .outputDrift(let paths):
            return "Spatial assets are stale. Run ./retrorapid assets spatial:\n" + paths.map { "  - \($0)" }.joined(separator: "\n")
        }
    }
}

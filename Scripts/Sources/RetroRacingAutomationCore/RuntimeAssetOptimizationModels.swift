//
//  RuntimeAssetOptimizationModels.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation
import ScriptSupport

public enum RuntimeAssetOptimizationMode: Sendable, Equatable {
    case apply
    case check
    case dryRun
}

public struct RuntimeAssetOptimizationOptions: Sendable, Equatable {
    public let mode: RuntimeAssetOptimizationMode

    public init(mode: RuntimeAssetOptimizationMode) {
        self.mode = mode
    }

    public static func parse(_ arguments: CLIArguments) throws -> RuntimeAssetOptimizationOptions {
        try arguments.rejectUnknownFlags(allowing: ["--check", "--dry-run"])
        guard arguments.contains("--check") == false || arguments.contains("--dry-run") == false else {
            throw ScriptSupportError.unexpectedArgument("--check and --dry-run cannot be combined")
        }
        if arguments.contains("--check") {
            return RuntimeAssetOptimizationOptions(mode: .check)
        }
        if arguments.contains("--dry-run") {
            return RuntimeAssetOptimizationOptions(mode: .dryRun)
        }
        return RuntimeAssetOptimizationOptions(mode: .apply)
    }
}

struct RuntimeAssetOptimizationPlan: Sendable, Equatable {
    enum Action: Sendable, Equatable {
        case clearPNGs(directory: String)
        case render(source: URL, destination: String, maximumLongEdge: Int)
        case convertTo8Bit(source: URL, destination: String)
        case writeContents(destination: String, contents: AssetCatalogContents)
        case remove(path: String)

        var destination: String? {
            switch self {
            case let .render(_, destination, _),
                 let .convertTo8Bit(_, destination),
                 let .writeContents(destination, _):
                destination
            case .clearPNGs, .remove:
                nil
            }
        }

        var summary: String {
            switch self {
            case let .clearPNGs(directory):
                "clear PNGs in \(directory)"
            case let .render(source, destination, maximum):
                "render \(source.lastPathComponent) -> \(destination) (max \(maximum) px)"
            case let .convertTo8Bit(source, destination):
                "convert \(source.lastPathComponent) -> \(destination) (8-bit RGBA)"
            case let .writeContents(destination, _):
                "write \(destination)"
            case let .remove(path):
                "remove \(path)"
            }
        }
    }

    let actions: [Action]

    init(actions: [Action]) {
        self.actions = actions
    }
}

public enum RuntimeAssetOptimizationError: LocalizedError {
    case drift([String])
    case invalidPlan([String])
    case commitRollbackFailed(commitError: String, rollbackError: String)
    case missingImageMetadata(String)
    case unsupportedImageMagick(String)

    public var errorDescription: String? {
        switch self {
        case let .drift(issues):
            "Runtime asset optimization check failed:\n" + issues.joined(separator: "\n")
        case let .invalidPlan(issues):
            "Runtime asset optimization plan conflicts with the manifest:\n" + issues.joined(separator: "\n")
        case let .commitRollbackFailed(commitError, rollbackError):
            "Runtime asset commit failed (\(commitError)) and rollback also failed (\(rollbackError))"
        case let .missingImageMetadata(path):
            "Could not read image metadata at \(path)"
        case let .unsupportedImageMagick(message):
            message
        }
    }
}

public protocol RuntimeAssetImageTransforming {
    func validateEnvironment() throws
    func render(source: URL, destination: URL, maximumLongEdge: Int) throws
    func convertTo8Bit(source: URL, destination: URL) throws
    func imagesArePixelEquivalent(_ lhs: URL, _ rhs: URL) throws -> Bool
    func imageIs8BitRGBA(_ image: URL) throws -> Bool
}

public extension RuntimeAssetImageTransforming {
    func validateEnvironment() throws {}
}

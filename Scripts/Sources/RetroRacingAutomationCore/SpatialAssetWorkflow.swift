//
//  SpatialAssetWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation
import ImageIO
import RealityKit
import ScriptSupport

public enum SpatialAssetWorkflow {
    public static let configurationPath = "AssetSources/VisionOS64BitPrototype2026-08-05/PlayerCar/spatial-production.json"

    @MainActor
    public static func run(
        repositoryRoot: URL,
        options: SpatialAssetOptions
    ) async throws {
        let configuration = try loadConfiguration(repositoryRoot: repositoryRoot)
        let paths = try resolvePaths(configuration: configuration, repositoryRoot: repositoryRoot)
        try validateMembership(configuration: configuration, repositoryRoot: repositoryRoot)

        if options.mode == .dryRun {
            print("Spatial asset production plan:")
            print("  - Compose and validate distinct player and rival USDA sources")
            print("  - Package player-car-64bit.usdz and rival-car-64bit.usdz")
            print("  - Render the rival sprite from its composed 3D model with the fixed camera")
            print("  - Derive the five shared-platform rival projections")
            print("  - Validate RealityKit import, target membership, budgets, and output drift")
            return
        }

        let temporaryRoot = FileManager.default.temporaryDirectory.appending(
            path: "retrorapid-spatial-assets-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        let generated = try generate(
            configuration: configuration,
            paths: paths,
            temporaryRoot: temporaryRoot
        )
        try await validateGenerated(generated: generated, configuration: configuration)

        let files = try generatedFiles(
            generated: generated,
            paths: paths
        )
        if options.mode == .check {
            let stale = FileWork.staleFiles(among: files, relativeTo: repositoryRoot)
            guard stale.isEmpty else { throw SpatialAssetError.outputDrift(stale) }
            print("Spatial assets match the production manifest.")
        } else {
            try FileWork.writeAtomically(files)
            print("Spatial player/rival models and model-derived sprites generated.")
        }
    }

    private struct ModelPaths {
        let sourceUSDA: URL
        let output: URL
    }

    private struct Paths {
        let playerModel: ModelPaths
        let rivalModel: ModelPaths
        let sourcePlayerSprite: URL
        let playerOutput: URL
        let rivalOutput: URL
        let rivalSpriteMaster: URL
        let rivalCuratedVisionOS: URL
        let rivalCuratedCatalog: URL
    }

    private struct PreparedModel {
        let usdz: URL
        let composedSource: String
    }

    private struct GeneratedPaths {
        let playerModel: PreparedModel
        let rivalModel: PreparedModel
        let playerSprite: URL
        let rivalSprite: URL
        let catalogSprites: [String: URL]
    }

    private static func loadConfiguration(repositoryRoot: URL) throws -> SpatialAssetConfiguration {
        let url = repositoryRoot.appending(path: configurationPath)
        let configuration = try JSONDecoder().decode(
            SpatialAssetConfiguration.self,
            from: Data(contentsOf: url)
        )
        let modelValidations = [
            configuration.models.player.validation,
            configuration.models.rival.validation,
        ]
        guard configuration.schemaVersion == 3,
              configuration.camera.position.count == 3,
              configuration.camera.target.count == 3,
              configuration.camera.pixelWidth > 0,
              configuration.camera.pixelHeight > 0,
              modelValidations.allSatisfy({
                  $0.minimumBounds.count == 3 && $0.maximumBounds.count == 3
              }) else {
            throw SpatialAssetError.invalidConfiguration("schema, camera, or bounds are invalid")
        }
        return configuration
    }

    private static func resolvePaths(
        configuration: SpatialAssetConfiguration,
        repositoryRoot: URL
    ) throws -> Paths {
        func resolved(_ relativePath: String) throws -> URL {
            let url = repositoryRoot.appending(path: relativePath).standardizedFileURL
            guard url.path.hasPrefix(repositoryRoot.standardizedFileURL.path + "/") else {
                throw SpatialAssetError.invalidConfiguration("Path escapes repository: \(relativePath)")
            }
            return url
        }
        return try Paths(
            playerModel: ModelPaths(
                sourceUSDA: resolved(configuration.models.player.sourceUSDA),
                output: resolved(configuration.models.player.output)
            ),
            rivalModel: ModelPaths(
                sourceUSDA: resolved(configuration.models.rival.sourceUSDA),
                output: resolved(configuration.models.rival.output)
            ),
            sourcePlayerSprite: resolved(configuration.sourcePlayerSprite),
            playerOutput: resolved(configuration.outputs.playerSprite),
            rivalOutput: resolved(configuration.outputs.rivalSprite),
            rivalSpriteMaster: resolved(configuration.outputs.rivalSpriteMaster),
            rivalCuratedVisionOS: resolved(configuration.outputs.rivalCuratedVisionOS),
            rivalCuratedCatalog: resolved(configuration.outputs.rivalCuratedCatalog)
        )
    }

    private static func validateMembership(
        configuration: SpatialAssetConfiguration,
        repositoryRoot: URL
    ) throws {
        let outputPrefix = "RetroRacing/RetroRacingVisionOS/"
        let shippingOutputs = [
            configuration.models.player.output,
            configuration.models.rival.output,
            configuration.outputs.playerSprite,
            configuration.outputs.rivalSprite,
        ]
        var issues = shippingOutputs.filter { $0.hasPrefix(outputPrefix) == false }
            .map { "Shipping output is outside the visionOS synchronized target: \($0)" }
        let projectURL = repositoryRoot.appending(path: "RetroRacing/RetroRacing.xcodeproj/project.pbxproj")
        let project = try String(contentsOf: projectURL, encoding: .utf8)
        if project.contains("VisionOS64BitPrototype2026-08-05") {
            issues.append("Canonical source archive must be excluded from Xcode targets.")
        }
        for file in [configuration.outputs.playerSprite, configuration.outputs.rivalSprite] {
            let output = repositoryRoot.appending(path: file)
            let contentsURL = output.deletingLastPathComponent().appending(path: "Contents.json")
            let contents = try String(contentsOf: contentsURL, encoding: .utf8)
            if contents.contains(output.lastPathComponent) == false {
                issues.append("Asset catalog membership is missing for \(file).")
            }
        }
        guard issues.isEmpty else { throw SpatialAssetError.invalidSource(issues) }
    }

    private static func generate(
        configuration: SpatialAssetConfiguration,
        paths: Paths,
        temporaryRoot: URL
    ) throws -> GeneratedPaths {
        guard let timestamp = ISO8601DateFormatter().date(
            from: configuration.validation.archiveTimestamp
        ) else {
            throw SpatialAssetError.invalidConfiguration("archiveTimestamp is not ISO-8601")
        }
        let playerModel = try prepareModel(
            source: paths.playerModel.sourceUSDA,
            name: "player-car-64bit",
            validation: configuration.models.player.validation,
            timestamp: timestamp,
            temporaryRoot: temporaryRoot
        )
        let rivalModel = try prepareModel(
            source: paths.rivalModel.sourceUSDA,
            name: "rival-car-64bit",
            validation: configuration.models.rival.validation,
            timestamp: timestamp,
            temporaryRoot: temporaryRoot
        )
        let playerSprite = temporaryRoot.appending(path: "playersCar-64Bit.png")
        try FileManager.default.copyItem(at: paths.sourcePlayerSprite, to: playerSprite)
        let rivalSprite = temporaryRoot.appending(path: "rivalsCar-64Bit.png")
        try SpatialAssetSpriteRenderer.render(
            source: rivalModel.composedSource,
            camera: configuration.camera,
            destination: rivalSprite
        )
        let catalogSprites = try renderCatalogSprites(
            source: rivalSprite,
            temporaryRoot: temporaryRoot
        )
        return GeneratedPaths(
            playerModel: playerModel,
            rivalModel: rivalModel,
            playerSprite: playerSprite,
            rivalSprite: rivalSprite,
            catalogSprites: catalogSprites
        )
    }

    private static func prepareModel(
        source: URL,
        name: String,
        validation: SpatialAssetConfiguration.ModelValidation,
        timestamp: Date,
        temporaryRoot: URL
    ) throws -> PreparedModel {
        let directory = temporaryRoot.appending(path: name, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let composedUSDA = directory.appending(path: "\(name).usda")
        let usdc = directory.appending(path: "\(name).usdc")
        let usdz = directory.appending(path: "\(name).usdz")
        try ProcessRunner.run(ProcessCommand(
            executable: "/usr/bin/usdcat",
            arguments: [source.path, "--flatten", "-o", composedUSDA.path]
        ))
        let composedSource = normalizedComposedSource(
            try String(contentsOf: composedUSDA, encoding: .utf8)
        )
        try composedSource.write(to: composedUSDA, atomically: true, encoding: .utf8)
        _ = try SpatialAssetSourceValidator.validate(
            source: composedSource,
            validation: validation
        )
        try ProcessRunner.run(ProcessCommand(
            executable: "/usr/bin/usdcat",
            arguments: [composedUSDA.path, "-o", usdc.path]
        ))
        try FileManager.default.setAttributes([.modificationDate: timestamp], ofItemAtPath: usdc.path)
        try ProcessRunner.run(ProcessCommand(
            executable: "/usr/bin/usdzip",
            arguments: [usdz.lastPathComponent, usdc.lastPathComponent],
            currentDirectory: directory
        ))
        return PreparedModel(usdz: usdz, composedSource: composedSource)
    }

    /// `usdcat --flatten` records the absolute root-layer path in generated documentation.
    /// Replacing that checkout-specific line keeps the packaged USDC/USDZ bytes reproducible.
    private static func normalizedComposedSource(_ source: String) -> String {
        let generatedDocumentPrefix = "    doc = \"\"\"Generated from Composed Stage of root layer "
        return source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                line.hasPrefix(generatedDocumentPrefix)
                    ? "    doc = \"\"\"Generated from canonical RetroRapid spatial source"
                    : String(line)
            }
            .joined(separator: "\n")
    }

    private static func renderCatalogSprites(
        source: URL,
        temporaryRoot: URL
    ) throws -> [String: URL] {
        let variants = [
            "iphone": (width: 768, height: 496),
            "ipad": (width: 768, height: 496),
            "mac": (width: 918, height: 593),
            "tv": (width: 512, height: 331),
            "watch": (width: 256, height: 165),
        ]
        return try Dictionary(uniqueKeysWithValues: variants.map { idiom, dimensions in
            let output = temporaryRoot.appending(path: "rivalsCar-64Bit-\(idiom).png")
            try ProcessRunner.run(ProcessCommand(
                executable: "/usr/bin/env",
                arguments: [
                    "magick", source.path,
                    "-trim", "+repage",
                    "-filter", "point",
                    "-resize", "\(dimensions.width)x\(dimensions.height)",
                    "-gravity", "center",
                    "-background", "none",
                    "-extent", "\(dimensions.width)x\(dimensions.height)",
                    "-depth", "8",
                    "-define", "png:exclude-chunks=date,time",
                    "PNG32:\(output.path)",
                ]
            ))
            return (idiom, output)
        })
    }

    private static func generatedFiles(
        generated: GeneratedPaths,
        paths: Paths
    ) throws -> [GeneratedFile] {
        let rivalData = try Data(contentsOf: generated.rivalSprite)
        var files = [
            GeneratedFile(url: paths.playerModel.output, data: try Data(contentsOf: generated.playerModel.usdz)),
            GeneratedFile(url: paths.rivalModel.output, data: try Data(contentsOf: generated.rivalModel.usdz)),
            GeneratedFile(url: paths.playerOutput, data: try Data(contentsOf: generated.playerSprite)),
            GeneratedFile(url: paths.rivalOutput, data: rivalData),
            GeneratedFile(url: paths.rivalSpriteMaster, data: rivalData),
            GeneratedFile(url: paths.rivalCuratedVisionOS, data: rivalData),
        ]
        for (idiom, url) in generated.catalogSprites {
            let filename = "rivalsCar-64Bit-\(idiom).png"
            files.append(GeneratedFile(
                url: paths.rivalCuratedCatalog.appending(path: filename),
                data: try Data(contentsOf: url)
            ))
        }
        return files
    }

    @MainActor
    private static func validateGenerated(
        generated: GeneratedPaths,
        configuration: SpatialAssetConfiguration
    ) async throws {
        var issues = [String]()
        let models = [
            ("player", generated.playerModel, configuration.models.player.validation),
            ("rival", generated.rivalModel, configuration.models.rival.validation),
        ]
        for (label, model, validation) in models {
            let size = try Data(contentsOf: model.usdz).count
            if size > validation.maximumModelBytes {
                issues.append("\(label) USDZ is \(size) bytes; ceiling is \(validation.maximumModelBytes).")
            }
            do {
                try ProcessRunner.run(ProcessCommand(
                    executable: "/usr/bin/usdchecker",
                    arguments: [model.usdz.path]
                ))
                let entity = try await Entity(contentsOf: model.usdz)
                let names = Set(allNames(in: entity))
                let expected = [validation.rootNode] + validation.requiredNodes
                if expected.allSatisfy(names.contains) == false {
                    issues.append("RealityKit import is missing required \(label) hierarchy names.")
                }
                if validation.forbiddenNodes.allSatisfy({ names.contains($0) == false }) == false {
                    issues.append("RealityKit imported a forbidden \(label) hierarchy name.")
                }
            } catch {
                issues.append("\(label) RealityKit or USD validation failed: \(error.localizedDescription)")
            }
        }
        for (label, url) in [
            ("player", generated.playerSprite),
            ("rival", generated.rivalSprite),
        ] {
            let size = try Data(contentsOf: url).count
            if size > configuration.validation.maximumSpriteBytes {
                issues.append("\(label) sprite is \(size) bytes; ceiling is \(configuration.validation.maximumSpriteBytes).")
            }
            let dimensions = imageDimensions(url)
            if dimensions?.width != configuration.camera.pixelWidth
                || dimensions?.height != configuration.camera.pixelHeight {
                issues.append("\(label) sprite dimensions do not match the camera manifest.")
            }
        }
        guard issues.isEmpty else { throw SpatialAssetError.invalidOutput(issues) }
    }

    @MainActor
    private static func allNames(in entity: Entity) -> [String] {
        [entity.name] + entity.children.flatMap(allNames(in:))
    }

    private static func imageDimensions(_ url: URL) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else { return nil }
        return (width, height)
    }
}

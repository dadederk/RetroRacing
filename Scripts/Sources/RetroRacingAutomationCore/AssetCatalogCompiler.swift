//
//  AssetCatalogCompiler.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation
import ScriptSupport

enum AssetCatalogCompiler {
    static func compileSharedCatalog(
        repositoryRoot: URL,
        manifest: RuntimeAssetManifest
    ) throws -> [AssetCatalogCompileReport] {
        let fileManager = FileManager.default
        let catalog = repositoryRoot.appending(path: "RetroRacing/RetroRacingShared/Assets.xcassets")
        let outputRoot = repositoryRoot.appending(path: ".build/asset-audit/catalog")
        if fileManager.fileExists(atPath: outputRoot.path) {
            try fileManager.removeItem(at: outputRoot)
        }
        try fileManager.createDirectory(at: outputRoot, withIntermediateDirectories: true)

        return try manifest.compiledCatalogBudgets.map { budget in
            let output = outputRoot.appending(path: budget.platform)
            try fileManager.createDirectory(at: output, withIntermediateDirectories: true)
            let arguments = [
                "actool",
                "--compile", output.path,
                "--platform", budget.actoolPlatform,
                "--minimum-deployment-target", "26.0",
            ] + budget.targetDevices.flatMap { ["--target-device", $0] } + [catalog.path]
            _ = try ProcessRunner.run(
                ProcessCommand(
                    executable: "/usr/bin/xcrun",
                    arguments: arguments,
                    currentDirectory: repositoryRoot
                ),
                captureOutput: true
            )

            let assetsCar = output.appending(path: "Assets.car")
            let bytes = (try? assetsCar.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return AssetCatalogCompileReport(
                platform: budget.platform,
                assetsCarBytes: bytes,
                largestRenditions: try largestRenditions(in: assetsCar)
            )
        }
    }

    static func enforceBudgets(
        reports: [AssetCatalogCompileReport],
        manifest: RuntimeAssetManifest
    ) throws {
        let budgets = Dictionary(
            uniqueKeysWithValues: manifest.compiledCatalogBudgets.map {
                ($0.platform, $0.maximumAssetsCarBytes)
            }
        )
        let issues = reports.compactMap { report -> String? in
            guard let maximum = budgets[report.platform], report.assetsCarBytes > maximum else {
                return nil
            }
            return "\(report.platform) Assets.car \(report.assetsCarBytes) bytes exceeds \(maximum)"
        }
        guard issues.isEmpty else { throw AssetAuditError.validationFailed(issues) }
    }

    private static func largestRenditions(in assetsCar: URL) throws -> [String] {
        guard FileManager.default.fileExists(atPath: assetsCar.path) else { return [] }
        let output = try ProcessRunner.run(
            ProcessCommand(executable: "/usr/bin/xcrun", arguments: ["assetutil", "-I", assetsCar.path]),
            captureOutput: true
        )
        guard let data = output.data(using: .utf8),
              let objects = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }
        return objects.compactMap { object -> (name: String, bytes: Int)? in
            guard let bytes = (object["SizeOnDisk"] as? Int) ?? (object["StorageSize"] as? Int),
                  bytes > 0 else { return nil }
            let name = (object["Name"] as? String)
                ?? (object["RenditionName"] as? String)
                ?? (object["AssetName"] as? String)
                ?? "unnamed"
            return (name, bytes)
        }
        .sorted { $0.bytes > $1.bytes }
        .prefix(8)
        .map { "\($0.name): \($0.bytes) bytes" }
    }
}

//
//  RuntimeAssetOptimizationChecker.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

enum RuntimeAssetOptimizationChecker {
    static func check(
        plan: RuntimeAssetOptimizationPlan,
        repositoryRoot: URL,
        transformer: any RuntimeAssetImageTransforming
    ) throws {
        let temporaryRoot = FileManager.default.temporaryDirectory.appending(
            path: "retrorapid-runtime-assets-\(UUID().uuidString)"
        )
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        try RuntimeAssetOptimizationExecutor.execute(
            plan: plan,
            repositoryRoot: repositoryRoot,
            outputRoot: temporaryRoot,
            transformer: transformer
        )

        let issues = try driftIssues(
            plan: plan,
            repositoryRoot: repositoryRoot,
            generatedRoot: temporaryRoot,
            transformer: transformer
        )
        guard issues.isEmpty else { throw RuntimeAssetOptimizationError.drift(issues) }
    }

    private static func driftIssues(
        plan: RuntimeAssetOptimizationPlan,
        repositoryRoot: URL,
        generatedRoot: URL,
        transformer: any RuntimeAssetImageTransforming
    ) throws -> [String] {
        var issues: [String] = []
        for action in plan.actions {
            switch action {
            case let .remove(path):
                if FileManager.default.fileExists(atPath: repositoryRoot.appending(path: path).path) {
                    issues.append("Remove obsolete runtime asset path: \(path)")
                }
            case let .writeContents(destination, expectedContents):
                issues += catalogIssues(
                    destination: destination,
                    expected: expectedContents,
                    repositoryRoot: repositoryRoot
                )
            case let .render(_, destination, _):
                try compareImage(
                    destination: destination,
                    repositoryRoot: repositoryRoot,
                    generatedRoot: generatedRoot,
                    transformer: transformer,
                    issues: &issues
                )
            case let .convertTo8Bit(_, destination):
                try compareImage(
                    destination: destination,
                    repositoryRoot: repositoryRoot,
                    generatedRoot: generatedRoot,
                    transformer: transformer,
                    issues: &issues
                )
                if try transformer.imageIs8BitRGBA(repositoryRoot.appending(path: destination)) == false {
                    issues.append("Optimized image is not 8-bit RGBA: \(destination)")
                }
            case let .clearPNGs(directory):
                let expected = expectedPNGNames(in: directory, actions: plan.actions)
                let current = try currentPNGNames(in: repositoryRoot.appending(path: directory))
                if current != expected {
                    issues.append(
                        "\(directory) PNG files \(current.sorted()) do not match \(expected.sorted())"
                    )
                }
            }
        }
        return issues
    }

    private static func catalogIssues(
        destination: String,
        expected: AssetCatalogContents,
        repositoryRoot: URL
    ) -> [String] {
        let currentURL = repositoryRoot.appending(path: destination)
        guard let currentData = try? Data(contentsOf: currentURL),
              let current = try? JSONDecoder().decode(AssetCatalogContents.self, from: currentData) else {
            return ["Missing or invalid generated catalog JSON: \(destination)"]
        }
        return catalogContentsAreEquivalent(current, expected)
            ? []
            : ["Generated catalog JSON is stale: \(destination)"]
    }

    private static func compareImage(
        destination: String,
        repositoryRoot: URL,
        generatedRoot: URL,
        transformer: any RuntimeAssetImageTransforming,
        issues: inout [String]
    ) throws {
        let current = repositoryRoot.appending(path: destination)
        guard FileManager.default.fileExists(atPath: current.path) else {
            issues.append("Missing optimized image: \(destination)")
            return
        }
        if try transformer.imagesArePixelEquivalent(
            current,
            generatedRoot.appending(path: destination)
        ) == false {
            issues.append("Optimized image is stale: \(destination)")
        }
    }

    private static func catalogContentsAreEquivalent(
        _ lhs: AssetCatalogContents,
        _ rhs: AssetCatalogContents
    ) -> Bool {
        lhs.info == rhs.info
            && lhs.properties == rhs.properties
            && Set(lhs.images.filter { $0.filename?.isEmpty == false })
                == Set(rhs.images.filter { $0.filename?.isEmpty == false })
    }

    private static func currentPNGNames(in directory: URL) throws -> Set<String> {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return Set(try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension.lowercased() == "png" }.map(\.lastPathComponent))
    }

    private static func expectedPNGNames(
        in directory: String,
        actions: [RuntimeAssetOptimizationPlan.Action]
    ) -> Set<String> {
        Set(actions.compactMap { action in
            guard let destination = action.destination else { return nil }
            let path = destination as NSString
            return path.deletingLastPathComponent == directory
                && path.pathExtension.lowercased() == "png"
                ? path.lastPathComponent
                : nil
        })
    }
}

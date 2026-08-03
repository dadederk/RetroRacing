//
//  RuntimeAssetOptimizationPlanValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

enum RuntimeAssetOptimizationPlanValidator {
    private static let catalogPrefix = "RetroRacing/RetroRacingShared/Assets.xcassets/"

    static func issues(
        in plan: RuntimeAssetOptimizationPlan,
        manifest: RuntimeAssetManifest
    ) -> [String] {
        var rulesByPath: [String: RuntimeAssetRule] = [:]
        let renderLimits = renderLimitsByDestination(in: plan)
        var issues: [String] = []
        issues += duplicateGeneratedDestinationIssues(in: plan)
        for rule in manifest.assets {
            if rulesByPath.updateValue(rule, forKey: rule.path) != nil {
                issues.append("Runtime asset manifest contains duplicate path '\(rule.path)'")
            }
        }

        for action in plan.actions {
            guard case let .writeContents(destination, contents) = action,
                  let assetPath = assetPath(forContentsDestination: destination) else {
                continue
            }
            guard let rule = rulesByPath[assetPath] else {
                issues.append("Optimizer writes an asset missing from the manifest: \(assetPath)")
                continue
            }
            issues += policyIssues(
                assetPath: assetPath,
                contents: contents,
                rule: rule,
                destinationDirectory: destination.deletingLastPathComponent,
                renderLimits: renderLimits
            )
        }

        let independentlyGeneratedAssets = Set(["Sprites/lapStripMask.imageset"])
        let expectedOwnedPaths = Set(manifest.assets.map(\.path))
            .subtracting(independentlyGeneratedAssets)
        let plannedPathValues: [String] = plan.actions.compactMap { action in
            guard case let .writeContents(destination, _) = action else { return nil }
            return assetPath(forContentsDestination: destination)
        }
        let plannedPaths = Set(plannedPathValues)
        for missingPath in expectedOwnedPaths.subtracting(plannedPaths).sorted() {
            issues.append("Manifest asset is not owned by an asset generator: \(missingPath)")
        }
        return issues
    }

    private static func policyIssues(
        assetPath: String,
        contents: AssetCatalogContents,
        rule: RuntimeAssetRule,
        destinationDirectory: String,
        renderLimits: [String: Int]
    ) -> [String] {
        let images = contents.images.filter { $0.filename != nil }
        var issues: [String] = []
        let idioms = Set(images.map(\.idiom))
        let requiredIdioms = Set(rule.requiredIdioms)
        guard idioms == requiredIdioms else {
            return [
                "Optimizer idioms for \(assetPath) are \(idioms.sorted()), expected \(requiredIdioms.sorted())"
            ]
        }

        for idiom in requiredIdioms.sorted() {
            let idiomImages = images.filter { $0.idiom == idiom }
            let actualScales = Set(idiomImages.compactMap(\.scale))
            let expectedScales = Set(rule.scalesByIdiom?[idiom] ?? [])
            if actualScales != expectedScales {
                issues.append(
                    "Optimizer scales for \(assetPath) [\(idiom)] are \(actualScales.sorted()), "
                    + "expected \(expectedScales.sorted())"
                )
            }
            guard let manifestMaximum = rule.maximumLongEdge[idiom] else {
                issues.append("Manifest has no pixel cap for optimizer asset \(assetPath) [\(idiom)]")
                continue
            }
            for image in idiomImages {
                guard let filename = image.filename else { continue }
                let destination = "\(destinationDirectory)/\(filename)"
                guard let renderMaximum = renderLimits[destination] else {
                    issues.append("Optimizer has no render action for \(destination)")
                    continue
                }
                if renderMaximum > manifestMaximum {
                    issues.append(
                        "Optimizer cap \(renderMaximum) exceeds manifest cap \(manifestMaximum) for \(destination)"
                    )
                }
            }
        }
        return issues
    }

    private static func renderLimitsByDestination(
        in plan: RuntimeAssetOptimizationPlan
    ) -> [String: Int] {
        plan.actions.reduce(into: [:]) { result, action in
            guard case let .render(_, destination, maximumLongEdge) = action else { return }
            result[destination] = maximumLongEdge
        }
    }

    private static func duplicateGeneratedDestinationIssues(
        in plan: RuntimeAssetOptimizationPlan
    ) -> [String] {
        var seen: Set<String> = []
        var duplicates: Set<String> = []
        for destination in plan.actions.compactMap(\.destination) {
            if seen.insert(destination).inserted == false {
                duplicates.insert(destination)
            }
        }
        return duplicates.sorted().map { "Optimizer generates destination more than once: \($0)" }
    }

    private static func assetPath(forContentsDestination destination: String) -> String? {
        guard destination.hasPrefix(catalogPrefix), destination.hasSuffix("/Contents.json") else {
            return nil
        }
        return String(destination.dropFirst(catalogPrefix.count).dropLast("/Contents.json".count))
    }
}

private extension String {
    var deletingLastPathComponent: String {
        (self as NSString).deletingLastPathComponent
    }
}

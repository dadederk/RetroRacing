//
//  AssetManifestValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

enum AssetManifestValidator {
    static func issues(in manifest: RuntimeAssetManifest) -> [String] {
        var issues: [String] = []
        if manifest.schemaVersion != 2 {
            issues.append("Runtime asset manifest schema must be 2, found \(manifest.schemaVersion)")
        }

        issues += duplicateValues(manifest.assets.map(\.path)).map {
            "Runtime asset manifest contains duplicate path '\($0)'"
        }
        issues += duplicateValues(manifest.compiledCatalogBudgets.map(\.platform)).map {
            "Runtime asset manifest contains duplicate platform '\($0)'"
        }

        for rule in manifest.assets {
            let allowed = Set(rule.allowedIdioms)
            let required = Set(rule.requiredIdioms)
            let capped = Set(rule.maximumLongEdge.keys)
            let scaled = Set(rule.scalesByIdiom?.keys.map { $0 } ?? [])

            if required.isSubset(of: allowed) == false {
                issues.append("\(rule.path) required idioms must be a subset of allowed idioms")
            }
            if capped != allowed {
                issues.append("\(rule.path) must define a pixel cap for every allowed idiom")
            }
            if scaled.isSubset(of: allowed) == false {
                issues.append("\(rule.path) scale rules must reference allowed idioms only")
            }
            if rule.maximumLongEdge.values.contains(where: { $0 <= 0 }) {
                issues.append("\(rule.path) pixel caps must be positive")
            }
            if rule.scalesByIdiom?.values.contains(where: { $0.isEmpty }) == true {
                issues.append("\(rule.path) scale rules must not be empty")
            }
        }
        return issues
    }

    private static func duplicateValues(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return Set(values.filter { seen.insert($0).inserted == false }).sorted()
    }
}

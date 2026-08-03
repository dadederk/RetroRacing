//
//  AssetAuditWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 02/08/2026.
//

import Foundation

public enum AssetAuditWorkflow {
    public static func run(repositoryRoot: URL, options: AssetAuditOptions) throws {
        let manifest = try loadManifest(repositoryRoot: repositoryRoot)
        let issues = try validationIssues(repositoryRoot: repositoryRoot, manifest: manifest)
        if issues.isEmpty {
            print("Runtime asset manifest is valid.")
        } else if options.check {
            throw AssetAuditError.validationFailed(issues)
        } else {
            print("Runtime asset manifest warnings:")
            issues.forEach { print("  - \($0)") }
        }

        let reports = try AssetCatalogCompiler.compileSharedCatalog(
            repositoryRoot: repositoryRoot,
            manifest: manifest
        )
        print("Compiled shared asset catalog:")
        for report in reports {
            print("  \(report.platform): \(report.assetsCarBytes) bytes")
            report.largestRenditions.prefix(5).forEach { print("    \($0)") }
        }
        if options.check {
            try AssetCatalogCompiler.enforceBudgets(reports: reports, manifest: manifest)
        }

        if options.full {
            try ReleasePackagingValidator.run(
                repositoryRoot: repositoryRoot,
                check: options.check
            )
        }
    }

    public static func loadManifest(repositoryRoot: URL) throws -> RuntimeAssetManifest {
        let url = repositoryRoot.appending(path: "Scripts/Resources/runtime_asset_manifest.json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(RuntimeAssetManifest.self, from: data)
    }

    public static func validationIssues(
        repositoryRoot: URL,
        manifest: RuntimeAssetManifest
    ) throws -> [String] {
        var issues = AssetManifestValidator.issues(in: manifest)
        issues += try RepositoryAssetValidator.issues(repositoryRoot: repositoryRoot)
        issues += try AssetCatalogValidator.issues(
            repositoryRoot: repositoryRoot,
            manifest: manifest
        )
        return issues
    }
}

public enum AssetAuditError: LocalizedError {
    case validationFailed([String])

    public var errorDescription: String? {
        switch self {
        case let .validationFailed(issues):
            "Runtime asset audit failed:\n" + issues.joined(separator: "\n")
        }
    }
}

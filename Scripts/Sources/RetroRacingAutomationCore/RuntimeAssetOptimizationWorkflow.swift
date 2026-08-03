//
//  RuntimeAssetOptimizationWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

public enum RuntimeAssetOptimizationWorkflow {
    public static func run(
        repositoryRoot: URL,
        options: RuntimeAssetOptimizationOptions,
        transformer: any RuntimeAssetImageTransforming
    ) throws {
        let plan = RuntimeAssetOptimizationPlanBuilder.make(repositoryRoot: repositoryRoot)
        let manifest = try AssetAuditWorkflow.loadManifest(repositoryRoot: repositoryRoot)
        let planIssues = RuntimeAssetOptimizationPlanValidator.issues(in: plan, manifest: manifest)
        guard planIssues.isEmpty else {
            throw RuntimeAssetOptimizationError.invalidPlan(planIssues)
        }
        try run(
            plan: plan,
            repositoryRoot: repositoryRoot,
            options: options,
            transformer: transformer
        )
    }

    static func run(
        plan: RuntimeAssetOptimizationPlan,
        repositoryRoot: URL,
        options: RuntimeAssetOptimizationOptions,
        transformer: any RuntimeAssetImageTransforming
    ) throws {
        switch options.mode {
        case .dryRun:
            plan.actions.forEach { print("  - \($0.summary)") }
        case .apply:
            try transformer.validateEnvironment()
            try apply(plan: plan, repositoryRoot: repositoryRoot, transformer: transformer)
            print("Runtime assets optimized.")
        case .check:
            try transformer.validateEnvironment()
            try RuntimeAssetOptimizationChecker.check(
                plan: plan,
                repositoryRoot: repositoryRoot,
                transformer: transformer
            )
            print("Runtime assets match the optimization plan.")
        }
    }

    private static func apply(
        plan: RuntimeAssetOptimizationPlan,
        repositoryRoot: URL,
        transformer: any RuntimeAssetImageTransforming
    ) throws {
        let temporaryRoot = FileManager.default.temporaryDirectory.appending(
            path: "retrorapid-runtime-assets-apply-\(UUID().uuidString)"
        )
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        try RuntimeAssetOptimizationExecutor.execute(
            plan: plan,
            repositoryRoot: repositoryRoot,
            outputRoot: temporaryRoot,
            transformer: transformer
        )
        try RuntimeAssetOptimizationCommitter.commit(
            plan: plan,
            repositoryRoot: repositoryRoot,
            generatedRoot: temporaryRoot
        )
    }
}

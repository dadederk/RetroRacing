//
//  RuntimeAssetOptimizationCommitter.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

enum RuntimeAssetOptimizationCommitter {
    private struct Backup {
        let relativePath: String
        let backupURL: URL
        let existed: Bool
    }

    static func commit(
        plan: RuntimeAssetOptimizationPlan,
        repositoryRoot: URL,
        generatedRoot: URL
    ) throws {
        let backups = try createBackups(
            for: mutationRoots(in: plan),
            repositoryRoot: repositoryRoot,
            backupRoot: generatedRoot.appending(path: ".commit-backup")
        )
        do {
            try install(plan: plan, repositoryRoot: repositoryRoot, generatedRoot: generatedRoot)
        } catch {
            do {
                try restore(backups, repositoryRoot: repositoryRoot)
            } catch let rollbackError {
                throw RuntimeAssetOptimizationError.commitRollbackFailed(
                    commitError: String(describing: error),
                    rollbackError: String(describing: rollbackError)
                )
            }
            throw error
        }
    }

    private static func install(
        plan: RuntimeAssetOptimizationPlan,
        repositoryRoot: URL,
        generatedRoot: URL
    ) throws {
        for action in plan.actions {
            if case let .clearPNGs(directory) = action {
                try RuntimeAssetOptimizationExecutor.clearPNGs(
                    in: repositoryRoot.appending(path: directory)
                )
            }
        }
        for action in plan.actions {
            switch action {
            case let .render(_, destination, _),
                 let .convertTo8Bit(_, destination),
                 let .writeContents(destination, _):
                try copyGeneratedFile(
                    from: generatedRoot.appending(path: destination),
                    to: repositoryRoot.appending(path: destination)
                )
            case let .remove(path):
                let url = repositoryRoot.appending(path: path)
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
            case .clearPNGs:
                break
            }
        }
    }

    private static func copyGeneratedFile(from source: URL, to destination: URL) throws {
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contentsOf: source).write(to: destination, options: .atomic)
    }

    private static func mutationRoots(in plan: RuntimeAssetOptimizationPlan) -> [String] {
        let candidates = plan.actions.compactMap { action -> String? in
            switch action {
            case let .clearPNGs(directory), let .remove(directory):
                directory
            case let .render(_, destination, _),
                 let .convertTo8Bit(_, destination),
                 let .writeContents(destination, _):
                destination
            }
        }
        let ordered = Set(candidates).sorted {
            $0.split(separator: "/").count < $1.split(separator: "/").count
        }
        return ordered.reduce(into: []) { roots, candidate in
            if roots.contains(where: { candidate == $0 || candidate.hasPrefix("\($0)/") }) == false {
                roots.append(candidate)
            }
        }
    }

    private static func createBackups(
        for relativePaths: [String],
        repositoryRoot: URL,
        backupRoot: URL
    ) throws -> [Backup] {
        try FileManager.default.createDirectory(at: backupRoot, withIntermediateDirectories: true)
        return try relativePaths.map { relativePath in
            let source = repositoryRoot.appending(path: relativePath)
            let backup = backupRoot.appending(path: relativePath)
            let existed = FileManager.default.fileExists(atPath: source.path)
            if existed {
                try FileManager.default.createDirectory(
                    at: backup.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try FileManager.default.copyItem(at: source, to: backup)
            }
            return Backup(relativePath: relativePath, backupURL: backup, existed: existed)
        }
    }

    private static func restore(_ backups: [Backup], repositoryRoot: URL) throws {
        for backup in backups.reversed() {
            let destination = repositoryRoot.appending(path: backup.relativePath)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            guard backup.existed else { continue }
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try FileManager.default.copyItem(at: backup.backupURL, to: destination)
        }
    }
}

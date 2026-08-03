//
//  RuntimeAssetOptimizationExecutor.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

enum RuntimeAssetOptimizationExecutor {
    static func execute(
        plan: RuntimeAssetOptimizationPlan,
        repositoryRoot: URL,
        outputRoot: URL,
        transformer: any RuntimeAssetImageTransforming
    ) throws {
        for action in plan.actions {
            switch action {
            case let .clearPNGs(directory):
                try clearPNGs(in: outputRoot.appending(path: directory))
            case let .render(source, destination, maximumLongEdge):
                try transformer.render(
                    source: source,
                    destination: outputRoot.appending(path: destination),
                    maximumLongEdge: maximumLongEdge
                )
            case let .convertTo8Bit(source, destination):
                try transformer.convertTo8Bit(
                    source: source,
                    destination: outputRoot.appending(path: destination)
                )
            case let .writeContents(destination, contents):
                try write(contents: contents, to: outputRoot.appending(path: destination))
            case .remove:
                break
            }
        }
    }

    static func clearPNGs(in directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for url in try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) where url.pathExtension.lowercased() == "png" {
            try FileManager.default.removeItem(at: url)
        }
    }

    private static func write(contents: AssetCatalogContents, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(contents)
        data.append(0x0A)
        try data.write(to: url, options: .atomic)
    }
}

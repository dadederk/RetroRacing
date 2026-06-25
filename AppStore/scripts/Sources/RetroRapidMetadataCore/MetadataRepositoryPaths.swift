//
//  MetadataRepositoryPaths.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public struct MetadataRepositoryPaths: Sendable {
    public let repositoryRoot: URL

    public var defaultCatalog: URL {
        repositoryRoot.appending(path: "AppStore/metadata/retrorapid-v1.5.json")
    }

    public var metadataCopyDocument: URL {
        repositoryRoot.appending(path: "AppStore/docs/05-metadata-copy.md")
    }

    public var validationDocument: URL {
        repositoryRoot.appending(path: "AppStore/docs/12-validation-results.md")
    }

    public static func locate(
        startingAt directory: URL = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath,
            isDirectory: true
        )
    ) throws -> MetadataRepositoryPaths {
        var candidate = directory.standardizedFileURL

        while candidate.path != "/" {
            let catalog = candidate.appending(
                path: "AppStore/metadata/retrorapid-v1.5.json"
            )
            if FileManager.default.fileExists(atPath: catalog.path) {
                return MetadataRepositoryPaths(repositoryRoot: candidate)
            }
            candidate.deleteLastPathComponent()
        }
        throw MetadataToolError.repositoryRootNotFound
    }
}

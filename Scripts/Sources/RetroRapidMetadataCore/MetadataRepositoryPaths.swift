//
//  MetadataRepositoryPaths.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import ScriptSupport

public struct MetadataRepositoryPaths: Sendable {
    public let repositoryRoot: URL

    public init(repositoryRoot: URL) {
        self.repositoryRoot = repositoryRoot
    }

    public var defaultCatalog: URL {
        repositoryRoot.appending(path: "AppStore/metadata/retrorapid-v1.5.json")
    }

    public var metadataCopyDocument: URL {
        repositoryRoot.appending(path: "AppStore/docs/05-metadata-copy.md")
    }

    public var validationDocument: URL {
        repositoryRoot.appending(path: "AppStore/docs/12-validation-results.md")
    }

    public var screenshotStudioProject: URL {
        repositoryRoot.appending(path: "AppStore/RetroRapid.screenshotstudio/project.plist")
    }

    public static func locate(
        startingAt directory: URL = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath,
            isDirectory: true
        )
    ) throws -> MetadataRepositoryPaths {
        let repositoryRoot = try RepositoryLocator.locate(
            containing: ["AppStore/metadata/retrorapid-v1.5.json"],
            startingAt: directory
        )
        return MetadataRepositoryPaths(repositoryRoot: repositoryRoot)
    }
}

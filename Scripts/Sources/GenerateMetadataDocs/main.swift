//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import RetroRapidMetadataCore

do {
    let paths = try MetadataRepositoryPaths.locate()
    if CommandLine.arguments.contains("--check") {
        let catalog = try MetadataCatalogLoader.loadValidatedCatalog(
            from: paths.defaultCatalog
        )
        try MetadataDocumentWorkflow.verifyDocumentsAreCurrent(
            for: catalog,
            paths: paths
        )
    } else {
        let catalog = try MetadataCatalogLoader.loadCatalog(
            from: paths.defaultCatalog
        )
        let repositoryRoot = paths.defaultCatalog
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let validationErrors = MetadataCatalogValidator.validationErrors(
            in: catalog,
            repositoryRoot: repositoryRoot,
            copyDocument: nil,
            validationDocument: nil
        )
        guard validationErrors.isEmpty else {
            throw MetadataToolError.validationFailed(validationErrors)
        }
        try MetadataDocumentWorkflow.generateDocuments(
            from: catalog,
            paths: paths
        )
    }
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}

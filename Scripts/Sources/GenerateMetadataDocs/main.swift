//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import RetroRapidMetadataCore
import ScriptSupport

do {
    let arguments = CLIArguments()
    CLIHelp.exitIfRequested(arguments, usage: CLIUsageTexts.generateMetadataDocs)
    try arguments.rejectUnknownFlags(
        allowing: ["--check"],
        valueFlags: ["--catalog"]
    )
    let paths = try MetadataRepositoryPaths.locate()
    let catalogURL = paths.catalogURL(for: try arguments.value(after: "--catalog"))
    if arguments.contains("--check") {
        let catalog = try MetadataCatalogLoader.loadValidatedCatalog(
            from: catalogURL
        )
        try MetadataDocumentWorkflow.verifyDocumentsAreCurrent(
            for: catalog,
            paths: paths
        )
    } else {
        let catalog = try MetadataCatalogLoader.loadCatalog(
            from: catalogURL
        )
        let validationErrors = MetadataCatalogValidator.validationErrors(
            in: catalog,
            repositoryRoot: paths.repositoryRoot,
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

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
    let catalog = try MetadataCatalogLoader.loadValidatedCatalog(
        from: paths.defaultCatalog
    )

    if CommandLine.arguments.contains("--check") {
        try MetadataDocumentWorkflow.verifyDocumentsAreCurrent(
            for: catalog,
            paths: paths
        )
    } else {
        try MetadataDocumentWorkflow.generateDocuments(
            from: catalog,
            paths: paths
        )
    }
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}

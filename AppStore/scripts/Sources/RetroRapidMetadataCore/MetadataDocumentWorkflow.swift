//
//  MetadataDocumentWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public enum MetadataDocumentWorkflow {
    public static func generateDocuments(
        from catalog: MetadataCatalog,
        paths: MetadataRepositoryPaths
    ) throws {
        for document in generatedDocuments(catalog: catalog, paths: paths) {
            try document.content.write(
                to: document.url,
                atomically: true,
                encoding: .utf8
            )
            print(
                "Updated "
                    + document.url.path.replacingOccurrences(
                        of: paths.repositoryRoot.path + "/",
                        with: ""
                    )
            )
        }
    }

    public static func verifyDocumentsAreCurrent(
        for catalog: MetadataCatalog,
        paths: MetadataRepositoryPaths
    ) throws {
        let stalePaths = generatedDocuments(catalog: catalog, paths: paths)
            .compactMap { document -> String? in
                guard
                    let current = try? String(contentsOf: document.url, encoding: .utf8),
                    current == document.content
                else {
                    return document.url.path.replacingOccurrences(
                        of: paths.repositoryRoot.path + "/",
                        with: ""
                    )
                }
                return nil
            }

        guard stalePaths.isEmpty else {
            throw MetadataToolError.generatedDocumentsOutOfDate(stalePaths)
        }
        print("Metadata catalog and generated documentation are valid and in sync.")
    }

    private static func generatedDocuments(
        catalog: MetadataCatalog,
        paths: MetadataRepositoryPaths
    ) -> [GeneratedDocument] {
        [
            GeneratedDocument(
                url: paths.metadataCopyDocument,
                content: MetadataCopyRenderer.render(catalog: catalog)
            ),
            GeneratedDocument(
                url: paths.validationDocument,
                content: MetadataValidationRenderer.render(catalog: catalog)
            ),
        ]
    }
}

private struct GeneratedDocument {
    let url: URL
    let content: String
}

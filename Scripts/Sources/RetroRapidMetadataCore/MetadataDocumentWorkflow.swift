//
//  MetadataDocumentWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import ScriptSupport

public enum MetadataDocumentWorkflow {
    public static func generateDocuments(
        from catalog: MetadataCatalog,
        paths: MetadataRepositoryPaths
    ) throws {
        let documents = generatedDocuments(catalog: catalog, paths: paths)
        try FileWork.writeAtomically(
            documents.map {
                GeneratedFile(url: $0.url, data: Data($0.content.utf8))
            }
        )
        for document in documents {
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
        let stalePaths = FileWork.staleFiles(
            among: generatedDocuments(catalog: catalog, paths: paths).map {
                GeneratedFile(url: $0.url, data: Data($0.content.utf8))
            },
            relativeTo: paths.repositoryRoot
        )

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

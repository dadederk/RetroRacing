//
//  RepositoryLocator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public enum RepositoryLocator {
    public static func locate(
        containing markerPaths: [String],
        startingAt directory: URL = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath,
            isDirectory: true
        )
    ) throws -> URL {
        var candidate = directory.standardizedFileURL

        while candidate.path != "/" {
            let containsEveryMarker = markerPaths.allSatisfy { marker in
                FileManager.default.fileExists(
                    atPath: candidate.appending(path: marker).path
                )
            }
            if containsEveryMarker {
                return candidate
            }
            candidate.deleteLastPathComponent()
        }
        throw ScriptSupportError.repositoryRootNotFound(markerPaths)
    }
}

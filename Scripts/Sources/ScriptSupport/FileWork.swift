//
//  FileWork.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public struct GeneratedFile: Sendable {
    public let url: URL
    public let data: Data

    public init(url: URL, data: Data) {
        self.url = url
        self.data = data
    }
}

public enum FileWork {
    public static func writeAtomically(_ files: [GeneratedFile]) throws {
        for file in files {
            try FileManager.default.createDirectory(
                at: file.url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try file.data.write(to: file.url, options: .atomic)
        }
    }

    public static func staleFiles(
        among files: [GeneratedFile],
        relativeTo root: URL
    ) -> [String] {
        files.compactMap { file in
            guard (try? Data(contentsOf: file.url)) == file.data else {
                return relativePath(for: file.url, from: root)
            }
            return nil
        }
    }

    public static func relativePath(for url: URL, from root: URL) -> String {
        url.path.replacingOccurrences(of: root.path + "/", with: "")
    }
}

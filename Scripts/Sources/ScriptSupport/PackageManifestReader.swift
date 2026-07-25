//
//  PackageManifestReader.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public enum PackageManifestReader {
    /// Parses executable product names from `Scripts/Package.swift`, excluding `retrorapid`.
    public static func executableProductNames(
        packageManifestURL: URL
    ) throws -> [String] {
        let contents = try String(contentsOf: packageManifestURL, encoding: .utf8)
        var names: [String] = []
        var searchStart = contents.startIndex

        while let executableRange = contents.range(
            of: ".executable(",
            range: searchStart ..< contents.endIndex
        ) {
            let snippetEnd = contents.index(
                executableRange.lowerBound,
                offsetBy: 400,
                limitedBy: contents.endIndex
            ) ?? contents.endIndex
            let snippet = String(contents[executableRange.lowerBound ..< snippetEnd])
            if let name = quotedValue(after: "name:", in: snippet), name != "retrorapid" {
                names.append(name)
            }
            searchStart = executableRange.upperBound
        }

        let uniqueNames = Array(Set(names)).sorted()
        guard uniqueNames.isEmpty == false else {
            throw ScriptSupportError.repositoryRootNotFound(["Scripts/Package.swift executable products"])
        }
        return uniqueNames
    }

    private static func quotedValue(after key: String, in snippet: String) -> String? {
        guard let keyRange = snippet.range(of: key) else { return nil }
        let afterKey = snippet[keyRange.upperBound...]
        guard let openQuote = afterKey.firstIndex(of: "\"") else { return nil }
        let valueStart = afterKey.index(after: openQuote)
        guard let closeQuote = afterKey[valueStart...].firstIndex(of: "\"") else { return nil }
        return String(afterKey[valueStart ..< closeQuote])
    }
}

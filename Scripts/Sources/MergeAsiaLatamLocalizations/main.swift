//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/07/2026.
//

import Foundation

struct StringCatalog: Codable {
    var sourceLanguage: String
    var strings: [String: StringEntry]
    var version: String
}

struct StringEntry: Codable {
    var extractionState: String?
    var localizations: [String: LocalizationUnit]?
}

struct LocalizationUnit: Codable {
    var stringUnit: StringUnit
}

struct StringUnit: Codable {
    var state: String
    var value: String
}

struct AsiaLatamBundle: Codable {
    // key -> locale -> value
}

private let targetLocales = ["ja", "ko", "pt-BR", "zh-Hant"]

@main
enum MergeAsiaLatamLocalizations {
    static func main() throws {
        let fileManager = FileManager.default
        let repoRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let catalogURL = repoRoot
            .appending(path: "RetroRacing/RetroRacingShared/Localizable.xcstrings")
        let bundleURL = repoRoot
            .appending(path: "Scripts/Resources/asia_latam_localizations.json")

        let catalogData = try Data(contentsOf: catalogURL)
        var catalog = try JSONDecoder().decode(StringCatalog.self, from: catalogData)

        let bundleData = try Data(contentsOf: bundleURL)
        let translations = try JSONDecoder().decode(
            [String: [String: String]].self,
            from: bundleData
        )

        var mergedCount = 0
        var missingKeys: [String] = []

        for (key, localeValues) in translations.sorted(by: { $0.key < $1.key }) {
            guard var entry = catalog.strings[key] else {
                missingKeys.append(key)
                continue
            }
            var localizations = entry.localizations ?? [:]
            for locale in targetLocales {
                guard let value = localeValues[locale], !value.isEmpty else { continue }
                localizations[locale] = LocalizationUnit(
                    stringUnit: StringUnit(state: "translated", value: value)
                )
                mergedCount += 1
            }
            entry.localizations = localizations
            catalog.strings[key] = entry
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(catalog).write(to: catalogURL, options: .atomic)

        print("Merged \(mergedCount) localization values into \(catalogURL.path)")
        if !missingKeys.isEmpty {
            print("Warning: \(missingKeys.count) bundle keys not found in catalog:")
            for key in missingKeys.prefix(10) {
                print("  - \(key)")
            }
        }

        var catalogKeys = Set(catalog.strings.keys)
        var bundleOnly = Set(translations.keys).subtracting(catalogKeys)
        if !bundleOnly.isEmpty {
            print("Warning: \(bundleOnly.count) bundle keys not in catalog")
        }

        var incomplete: [String] = []
        for key in catalogKeys.sorted() {
            guard let entry = catalog.strings[key] else { continue }
            let locs = entry.localizations ?? [:]
            for locale in targetLocales {
                if locs[locale] == nil {
                    incomplete.append("\(key) [\(locale)]")
                }
            }
        }
        if incomplete.isEmpty {
            print("All \(targetLocales.joined(separator: ", ")) entries present.")
        } else {
            print("Missing \(incomplete.count) entries:")
            for item in incomplete.prefix(20) {
                print("  - \(item)")
            }
        }
    }
}

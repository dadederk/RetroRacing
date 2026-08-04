//
//  TurkishPolishLocalizationTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation
import Testing

@Test
func givenTurkishAndPolishDraftsWhenComparingWithStringCatalogThenEveryKeyIsCovered() throws {
    let root = repositoryRoot()
    let reviewBundle = try loadJSON(
        root.appending(path: "Scripts/Resources/turkish_polish_localizations.json")
    )
    let stringCatalog = try loadJSON(
        root.appending(path: "RetroRacing/RetroRacingShared/Localizable.xcstrings")
    )

    #expect(reviewBundle["reviewStatus"] as? String == "NEEDS_NATIVE_REVIEW")

    let drafts = try #require(reviewBundle["localizations"] as? [String: Any])
    let strings = try #require(stringCatalog["strings"] as? [String: Any])
    #expect(drafts.count == 363)
    #expect(Set(drafts.keys) == Set(strings.keys))

    for key in strings.keys.sorted() {
        let draftLocales = try #require(drafts[key] as? [String: String])
        #expect(Set(draftLocales.keys) == ["tr", "pl"])

        let stringEntry = try #require(strings[key] as? [String: Any])
        let localizations = try #require(stringEntry["localizations"] as? [String: Any])
        for locale in ["tr", "pl"] {
            let localization = try #require(localizations[locale] as? [String: Any])
            let stringUnit = try #require(localization["stringUnit"] as? [String: String])
            #expect(stringUnit["state"] == "needs_review")
            #expect(stringUnit["value"] == draftLocales[locale])
            if key.isEmpty == false {
                #expect(draftLocales[locale]?.isEmpty == false)
            }
        }
    }
}

@Test
func givenTurkishAndPolishDraftsWhenCheckingFormatSpecifiersThenSourcePlaceholdersArePreserved() throws {
    let root = repositoryRoot()
    let reviewBundle = try loadJSON(
        root.appending(path: "Scripts/Resources/turkish_polish_localizations.json")
    )
    let stringCatalog = try loadJSON(
        root.appending(path: "RetroRacing/RetroRacingShared/Localizable.xcstrings")
    )
    let drafts = try #require(reviewBundle["localizations"] as? [String: Any])
    let strings = try #require(stringCatalog["strings"] as? [String: Any])

    for key in strings.keys.sorted() {
        let entry = try #require(strings[key] as? [String: Any])
        let localizations = entry["localizations"] as? [String: Any]
        let english = ((localizations?["en"] as? [String: Any])?["stringUnit"] as? [String: String])?["value"]
        let expected = canonicalPlaceholders(in: english ?? key)
        let draftLocales = try #require(drafts[key] as? [String: String])
        for locale in ["tr", "pl"] {
            let value = try #require(draftLocales[locale])
            #expect(canonicalPlaceholders(in: value) == expected)
        }
    }
}

@Test
func givenTurkishAndPolishDraftsWhenCheckingBundleAndProjectThenBothRegionsAreDeclared() throws {
    let root = repositoryRoot()
    let plistURL = root.appending(path: "RetroRacing/Config/RetroRacingUniversalInfo.plist")
    let plistData = try Data(contentsOf: plistURL)
    let plist = try #require(
        PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]
    )
    let localizations = try #require(plist["CFBundleLocalizations"] as? [String])
    #expect(localizations.contains("tr"))
    #expect(localizations.contains("pl"))

    let project = try String(
        contentsOf: root.appending(path: "RetroRacing/RetroRacing.xcodeproj/project.pbxproj"),
        encoding: .utf8
    )
    #expect(project.contains("\n\t\t\t\ttr,"))
    #expect(project.contains("\n\t\t\t\tpl,"))
}

private func repositoryRoot() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}

private func loadJSON(_ url: URL) throws -> [String: Any] {
    let data = try Data(contentsOf: url)
    return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
}

private func canonicalPlaceholders(in value: String) -> [String] {
    let pattern = #"%(?:(\d+)\$)?(@|lld|%)"#
    guard let expression = try? NSRegularExpression(pattern: pattern) else {
        return []
    }
    let range = NSRange(value.startIndex..., in: value)
    return expression.matches(in: value, range: range).compactMap { match in
        guard let kindRange = Range(match.range(at: 2), in: value) else {
            return nil
        }
        return "%" + value[kindRange]
    }.sorted()
}

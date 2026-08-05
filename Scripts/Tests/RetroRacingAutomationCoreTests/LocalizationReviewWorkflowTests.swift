//
//  LocalizationReviewWorkflowTests.swift
//  RetroRacingAutomationCoreTests
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation
import Testing

@testable import RetroRacingAutomationCore

@Test
func givenCanonicalSourcesWhenAuditingThenEveryLocaleHasCompleteInAppCoverage() throws {
    let root = try repositoryRoot()
    let snapshots = try LocalizationReviewWorkflow.audit(
        repositoryRoot: root,
        locale: nil,
        requireApproval: false
    )

    #expect(snapshots.count == 20)
    #expect(snapshots.allSatisfy { snapshot in
        snapshot.items.filter { $0.layer == "In-app" }.count == 363
    })
    #expect(snapshots.allSatisfy { $0.items.count == 518 })
    #expect(snapshots.allSatisfy { snapshot in
        Set(snapshot.items.map(\.layer)) == [
            "In-app", "App Store metadata", "IAP", "Game Center",
            "Screenshots", "TestFlight",
        ]
    })
    #expect(snapshots.first { $0.locale == "es-MX" }?.record.catalogLocale == "es-MX")

    let english = try #require(snapshots.first { $0.locale == "en-US" })
    #expect(english.items.contains { item in
        item.identifier.hasSuffix("overtakes.0100.name")
            && item.english == "Streak 100"
            && item.translation == "Streak 100"
    })
    #expect(english.items.contains { item in
        item.identifier.hasSuffix("bestios001cruise.displayName")
            && item.translation == "iPhone High Score - Cruise"
    })
}

@Test
func givenStringCatalogWhenReviewWaveIsOpenThenAllNonEnglishUnitsNeedReview() throws {
    let root = try repositoryRoot()
    let url = root.appending(path: LocalizationReviewCollector.catalogRelativePath)
    let object = try #require(
        try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
    )
    let strings = try #require(object["strings"] as? [String: Any])
    let locales = [
        "de", "nl", "it", "fr", "fr-CA", "es", "es-MX", "ca",
        "ja", "ko", "pt-BR", "pt-PT", "zh-Hant", "zh-Hans", "tr", "pl",
    ]

    for locale in locales {
        let units = strings.values.compactMap { entry -> [String: Any]? in
            let localizations = (entry as? [String: Any])?["localizations"] as? [String: Any]
            return (localizations?[locale] as? [String: Any])?["stringUnit"] as? [String: Any]
        }
        #expect(units.count == 363, "Expected full coverage for \(locale)")
        #expect(units.allSatisfy { $0["state"] as? String == "needs_review" })
    }
}

@Test
func givenMexicanSpanishWhenCheckingBundleAndProjectThenRegionIsDeclared() throws {
    let root = try repositoryRoot()
    let plistData = try Data(
        contentsOf: root.appending(path: "RetroRacing/Config/RetroRacingUniversalInfo.plist")
    )
    var format = PropertyListSerialization.PropertyListFormat.xml
    let plistObject = try PropertyListSerialization.propertyList(
        from: plistData,
        options: [],
        format: &format
    )
    let plist = try #require(plistObject as? [String: Any])
    let bundleLocales = try #require(plist["CFBundleLocalizations"] as? [String])
    let project = try String(
        contentsOf: root.appending(path: "RetroRacing/RetroRacing.xcodeproj/project.pbxproj"),
        encoding: .utf8
    )

    #expect(bundleLocales.contains("es-MX"))
    #expect(project.contains("\"es-MX\","))
}

@Test
func givenPendingReviewsWhenRequiringApprovalThenReleaseGateFails() throws {
    let root = try repositoryRoot()

    #expect(throws: LocalizationReviewError.self) {
        _ = try LocalizationReviewWorkflow.audit(
            repositoryRoot: root,
            locale: "tr",
            requireApproval: true
        )
    }
}

@Test
func givenGeneratedReviewSheetsWhenCheckingThenArtifactsAreDeterministic() throws {
    let root = try repositoryRoot()
    let snapshots = try LocalizationReviewWorkflow.renderReviews(
        repositoryRoot: root,
        locale: nil,
        check: true
    )

    #expect(snapshots.count == 20)
    #expect(snapshots.allSatisfy { $0.digest.count == 64 })
}

@Test
func givenCopyChangeWhenDigestingThenApprovalDigestIsInvalidated() {
    let original = LocalizationReviewItem(
        layer: "In-app",
        identifier: "play",
        english: "Play",
        translation: "Jugar",
        state: "needs_review"
    )
    let changed = LocalizationReviewItem(
        layer: "In-app",
        identifier: "play",
        english: "Play",
        translation: "Juega",
        state: "needs_review"
    )

    #expect(LocalizationContentDigest.value(for: [original]) != LocalizationContentDigest.value(for: [changed]))
}

@Test
func givenReviewCopyWhenCheckingRegisterAndDialectThenKnownLeakageIsAbsent() throws {
    let snapshots = try LocalizationReviewCollector.snapshots(
        repositoryRoot: repositoryRoot()
    )
    let copy = Dictionary(uniqueKeysWithValues: snapshots.map { snapshot in
        (snapshot.locale, snapshot.items.map(\.translation).joined(separator: "\n"))
    })

    let canadianFrench = copy["fr-CA"]?.lowercased() ?? ""
    #expect(canadianFrench.contains(" tu ") == false)
    #expect(canadianFrench.contains(" tes ") == false)
    for informalPossessive in ["ton meilleur", "ton ami", "ton soutien", "ton thème", "ta limite"] {
        #expect(canadianFrench.contains(informalPossessive) == false)
    }
    for malformed in ["connecte-vous", "prépare-vous", "êvos", "vous es ", "votre de", "vous te ", "vous dois"] {
        #expect(canadianFrench.contains(malformed) == false, "Found malformed Canadian French: \(malformed)")
    }

    let europeanPortuguese = copy["pt-PT"]?.lowercased() ?? ""
    #expect(europeanPortuguese.contains("você") == false)
    #expect(europeanPortuguese.contains("vocês") == false)
    #expect(europeanPortuguese.contains("mouse") == false)
    #expect(europeanPortuguese.contains("retrô") == false)

    let valencian = copy["ca"]?.lowercased() ?? ""
    for forbidden in ["teva", "seva", "avui", "aquest", "aquí", "reloj", "correixes", "hem polix"] {
        #expect(valencian.contains(forbidden) == false, "Found non-Valencian form: \(forbidden)")
    }

    let traditionalChinese = copy["zh-Hant"] ?? ""
    #expect(traditionalChinese.contains("与") == false)
    #expect((copy["de-DE"] ?? "").contains("Weiche Verkehr") == false)

    let french = try #require(snapshots.first { $0.locale == "fr-FR" })
    let canadian = try #require(snapshots.first { $0.locale == "fr-CA" })
    let localizedDifferences = zip(french.items, canadian.items).filter { pair in
        pair.0.translation != pair.1.translation
    }
    #expect(localizedDifferences.count >= 50)
}

@Test
func givenReviewSheetWhenRenderedThenCSVIsUTF8AndProperlyQuoted() throws {
    let snapshot = LocalizationReviewSnapshot(
        locale: "pl",
        record: LocalizationReviewRecord(
            catalogLocale: "pl",
            guidance: "Polski",
            status: .needsReview,
            reviewer: nil,
            reviewedAt: nil,
            notes: nil,
            approvedContentDigest: nil
        ),
        items: [
            LocalizationReviewItem(
                layer: "In-app",
                identifier: "example",
                english: "One, two",
                translation: "Raz, dwa — żółć",
                state: "needs_review"
            ),
        ]
    )
    let csv = LocalizationReviewRenderer.csv(for: snapshot)

    #expect(csv.contains("\"One, two\""))
    #expect(csv.contains("żółć"))
    #expect(Data(csv.utf8).isEmpty == false)
}

private func repositoryRoot() throws -> URL {
    var url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    while url.path != "/" {
        if FileManager.default.fileExists(
            atPath: url.appending(path: LocalizationReviewCollector.manifestRelativePath).path
        ) {
            return url
        }
        url.deleteLastPathComponent()
    }
    throw LocalizationReviewError.missingManifestLocale("repository root")
}

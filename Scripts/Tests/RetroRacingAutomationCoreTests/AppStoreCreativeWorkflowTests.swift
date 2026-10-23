//
//  AppStoreCreativeWorkflowTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 18/10/2026.
//

import Foundation
import ScriptSupport
import Testing

@testable import RetroRacingAutomationCore

@Test
func givenEveryCreativeLocaleWhenPlanningHeadlineThenCopyFitsAtSearchSize() throws {
    let entries = try ScreenshotStudioWorkflow.localizationEntries(
        slideIndex: 0,
        watchSequenceOnly: false
    )

    for entry in entries {
        let locale = try #require(entry["language"])
        let title = try #require(entry["title"])
        let layout = try AppStoreCreativeHeadlineLayout.plan(text: title, locale: locale)

        #expect(layout.lines.isEmpty == false)
        #expect(layout.lines.count <= 3)
        #expect(layout.fontSize == 270)
    }
}

@Test
func givenEnglishHeadlineWhenPlanningThenBalancedBreakMatchesApprovedComposition() throws {
    let layout = try AppStoreCreativeHeadlineLayout.plan(
        text: "Race Through Endless Traffic",
        locale: "en-US"
    )

    #expect(layout.lines == ["Race Through", "Endless Traffic"])
}

@Test
func givenRepositoryLocalizationManifestWhenBuildingHelmManifestThenEveryLocaleHasBothAssets() throws {
    let repositoryRoot = try RepositoryLocator.locate(
        containing: ["AppStore/localization/review-status.json"]
    )
    let manifest = try AppStoreCreativeWorkflow.uploadManifest(
        repositoryRoot: repositoryRoot
    )

    #expect(manifest.assets.count == ScreenshotStudioWorkflow.locales.count * 2)
    #expect(Set(manifest.assets.map(\.locale)) == Set(ScreenshotStudioWorkflow.locales))
    #expect(Set(manifest.assets.map(\.kind)) == ["header", "search-results"])
    #expect(
        Set(manifest.assets.filter { $0.kind == "header" }.map(\.path))
            == [AppStoreCreativeWorkflow.headerRelativePath]
    )
    #expect(manifest.assets.allSatisfy { $0.localizationStatus == "NEEDS_REVIEW" })
}

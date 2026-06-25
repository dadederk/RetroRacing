//
//  MetadataCatalogTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import Testing
@testable import RetroRapidMetadataCore

@Test
func givenCanonicalCatalogWhenValidatingThenNoErrorsAreReturned() throws {
    let catalog = try loadCanonicalCatalog()

    let errors = MetadataCatalogValidator.validationErrors(in: catalog)

    #expect(errors.isEmpty)
}

@Test
func givenCanonicalCatalogWhenRenderingThenGeneratedDocumentsAreCurrent() throws {
    let paths = try repositoryPaths()
    let catalog = try MetadataCatalogLoader.loadValidatedCatalog(
        from: paths.defaultCatalog
    )

    let metadataCopy = MetadataCopyRenderer.render(catalog: catalog)
    let validation = MetadataValidationRenderer.render(catalog: catalog)

    #expect(
        try String(contentsOf: paths.metadataCopyDocument, encoding: .utf8)
            == metadataCopy
    )
    #expect(
        try String(contentsOf: paths.validationDocument, encoding: .utf8)
            == validation
    )
}

@Test
func givenLocaleWhenBuildingVersionCommandThenAppInfoIsNotIncluded() throws {
    let locale = try loadCanonicalCatalog().locales["en-US"]
    let requiredLocale = try #require(locale)

    let arguments = HelmMetadataWorkflow.commandArguments(
        locale: requiredLocale,
        localizationID: "localization-id",
        includeAppInfo: false,
        keywordsOnly: false
    )

    #expect(!arguments.contains("--name"))
    #expect(!arguments.contains("--subtitle"))
    #expect(arguments.contains("--description"))
    #expect(arguments.contains("--whats-new"))
}

@Test
func givenLocaleWhenBuildingAppInfoCommandThenNameAndSubtitleAreIncluded() throws {
    let locale = try loadCanonicalCatalog().locales["en-US"]
    let requiredLocale = try #require(locale)

    let arguments = HelmMetadataWorkflow.commandArguments(
        locale: requiredLocale,
        localizationID: "localization-id",
        includeAppInfo: true,
        keywordsOnly: false
    )

    #expect(arguments.contains("--name"))
    #expect(arguments.contains(requiredLocale.name))
    #expect(arguments.contains("--subtitle"))
    #expect(arguments.contains(requiredLocale.subtitle))
}

@Test
func givenInvalidKeywordsWhenValidatingThenEveryRuleIsReported() {
    let errors = MetadataKeywordRules.keywordRuleErrors(
        locale: "en-US",
        appName: "RetroRapid: Arcade Racer",
        subtitle: "Dodge Traffic",
        keywords: "dodge, Dodge, a,, spaced "
    )

    #expect(errors.contains { $0.contains("empty token") })
    #expect(errors.contains { $0.contains("whitespace") })
    #expect(errors.contains { $0.contains("greater than two characters") })
    #expect(errors.contains { $0.contains("duplicates") })
    #expect(errors.contains { $0.contains("visible") })
}

@Test
func givenAllowlistedShortKeywordWhenValidatingThenItIsAccepted() {
    let errors = MetadataKeywordRules.keywordRuleErrors(
        locale: "en-US",
        appName: "RetroRapid: Arcade Racer",
        subtitle: "Dodge Traffic",
        keywords: "overtake,ai",
        allowedShortKeywords: ["ai"]
    )

    #expect(errors.isEmpty)
}

private func loadCanonicalCatalog() throws -> MetadataCatalog {
    let paths = try repositoryPaths()
    return try MetadataCatalogLoader.loadValidatedCatalog(
        from: paths.defaultCatalog
    )
}

private func repositoryPaths() throws -> MetadataRepositoryPaths {
    let testsFile = URL(fileURLWithPath: #filePath)
    let repositoryRoot = testsFile
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    return try MetadataRepositoryPaths.locate(startingAt: repositoryRoot)
}

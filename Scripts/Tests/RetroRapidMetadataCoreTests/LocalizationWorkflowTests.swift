//
//  LocalizationWorkflowTests.swift
//  RetroRapidMetadataCoreTests
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import Testing

@testable import RetroRapidMetadataCore

@Test
func givenGameCenterCatalogsWhenCheckingThenValidationPassesWithoutCredentials() throws {
    let paths = try MetadataRepositoryPaths.locate()
    let options = GameCenterEULocalizationApplyOptions(
        appID: "6758641625",
        achievementsCatalogRelativePath: "AppStore/game-center/achievements-eu-localizations.json",
        leaderboardsCatalogRelativePath: "AppStore/game-center/leaderboards-eu-localizations.json",
        includeAchievements: true,
        includeLeaderboards: true,
        dryRun: false
    )

    try GameCenterEULocalizationWorkflow.check(
        repositoryRoot: paths.repositoryRoot,
        options: options
    )
}

@Test
func givenIAPBundleWhenCheckingThenValidationPassesWithoutCredentials() throws {
    let paths = try MetadataRepositoryPaths.locate()
    let options = IAPLocalizationApplyOptions(
        helmPath: HelmCLI.defaultPath,
        iapID: "6759012658",
        bundleRelativePath: "AppStore/iap-localizations/6759012658",
        locales: [
            "de-DE", "nl-NL", "it", "fr-FR", "fr-CA", "es-ES", "es-MX", "ca",
            "ja", "ko", "pt-BR", "pt-PT", "zh-Hant", "zh-Hans",
        ],
        dryRun: false,
        preferAppStoreConnectAPI: false
    )

    try IAPLocalizationWorkflow.check(
        repositoryRoot: paths.repositoryRoot,
        options: options
    )
}

@Test
func givenMissingCredentialsMessageWhenRenderedThenIncludesRequiredEnvironmentVariables() {
    let message = AppStoreConnectCredentialsLoader.missingCredentialsMessage(
        from: [:],
        includeKeychain: false
    )
    #expect(message.contains("ASC_KEY_ID") || message.contains("APP_STORE_CONNECT_KEY_ID"))
    #expect(message.contains("credentials") || message.contains("key ID"))
}

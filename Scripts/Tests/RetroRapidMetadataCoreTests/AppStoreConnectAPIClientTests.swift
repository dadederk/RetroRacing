//
//  AppStoreConnectAPIClientTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import Testing
@testable import RetroRapidMetadataCore

@Test
func givenLocalizationLinkagesWhenParsingThenIDsResolve() {
    let json: [String: Any] = [
        "data": [
            [
                "type": "inAppPurchaseLocalizations",
                "id": "loc-de",
            ],
            [
                "type": "inAppPurchaseLocalizations",
                "id": "loc-fr",
            ],
        ],
    ]

    #expect(AppStoreConnectAPIClient.localizationResourceIDs(from: json) == ["loc-de", "loc-fr"])
}

@Test
func givenLocalizationDetailWhenParsingThenLocaleMaps() {
    let json: [String: Any] = [
        "data": [
            "id": "loc-de",
            "type": "inAppPurchaseLocalizations",
            "attributes": [
                "locale": "de-DE",
                "name": "Unbegrenzte Spiele",
            ],
        ],
    ]

    let pair = AppStoreConnectAPIClient.localeByLocalizationID(from: json)
    #expect(pair?.id == "loc-de")
    #expect(pair?.locale == "de-DE")
}

@Test
func givenVersionListWhenParsingThenDraftVersionIDResolves() {
    let json: [String: Any] = [
        "data": [
            [
                "type": "inAppPurchaseVersions",
                "id": "approved-version",
                "attributes": ["state": "APPROVED"],
            ],
            [
                "type": "inAppPurchaseVersions",
                "id": "draft-version",
                "attributes": ["state": "PREPARE_FOR_SUBMISSION"],
            ],
        ],
    ]

    #expect(AppStoreConnectAPIClient.draftVersionID(from: json) == "draft-version")
}

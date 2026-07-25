//
//  AppStoreConnectCredentialsTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import Testing
@testable import RetroRapidMetadataCore

@Test
func givenEnvironmentVariablesWhenLoadingCredentialsThenValuesResolve() throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    let keyURL = temporaryDirectory.appending(path: "AuthKey_TEST.p8")
    try "test-key".write(to: keyURL, atomically: true, encoding: .utf8)

    let credentials = try #require(
        AppStoreConnectCredentialsLoader.load(
            from: [
                "ASC_KEY_ID": "TEST",
                "ASC_ISSUER_ID": "issuer-123",
                "ASC_PRIVATE_KEY": keyURL.path,
            ]
        )
    )

    #expect(credentials.keyID == "TEST")
    #expect(credentials.issuerID == "issuer-123")
    #expect(credentials.privateKeyURL == keyURL)
}

@Test
func givenMissingKeyIDWhenExplainingCredentialsThenMessageNamesKeyID() {
    let message = AppStoreConnectCredentialsLoader.missingCredentialsMessage(from: [:])
    #expect(message.contains("missing key ID"))
    #expect(message.contains("ASC_KEY_ID"))
}

@Test
func givenMissingPrivateKeyFileWhenExplainingCredentialsThenMessageNamesPath() {
    let message = AppStoreConnectCredentialsLoader.missingCredentialsMessage(
        from: [
            "ASC_KEY_ID": "TEST",
            "ASC_ISSUER_ID": "issuer-123",
            "ASC_PRIVATE_KEY": "/tmp/does-not-exist.p8",
        ]
    )
    #expect(message.contains("private key file missing"))
    #expect(message.contains("AuthKey_TEST.p8"))
}

@Test
func givenCSVBundleWhenReadingLocalizationThenFieldValuesResolve() throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appending(path: UUID().uuidString)
    let localeDirectory = temporaryDirectory.appending(path: "de-DE")
    try FileManager.default.createDirectory(at: localeDirectory, withIntermediateDirectories: true)
    let csvURL = localeDirectory.appending(path: "metadata.csv")
    try """
    field,value
    name,Unbegrenzte Spiele
    description,Spiele unbegrenzt und unterstütze RetroRapid!
    """.write(to: csvURL, atomically: true, encoding: .utf8)

    let rows = try CSVDictionaryReader.read(url: csvURL)
    #expect(rows["name"] == "Unbegrenzte Spiele")
    #expect(rows["description"] == "Spiele unbegrenzt und unterstütze RetroRapid!")
}

@Test
func givenJWTInputsWhenEncodingBase64URLThenPaddingIsStripped() {
    let encoded = AppStoreConnectJWT.base64URLEncode(Data("test".utf8))
    #expect(encoded.contains("=") == false)
    #expect(encoded.contains("+") == false)
}

//
//  AppStoreConnectAssetUploadTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import Testing

@testable import RetroRapidMetadataCore

@Test
func givenTemplateURLWhenResolvedThenPlaceholdersExpand() {
    let url = AppStoreConnectAssetUpload.resolvedTemplateURL(
        templateURL: "https://example.test/{w}x{h}.{f}",
        width: 1024,
        height: 1024,
        fileExtension: "png"
    )

    #expect(url?.absoluteString == "https://example.test/1024x1024.png")
}

@Test
func givenAssetDataWhenHashingThenMD5ChecksumIsLowercaseHex() {
    let checksum = AppStoreConnectAssetUpload.md5Checksum(for: Data("test".utf8))
    #expect(checksum == "098f6bcd4621d373cade4e832627b4f6")
}

@Test
func givenUploadOperationsJSONWhenParsingThenMethodAndURLResolve() {
    let resource: [String: Any] = [
        "attributes": [
            "uploadOperations": [
                [
                    "method": "PUT",
                    "url": "https://upload.example.test/asset",
                    "requestHeaders": [
                        ["name": "Content-Type", "value": "image/png"],
                    ],
                ],
            ],
        ],
    ]

    let operations = AppStoreConnectAssetUpload.uploadOperations(from: resource)
    #expect(operations.count == 1)
    #expect(operations[0].method == "PUT")
    #expect(operations[0].url.absoluteString == "https://upload.example.test/asset")
    #expect(operations[0].requestHeaders.first?.0 == "Content-Type")
    #expect(operations[0].requestHeaders.first?.1 == "image/png")
}

@Test
func givenAppStoreConnectImageJSONWhenParsingThenTemplateUrlResolves() {
    let resource: [String: Any] = [
        "type": "gameCenterLeaderboardImages",
        "id": "482f6124-4570-43a0-aa5e-ec289ba6faf8",
        "attributes": [
            "fileName": "LeaderboardIphoneCruise.png",
            "imageAsset": [
                "templateUrl": "https://example.test/{w}x{h}bb.{f}",
                "width": 1024,
                "height": 1024,
            ],
            "assetDeliveryState": [
                "state": "COMPLETE",
            ],
        ],
    ]

    let parsed = AppStoreConnectAssetUpload.sourceImageDownload(fromImageResource: resource)
    #expect(parsed?.fileName == "LeaderboardIphoneCruise.png")
    #expect(parsed?.downloadURL.absoluteString == "https://example.test/1024x1024bb.png")
}

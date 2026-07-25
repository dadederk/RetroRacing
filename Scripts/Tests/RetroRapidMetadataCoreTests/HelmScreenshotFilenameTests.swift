//
//  HelmScreenshotFilenameTests.swift
//  RetroRapidMetadataCoreTests
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation
import ScriptSupport
import Testing

@testable import RetroRapidMetadataCore

@Test
func givenHelmDownloadFilenameWhenReadingPositionThenEmbeddedIndexIsReturned() {
    #expect(HelmScreenshotFilename.position(in: "en-US_display_65_03.jpeg") == 3)
    #expect(HelmScreenshotFilename.position(in: "03_en-US_display_65_03.jpeg") == 3)
    #expect(HelmScreenshotFilename.position(in: "de-DE_display_69_07.jpeg") == 7)
}

@Test
func givenHelmPlatformWhenReadingDeviceTypesThenExpectedSetsAreReturned() {
    #expect(HelmScreenshotPlatform.iphone.deviceTypes.contains("APP_IPHONE_65"))
    #expect(HelmScreenshotPlatform.ipad.deviceTypes.contains("APP_IPAD_PRO_3GEN_129"))
    #expect(HelmScreenshotPlatform.mac.deviceTypes.contains("APP_DESKTOP"))
}

@Test
func givenVersionSummariesWhenResolvingDraftIOSThenPreferredStateWins() throws {
    let json = """
    [
      {"id":"live","platform":"IOS","state":"READY_FOR_SALE","versionString":"1.5"},
      {"id":"draft","platform":"IOS","state":"PREPARE_FOR_SUBMISSION","versionString":"1.5"}
    ]
    """
    let versions = try JSONDecoder().decode([HelmAppVersionSummary].self, from: json.data(using: .utf8)!)
    let match = versions.first {
        $0.platform == "IOS"
            && $0.versionString == "1.5"
            && $0.state == "PREPARE_FOR_SUBMISSION"
    }
    #expect(match?.id == "draft")
}

@Test
func givenSwapOptionsParserWhenPositionsMatchThenValidationFails() throws {
    do {
        _ = try HelmScreenshotSwapOptionsParser.parse(
            CLIArguments(["--first", "3", "--second", "3"])
        )
        Issue.record("Expected identical positions to fail validation.")
    } catch let error as MetadataToolError {
        #expect(String(describing: error).contains("different positions"))
    }
}

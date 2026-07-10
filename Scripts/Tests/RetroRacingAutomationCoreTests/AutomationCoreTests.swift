//
//  AutomationCoreTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import AppKit
import Foundation
import Testing
@testable import RetroRacingAutomationCore
import ScriptSupport

@Test
func givenDefaultTestOptionsWhenBuildingCommandsThenBothTestTargetsAreIncluded() {
    let root = URL(fileURLWithPath: "/repository")
    let options = TestRunnerOptions(
        destination: "platform=iOS Simulator,name=iPhone 17 Pro",
        dryRun: true
    )

    let commands = TestRunnerWorkflow.commands(
        repositoryRoot: root,
        options: options
    )

    #expect(commands.count == 2)
    #expect(commands[0].arguments.contains("-only-testing:RetroRacingSharedTests"))
    #expect(commands[1].arguments.contains("-only-testing:RetroRacingUniversalTests"))
}

@Test
func givenOnlyTestingFilterWhenBuildingCommandsThenSingleFilteredCommandIsReturned() {
    let root = URL(fileURLWithPath: "/repository")
    let options = TestRunnerOptions(
        destination: "platform=iOS Simulator,name=iPhone 17 Pro",
        dryRun: true,
        onlyTesting: [
            "RetroRacingSharedTests/DebugSimulationProductionIsolationTests",
        ]
    )

    let commands = TestRunnerWorkflow.commands(
        repositoryRoot: root,
        options: options
    )

    #expect(commands.count == 1)
    #expect(
        commands[0].arguments.contains(
            "-only-testing:RetroRacingSharedTests/DebugSimulationProductionIsolationTests"
        )
    )
}

@Test
func givenTestFlightArchiveOptionsWhenBuildingCommandsThenIOSAndMacArchivesArePlanned() {
    let root = URL(fileURLWithPath: "/repository")
    let options = testFlightOptions(command: .archive)

    let commands = TestFlightUploadWorkflow.commands(
        repositoryRoot: root,
        options: options
    )

    #expect(commands.count == 2)
    #expect(commands.allSatisfy { $0.environment["DEVELOPER_DIR"] == options.developerDirectory })
    #expect(commands[0].arguments.contains("generic/platform=iOS"))
    #expect(commands[1].arguments.contains("generic/platform=macOS"))
}

@Test
func givenTestFlightUploadOptionsWhenBuildingCommandThenExportArchiveIsPlanned() {
    let root = URL(fileURLWithPath: "/repository")
    let options = testFlightOptions(command: .uploadIOS)

    let commands = TestFlightUploadWorkflow.commands(
        repositoryRoot: root,
        options: options
    )

    #expect(commands.count == 1)
    #expect(commands[0].arguments.contains("-exportArchive"))
    #expect(commands[0].arguments.contains("/repository/build/testflight-1.5/RetroRacingUniversal-iOS.xcarchive"))
}

@Test
func givenBuildLookupJSONObjectWhenParsingThenBuildIDIsReturned() throws {
    let buildID = try TestFlightUploadWorkflow.buildID(
        from: #"{"id":"1234567890"}"#
    )

    #expect(buildID == "1234567890")
}

@Test
func givenBuildLookupJSONArrayWhenParsingThenFirstBuildIDIsReturned() throws {
    let buildID = try TestFlightUploadWorkflow.buildID(
        from: #"[{"id":"1234567890"}]"#
    )

    #expect(buildID == "1234567890")
}

@Test
func givenRoadMaskDescriptorsWhenResolvingSizesThenLapAndLaneSizesDiffer() throws {
    let lane = try #require(
        RoadMaskWorkflow.descriptors.first { !$0.isLapMask }
    )
    let lap = try #require(
        RoadMaskWorkflow.descriptors.first { $0.isLapMask }
    )

    #expect(
        RoadMaskWorkflow.renderSizes(for: lane).universal
            == RoadMaskRenderSize(width: 600, height: 360)
    )
    #expect(
        RoadMaskWorkflow.renderSizes(for: lap).universal
            == RoadMaskRenderSize(width: 1600, height: 240)
    )
}

@Test
func givenRoadMaskDescriptorsWhenRenderingThenEveryExpectedFileIsProduced() throws {
    let files = try RoadMaskWorkflow.generatedFiles(
        repositoryRoot: URL(fileURLWithPath: "/repository")
    )
    let pngFiles = files.filter { $0.url.pathExtension == "png" }
    let firstPNG = try #require(pngFiles.first)
    let image = try #require(NSBitmapImageRep(data: firstPNG.data))

    #expect(files.count == RoadMaskWorkflow.descriptors.count * 5)
    #expect(image.pixelsWide > 0)
    #expect(image.pixelsHigh > 0)
}

@Test
func givenScreenshotSlideWhenBuildingLocalizationsThenEveryLocaleIsPresent() {
    let entries = ScreenshotStudioWorkflow.localizationEntries(
        slideIndex: 0,
        watchSequenceOnly: false
    )

    #expect(entries.count == ScreenshotStudioWorkflow.locales.count)
    #expect(Set(entries.compactMap { $0["language"] }) == Set(ScreenshotStudioWorkflow.locales))
}

@Test
func givenScreenshotPlatformWhenBuildingManifestThenEveryLocaleAndIndexIsPresent() throws {
    let manifest = try ScreenshotStudioWorkflow.contentsManifest(
        platform: "iphone",
        slideCount: ScreenshotStudioWorkflow.slideCount
    )
    let images = try #require(manifest["images"] as? [[String: Any]])

    #expect(
        images.count
            == ScreenshotStudioWorkflow.locales.count
            * ScreenshotStudioWorkflow.slideCount
    )
    #expect(images.contains { $0["filename"] as? String == "es-MX_6.jpeg" })
}

private func testFlightOptions(
    command: TestFlightUploadCommand
) -> TestFlightUploadOptions {
    TestFlightUploadOptions(
        command: command,
        appID: "6758641625",
        version: "1.5",
        buildNumber: "29",
        helmPath: "/Applications/Helm.app/Contents/Helpers/helm-asc",
        developerDirectory: "/Applications/Xcode.app/Contents/Developer",
        externalGroup: "df40f833-12c7-4411-b28d-122690045c58",
        pollAttempts: 1,
        pollIntervalSeconds: 1,
        dryRun: true
    )
}

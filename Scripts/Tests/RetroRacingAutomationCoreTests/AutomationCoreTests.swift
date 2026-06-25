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

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
func givenTestEnvironmentWhenBuildingCommandsThenEnvironmentIsForwarded() {
    let root = URL(fileURLWithPath: "/repository")
    let options = TestRunnerOptions(
        destination: "platform=iOS Simulator,name=iPhone 17 Pro Max",
        dryRun: true,
        onlyTesting: [
            "RetroRacingUniversalUITests/AppStoreScreenshotTests/testCaptureConfiguredScreenshot",
        ],
        environment: [
            "RETRORAPID_SCREENSHOT_STAGING": "/repository/.build/screenshot-capture",
        ]
    )

    let commands = TestRunnerWorkflow.commands(
        repositoryRoot: root,
        options: options
    )

    #expect(commands.count == 1)
    #expect(
        commands[0].environment["RETRORAPID_SCREENSHOT_STAGING"]
            == "/repository/.build/screenshot-capture"
    )
}

@Test
func givenScreenshotCaptureTargetsWhenEncodingAndDecodingThenRoundTripPreservesOrder() {
    let targets = ScreenshotCapturePlan.targets(
        locales: ["en-US", "de-DE"],
        slideIndexes: [0, 2]
    )
    let encoded = ScreenshotCapturePlan.encode(targets)
    #expect(encoded == "en-US_0,en-US_2,de-DE_0,de-DE_2")
    #expect(ScreenshotCapturePlan.decode(encoded) == targets)
}

@Test
func givenExistingStagedFilesWhenComputingMissingTargetsThenOnlyAbsentOnesAreReturned() throws {
    let root = FileManager.default.temporaryDirectory
        .appending(path: "screenshot-capture-plan-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let existing = root.appending(path: "en-US_0.jpeg")
    try Data("jpeg".utf8).write(to: existing)

    let targets = ScreenshotCapturePlan.targets(
        locales: ["en-US"],
        slideIndexes: [0, 1]
    )
    let missing = ScreenshotCapturePlan.missingTargets(in: root, targets: targets)

    #expect(missing.map(\.stem) == ["en-US_1"])
}

@Test
func givenCaptureEnvironmentWhenBuildingCommandThenTargetsAndRetriesAreForwarded() {
    let root = URL(fileURLWithPath: "/repository")
    let staging = root.appending(path: ".build/screenshot-capture")
    let targets = [
        ScreenshotCaptureTarget(locale: "fr-FR", slideIndex: 3),
    ]
    let environment = ScreenshotCapturePlan.captureEnvironment(
        targets: targets,
        maxRetries: 3,
        skipExisting: true,
        stagingDirectory: staging,
        fileExtension: ".jpeg",
        platform: "iphone"
    )

    let options = TestRunnerOptions(
        destination: "platform=iOS Simulator,name=iPhone 17 Pro Max",
        dryRun: true,
        onlyTesting: [
            "RetroRacingUniversalUITests/AppStoreScreenshotTests/testCaptureConfiguredScreenshot",
        ],
        environment: environment
    )

    let commands = TestRunnerWorkflow.commands(
        repositoryRoot: root,
        options: options
    )

    #expect(commands.count == 1)
    #expect(commands[0].environment["RETRORAPID_SCREENSHOT_TARGETS"] == "fr-FR_3")
    #expect(commands[0].environment["RETRORAPID_SCREENSHOT_MAX_RETRIES"] == "3")
    #expect(commands[0].environment["RETRORAPID_SCREENSHOT_SKIP_EXISTING"] == "1")
    #expect(commands[0].environment["RETRORAPID_SCREENSHOT_STAGING"] == staging.path)
    #expect(commands[0].environment["RETRORAPID_SCREENSHOT_FILE_EXTENSION"] == ".jpeg")
    #expect(commands[0].environment["RETRORAPID_SCREENSHOT_PLATFORM"] == "iphone")
}

@Test
func givenIPadPlatformWhenResolvingCaptureDefaultsThenUsesIPadSimulatorAndJpegStaging() {
    let root = URL(fileURLWithPath: "/repository")
    let staging = AppStoreScreenshotCaptureDefaults.stagingDirectory(repositoryRoot: root, platform: "ipad")

    #expect(AppStoreScreenshotCaptureDefaults.normalizedPlatform("iPadOS") == "ipad")
    #expect(AppStoreScreenshotCaptureDefaults.destination(for: "ipad") == "platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=27.0")
    #expect(staging.path.hasSuffix(".build/screenshot-capture/ipad"))
    #expect(ScreenshotStudioWorkflow.imageExtension(for: "ipad") == ".jpeg")
}

@Test
func givenMacPlatformWhenResolvingCaptureDefaultsThenUsesMacOSDestinationAndPngStaging() {
    let root = URL(fileURLWithPath: "/repository")
    let staging = AppStoreScreenshotCaptureDefaults.stagingDirectory(repositoryRoot: root, platform: "mac")

    #expect(AppStoreScreenshotCaptureDefaults.normalizedPlatform("macOS") == "mac")
    #expect(AppStoreScreenshotCaptureDefaults.destination(for: "mac") == "platform=macOS")
    #expect(staging.path.hasSuffix(".build/screenshot-capture/mac"))
    #expect(ScreenshotStudioWorkflow.imageExtension(for: "mac") == ".png")
}

@Test
func givenCaptureTargetWhenWritingFilePlanThenStoresPlanInStagingDirectory() throws {
    let staging = FileManager.default.temporaryDirectory
        .appending(path: "screenshot-capture-plan-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: staging.deletingLastPathComponent()) }

    let target = ScreenshotCaptureTarget(locale: "en-US", slideIndex: 0)
    try ScreenshotCapturePlan.writeFilePlan(
        stagingDirectory: staging,
        platform: "iphone",
        targets: [target],
        maxRetries: 1,
        skipExisting: false,
        fileExtension: ".png"
    )

    let planURL = ScreenshotCapturePlan.filePlanURL(in: staging)
    #expect(FileManager.default.fileExists(atPath: planURL.path))

    let platformPlanURL = ScreenshotCapturePlan.platformFilePlanURL(platform: "iphone")
    #expect(FileManager.default.fileExists(atPath: platformPlanURL.path))

    let activePlanURL = ScreenshotCapturePlan.activeFilePlanURL()
    #expect(FileManager.default.fileExists(atPath: activePlanURL.path))

    let loaded = try #require(ScreenshotCapturePlan.loadFilePlan(from: staging))
    #expect(loaded.targets == [target.stem])

    let activeLoaded = try JSONDecoder().decode(
        ScreenshotCapturePlan.FilePlan.self,
        from: Data(contentsOf: activePlanURL)
    )
    #expect(activeLoaded.targets == [target.stem])
    defer { try? FileManager.default.removeItem(at: activePlanURL) }
    #expect(loaded.resolvedFileExtension == ".png")
    #expect(loaded.stagingDirectory == staging.path)
}

@Test
func givenFailedReportEntryWhenStagedFileExistsThenReconcileReportRemovesFailure() throws {
    let root = FileManager.default.temporaryDirectory
        .appending(path: "screenshot-capture-reconcile-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let stagedFile = root.appending(path: "en-US_1.jpeg")
    try Data("jpeg".utf8).write(to: stagedFile)

    let report = ScreenshotCaptureReport(
        captured: ["en-US_0"],
        skippedExisting: [],
        failed: [
            .init(target: "en-US_1", attempts: 2, error: "Expected screenshot file was not written: en-US_1.jpeg.")
        ]
    )
    try ScreenshotCapturePlan.writeReport(report, to: root)

    try ScreenshotCapturePlan.reconcileReport(in: root)

    let reconciled = try #require(ScreenshotCapturePlan.loadReport(from: root))
    #expect(reconciled.failed.isEmpty)
}

@Test
func givenCapturedTargetWhenInstallingIncrementallyThenCopiesSingleStudioImage() throws {
    let root = FileManager.default.temporaryDirectory
        .appending(path: "screenshot-capture-install-\(UUID().uuidString)", directoryHint: .isDirectory)
    let staging = root.appending(path: ".build/screenshot-capture", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let stagedFile = staging.appending(path: "en-US_1.jpeg")
    try Data("jpeg".utf8).write(to: stagedFile)

    let options = ScreenshotStudioPlacementOptions(
        stagingDirectory: staging,
        platform: "iphone",
        locales: ["en-US"],
        slideIndexes: [1]
    )
    let result = try ScreenshotStudioPlacementWorkflow.installTarget(
        repositoryRoot: root,
        options: options,
        target: ScreenshotCaptureTarget(locale: "en-US", slideIndex: 1)
    )

    #expect(result.installed == ["en-US_1.jpeg"])
    let destination = try ScreenshotStudioPlacementWorkflow.destinationURL(
        repositoryRoot: root,
        platform: "iphone",
        locale: "en-US",
        slideIndex: 1
    )
    #expect(FileManager.default.fileExists(atPath: destination.path))
}

@Test
func givenEnglishAndSpanishDerivedLocalesWhenResolvingCaptureLocalesThenUsesSharedSources() {
    let studioLocales = ScreenshotStudioWorkflow.locales
    let captureLocales = ScreenshotCapturePlan.captureLocales(from: studioLocales)

    #expect(captureLocales == ["en-US", "de-DE", "nl-NL", "it", "fr-FR", "fr-CA", "es-ES", "ca", "ja", "ko", "pt-BR", "pt-PT", "zh-Hant", "zh-Hans"])
    #expect(ScreenshotCapturePlan.sourceLocale(for: "en-GB") == "en-US")
    #expect(ScreenshotCapturePlan.sourceLocale(for: "es-MX") == "es-ES")
}

@Test
func givenEnglishSourceCaptureWhenDuplicatingDerivedLocalesThenCopiesMissingTargets() throws {
    let root = FileManager.default.temporaryDirectory
        .appending(path: "screenshot-capture-duplicate-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    try Data("jpeg".utf8).write(to: root.appending(path: "en-US_1.jpeg"))

    let duplicated = try ScreenshotCapturePlan.duplicateDerivedCaptures(
        in: root,
        studioLocales: ["en-US", "en-GB", "en-AU", "en-CA"],
        slideIndexes: [1]
    )

    #expect(duplicated.map(\.stem).sorted() == ["en-AU_1", "en-CA_1", "en-GB_1"])
    #expect(FileManager.default.fileExists(atPath: root.appending(path: "en-GB_1.jpeg").path))
}

@Test
func givenLocalizedSourceCapturesWhenSyncingScreenshotStudioThenOnlyDerivedLocalesAreCopied() throws {
    let root = FileManager.default.temporaryDirectory
        .appending(path: "screenshot-studio-sync-\(UUID().uuidString)", directoryHint: .isDirectory)
    let studioRoot = root.appending(path: "AppStore/RetroRapid.screenshotstudio")
    let imagesDirectory = studioRoot
        .appending(path: "iphone/images")
    try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

    let enUS = Data("en-us-image".utf8)
    let german = Data("german-image".utf8)
    try enUS.write(to: imagesDirectory.appending(path: "en-US_0.jpeg"))
    try german.write(to: imagesDirectory.appending(path: "de-DE_0.jpeg"))

    let projectPlist: [String: Any] = [
        "localizations": ScreenshotStudioWorkflow.locales,
    ]
    let projectData = try PropertyListSerialization.data(
        fromPropertyList: projectPlist,
        format: .xml,
        options: 0
    )
    try projectData.write(to: studioRoot.appending(path: "project.plist"))

    let iphoneSlides = try Array(repeating: ["localizations": []] as [String: Any], count: 10)
    let iphoneData = try PropertyListSerialization.data(
        fromPropertyList: iphoneSlides,
        format: .xml,
        options: 0
    )
    try FileManager.default.createDirectory(
        at: studioRoot.appending(path: "iphone"),
        withIntermediateDirectories: true
    )
    try iphoneData.write(to: studioRoot.appending(path: "iphone/data.plist"))

    for platform in ["ipad", "mac", "appleWatch"] {
        let platformRoot = studioRoot.appending(path: platform)
        try FileManager.default.createDirectory(at: platformRoot, withIntermediateDirectories: true)
        try iphoneData.write(to: platformRoot.appending(path: "data.plist"))
    }

    try ScreenshotStudioWorkflow.run(repositoryRoot: root, mode: .write)

    let germanAfter = try Data(contentsOf: imagesDirectory.appending(path: "de-DE_0.jpeg"))
    let englishDerived = try Data(contentsOf: imagesDirectory.appending(path: "en-GB_0.jpeg"))
    #expect(germanAfter == german)
    #expect(englishDerived == enUS)
}

@Test
func givenScreenshotCapturePlanWhenUsingTestWithoutBuildingThenUsesExpectedXcodebuildAction() {
    let root = URL(fileURLWithPath: "/repository")
    let options = TestRunnerOptions(
        destination: "platform=iOS Simulator,name=iPhone 17 Pro Max",
        dryRun: true,
        onlyTesting: [
            "RetroRacingUniversalUITests/AppStoreScreenshotTests/testCaptureConfiguredScreenshot",
        ],
        buildMode: .testWithoutBuilding
    )

    let commands = TestRunnerWorkflow.commands(repositoryRoot: root, options: options)

    #expect(commands.count == 1)
    #expect(commands[0].arguments.contains("test-without-building"))
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
func givenScreenshotSlideWhenBuildingLocalizationsThenEveryLocaleIsPresent() throws {
    let entries = try ScreenshotStudioWorkflow.localizationEntries(
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
    #expect(images.contains { $0["filename"] as? String == "es-MX_9.jpeg" })
    #expect(images.contains { $0["filename"] as? String == "ca_9.jpeg" })
    #expect(images.contains { $0["filename"] as? String == "es-ES_9.jpeg" })
}

@Test
func givenMacPlatformWhenBuildingManifestThenUsesNineSlides() throws {
    let manifest = try ScreenshotStudioWorkflow.contentsManifest(
        platform: "mac",
        slideCount: ScreenshotStudioWorkflow.slideCount(for: "mac")
    )
    let images = try #require(manifest["images"] as? [[String: Any]])
    #expect(images.count == ScreenshotStudioWorkflow.locales.count * 9)
}

@Test
func givenMacSlideFiveWhenBuildingLocalizationsThenSkipsSharePlayCopy() throws {
    let entries = try ScreenshotStudioWorkflow.localizationEntries(
        slideIndex: 4,
        watchSequenceOnly: false,
        platform: "mac"
    )
    let enUS = try #require(entries.first { $0["language"] == "en-US" })
    #expect(enUS["title"] == "Climb the Leaderboard")
}

@Test
func givenWatchPlatformWhenBuildingManifestThenEveryLocaleAndIndexIsPresent() throws {
    let manifest = try ScreenshotStudioWorkflow.contentsManifest(
        platform: "appleWatch",
        slideCount: ScreenshotStudioWorkflow.watchSlideCount
    )
    let images = try #require(manifest["images"] as? [[String: Any]])

    #expect(
        images.count
            == ScreenshotStudioWorkflow.locales.count
            * ScreenshotStudioWorkflow.watchSlideCount
    )
    #expect(Set(images.compactMap { $0["locale"] as? String }) == Set(ScreenshotStudioWorkflow.locales))
    #expect(images.contains { $0["filename"] as? String == "en-US_4.jpeg" })
    #expect(images.contains { $0["filename"] as? String == "es-MX_0.jpeg" })
}

@Test
func givenStagedFileNameWhenParsingThenReturnsLocaleAndSlideIndex() {
    let parsed = ScreenshotStudioPlacementWorkflow.parseStagedFileName("de-DE_2.jpeg", fileExtension: ".jpeg")
    #expect(parsed?.locale == "de-DE")
    #expect(parsed?.slideIndex == 2)
}

@Test
func givenInvalidStagedFileNameWhenParsingThenReturnsNil() {
    #expect(ScreenshotStudioPlacementWorkflow.parseStagedFileName("invalid.jpeg", fileExtension: ".jpeg") == nil)
}

@Test
func givenCaptureOptionsWhenParsingThenPlatformLocalesAndSlidesResolve() throws {
    let root = URL(fileURLWithPath: "/repository")
    let arguments = CLIArguments([
        "--platform", "mac",
        "--locales", "en-US,de-DE",
        "--slides", "0,4",
        "--retries", "2",
        "--dry-run",
    ])
    let options = try AppStoreScreenshotCaptureOptions.parse(arguments, repositoryRoot: root)

    #expect(options.platform == "mac")
    #expect(options.locales == ["en-US", "de-DE"])
    #expect(options.slideIndexes == [0, 4])
    #expect(options.maxRetries == 2)
    #expect(options.dryRun == true)
    #expect(options.statusBarOverrideEnabled == true)
    #expect(options.destination == AppStoreScreenshotCaptureDefaults.destination(for: "mac"))
}

@Test
func givenNoStatusBarOverrideFlagWhenParsingThenOverrideIsDisabled() throws {
    let root = URL(fileURLWithPath: "/repository")
    let arguments = CLIArguments(["--no-status-bar-override"])
    let options = try AppStoreScreenshotCaptureOptions.parse(arguments, repositoryRoot: root)
    #expect(options.statusBarOverrideEnabled == false)
}

@Test
func givenWatchPlatformWhenParsingThenStatusBarOverrideDefaultsOff() throws {
    let root = URL(fileURLWithPath: "/repository")
    let arguments = CLIArguments(["--platform", "watch"])
    let options = try AppStoreScreenshotCaptureOptions.parse(arguments, repositoryRoot: root)
    #expect(options.statusBarOverrideEnabled == false)
}

@Test
func givenWatchPlatformWithStatusBarOverrideFlagWhenParsingThenOverrideIsEnabled() throws {
    let root = URL(fileURLWithPath: "/repository")
    let arguments = CLIArguments(["--platform", "watch", "--status-bar-override"])
    let options = try AppStoreScreenshotCaptureOptions.parse(arguments, repositoryRoot: root)
    #expect(options.statusBarOverrideEnabled == true)
}

@Test
func givenAllPlatformsFlagWhenParsingPlansThenReturnsIphoneIpadMacWatch() throws {
    let root = URL(fileURLWithPath: "/repository")
    let arguments = CLIArguments(["--all-platforms", "--force"])
    let plans = try AppStoreScreenshotCaptureOptions.parsePlans(arguments, repositoryRoot: root)

    #expect(plans.map(\.platform) == ["iphone", "ipad", "mac", "appleWatch"])
    #expect(plans.map(\.forceRecapture) == [true, true, true, true])
    #expect(plans[0].statusBarOverrideEnabled == true)
    #expect(plans[3].statusBarOverrideEnabled == false)
    #expect(plans[0].slideIndexes.count == 10)
    #expect(plans[2].slideIndexes.count == 9)
    #expect(plans[3].slideIndexes.count == 5)
}

@Test
func givenAllPlatformsWithPlatformFlagWhenParsingThenThrows() throws {
    let root = URL(fileURLWithPath: "/repository")
    let arguments = CLIArguments(["--all-platforms", "--platform", "iphone"])
    #expect(throws: AppStoreScreenshotCaptureError.self) {
        _ = try AppStoreScreenshotCaptureOptions.parsePlans(arguments, repositoryRoot: root)
    }
}

@Test
func givenAppearanceFlagWhenParsingThenUsesRequestedAppearance() throws {
    let root = URL(fileURLWithPath: "/repository")
    let light = try AppStoreScreenshotCaptureOptions.parse(CLIArguments([]), repositoryRoot: root)
    let dark = try AppStoreScreenshotCaptureOptions.parse(
        CLIArguments(["--appearance", "dark"]),
        repositoryRoot: root
    )
    #expect(light.appearance == .light)
    #expect(dark.appearance == .dark)
}

@Test
func givenInvalidAppearanceWhenParsingThenThrows() throws {
    let root = URL(fileURLWithPath: "/repository")
    #expect(throws: AppStoreScreenshotCaptureError.self) {
        _ = try AppStoreScreenshotCaptureOptions.parse(
            CLIArguments(["--appearance", "sepia"]),
            repositoryRoot: root
        )
    }
}

@Test
func givenIOSDestinationWhenParsingSimulatorNameThenReturnsDeviceName() {
    let destination = "platform=iOS Simulator,name=iPhone 17 Pro Max"
    #expect(SimulatorStatusBarWorkflow.simulatorName(from: destination) == "iPhone 17 Pro Max")
    #expect(SimulatorStatusBarWorkflow.usesIOSSimulatorDestination(destination))
}

@Test
func givenMarketingStatusBarCommandWhenBuildingThenUsesNineFortyOneTime() {
    let command = SimulatorStatusBarWorkflow.marketingOverrideCommand(simulatorReference: "BOOTED-UDID")
    let timeArgument = command.arguments[command.arguments.firstIndex(of: "--time")! + 1]
    #expect(timeArgument.contains("2027-01-27"))
    #expect(timeArgument.contains("09:41:00.000"))
    #expect(timeArgument.contains("T"))
    #expect(command.arguments.contains("override"))
    #expect(command.arguments.contains("charged"))
}

@Test
func givenMarketingStatusBarDateTimeWhenFormattingThenUsesFractionalISO8601() {
    let utc = TimeZone(secondsFromGMT: 0)!
    let formatted = SimulatorStatusBarWorkflow.marketingStatusBarDateTime(for: utc)
    #expect(formatted == "2027-01-27T09:41:00.000+00:00")
}

@Test
func givenWatchSimulatorPairsJSONWhenResolvingPhoneThenReturnsPairedUDID() throws {
    let json = """
    {
      "pairs": {
        "pair-1": {
          "watch": { "udid": "watch-udid" },
          "phone": { "udid": "phone-udid" }
        }
      }
    }
    """.data(using: .utf8)!

    let phoneUDID = try WatchScreenshotCaptureLocaleWorkflow.pairedPhoneUDID(
        forWatchUDID: "watch-udid",
        pairsJSON: json
    )

    #expect(phoneUDID == "phone-udid")
}

@Test
func givenWatchCaptureLocaleWhenMappingAppStoreLocaleThenUsesLanguageAndRegion() {
    #expect(WatchScreenshotCaptureLocaleWorkflow.inAppLanguageIdentifier(for: "de-DE") == "de")
    #expect(WatchScreenshotCaptureLocaleWorkflow.inAppLanguageIdentifier(for: "nl-NL") == "nl")
    #expect(WatchScreenshotCaptureLocaleWorkflow.inAppLanguageIdentifier(for: "ja") == "ja")
    #expect(WatchScreenshotCaptureLocaleWorkflow.inAppLanguageIdentifier(for: "pt-BR") == "pt-BR")
    #expect(WatchScreenshotCaptureLocaleWorkflow.inAppLanguageIdentifier(for: "zh-Hant") == "zh-Hant")
    #expect(WatchScreenshotCaptureLocaleWorkflow.appleLocaleArgument(for: "de-DE") == "de_DE")
    #expect(WatchScreenshotCaptureLocaleWorkflow.appleLocaleArgument(for: "pt-BR") == "pt_BR")
}

@Test
func givenWatchMarketingClockWhenFormattingDateArgumentThenUsesTenZeroNine() {
    #expect(WatchSimulatorClockWorkflow.macOSDateSetArgument == "012710092027")
    #expect(WatchSimulatorClockWorkflow.marketingClockTime == "10:09")
    #expect(
        WatchSimulatorClockWorkflow.applyMarketingClockShellCommand
            == "/usr/sbin/systemsetup -setusingnetworktime off && /bin/date 012710092027"
    )
    #expect(
        WatchSimulatorClockWorkflow.restoreMarketingClockShellCommand(savedEpoch: "1700000000")
            == "/bin/date -r 1700000000 && /usr/sbin/systemsetup -setusingnetworktime on"
    )
}

@Test
func givenWatchMarketingClockWhenBuildingPrivilegedCommandThenUsesOsaScript() {
    let command = WatchSimulatorClockWorkflow.privilegedShellCommand(
        WatchSimulatorClockWorkflow.applyMarketingClockShellCommand
    )
    #expect(command.executable == "/usr/bin/osascript")
    #expect(command.arguments.first == "-e")
    let source = command.arguments.dropFirst().first
    #expect(source?.contains("with administrator privileges") == true)
    #expect(source?.contains("systemsetup -setusingnetworktime off") == true)
    #expect(source?.contains("012710092027") == true)
}

@Test
func givenWatchPlatformWhenCheckingMarketingClockOverrideThenIsEnabled() {
    #expect(WatchSimulatorClockWorkflow.shouldApply(platform: "appleWatch", enabled: true))
    #expect(WatchSimulatorClockWorkflow.shouldApply(platform: "watch", enabled: true))
    #expect(WatchSimulatorClockWorkflow.shouldApply(platform: "appleWatch", enabled: false) == false)
    #expect(WatchSimulatorClockWorkflow.shouldApply(platform: "iphone", enabled: true) == false)
}

@Test
func givenMarketingStatusBarDateTimeWhenUsingMarketingCalendarDateThenUsesSeasonalOffsetForThatDate() throws {
    let madrid = try #require(TimeZone(identifier: "Europe/Madrid"))
    let formatted = SimulatorStatusBarWorkflow.marketingStatusBarDateTime(for: madrid)
    // 27 January is standard time (CET, +01:00) even when captures run during summer DST.
    #expect(formatted == "2027-01-27T09:41:00.000+01:00")
}

@Test
func givenSimulatorDevicesJSONWhenResolvingUDIDThenPrefersBootedDevice() throws {
    let json = """
    {
      "devices": {
        "com.apple.CoreSimulator.SimRuntime.iOS-27-0": [
          { "udid": "A", "name": "iPhone 17 Pro Max", "state": "Shutdown", "isAvailable": true },
          { "udid": "B", "name": "iPhone 17 Pro Max", "state": "Booted", "isAvailable": true }
        ]
      }
    }
    """
    let udid = try SimulatorStatusBarWorkflow.resolveSimulatorUDID(
        named: "iPhone 17 Pro Max",
        devicesJSON: Data(json.utf8)
    )
    #expect(udid == "B")
}

@Test
func givenMultipleBootedSimulatorsWithSameNameWhenResolvingUDIDThenMatchesDestinationOS() throws {
    let json = """
    {
      "devices": {
        "com.apple.CoreSimulator.SimRuntime.iOS-26-5": [
          { "udid": "ios-26-booted", "name": "iPhone 17 Pro Max", "state": "Booted", "isAvailable": true }
        ],
        "com.apple.CoreSimulator.SimRuntime.iOS-27-0": [
          { "udid": "ios-27-booted", "name": "iPhone 17 Pro Max", "state": "Booted", "isAvailable": true }
        ]
      }
    }
    """
    let udid = try SimulatorStatusBarWorkflow.resolveSimulatorUDID(
        named: "iPhone 17 Pro Max",
        osVersion: "27.0",
        devicesJSON: Data(json.utf8)
    )
    #expect(udid == "ios-27-booted")
}

@Test
func givenDestinationStringWhenParsingSimulatorOSVersionThenReturnsOSComponent() {
    let destination = "platform=iOS Simulator,name=iPhone 17 Pro Max,OS=27.0"
    #expect(SimulatorStatusBarWorkflow.simulatorOSVersion(from: destination) == "27.0")
}

@Test
func givenFailedCaptureTargetWhenRecordingFailureThenReportContainsEntry() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("screenshot-capture-failure-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let target = ScreenshotCaptureTarget(locale: "en-US", slideIndex: 1)
    try ScreenshotCapturePlan.recordFailure(
        target: target,
        attempts: 3,
        error: "Timed out waiting for screenshot-ready-slide-1.",
        in: directory
    )

    let report = try #require(ScreenshotCapturePlan.loadReport(from: directory))
    #expect(report.failed.count == 1)
    #expect(report.failed[0].target == "en-US_1")
    #expect(report.failed[0].attempts == 3)
}

@Test
func givenDestinationURLWhenBuildingPathThenUsesScreenshotStudioImagesFolder() throws {
    let root = URL(fileURLWithPath: "/repository")
    let destination = try ScreenshotStudioPlacementWorkflow.destinationURL(
        repositoryRoot: root,
        platform: "iphone",
        locale: "fr-FR",
        slideIndex: 3
    )
    #expect(
        destination.path.hasSuffix("AppStore/RetroRapid.screenshotstudio/iphone/images/fr-FR_3.jpeg")
    )
}

@Test
func givenInstalledSimulatorsWhenResolvingIPadDestinationThenPrefersLatestM5Runtime() throws {
    let json = """
    {
      "devices": {
        "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [
          { "name": "iPad Pro 13-inch (M4)", "udid": "m4-26", "isAvailable": true }
        ],
        "com.apple.CoreSimulator.SimRuntime.iOS-27-0": [
          { "name": "iPad Pro 13-inch (M5)", "udid": "m5-27", "isAvailable": true }
        ]
      }
    }
    """.data(using: .utf8)!

    let destination = try SimulatorDestinationResolver.resolveDefaultDestination(
        for: "ipad",
        devicesJSON: json
    )

    #expect(destination == "platform=iOS Simulator,id=m5-27")
}

@Test
func givenOnlyLegacyIPadSimulatorWhenResolvingDestinationThenFallsBackToM4() throws {
    let json = """
    {
      "devices": {
        "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [
          { "name": "iPad Pro 13-inch (M4)", "udid": "m4-26", "isAvailable": true }
        ]
      }
    }
    """.data(using: .utf8)!

    let destination = try SimulatorDestinationResolver.resolveDefaultDestination(
        for: "ipad",
        devicesJSON: json
    )

    #expect(destination == "platform=iOS Simulator,id=m4-26")
}

@Test
func givenMultipleWatchUltraSimulatorsWhenResolvingDestinationThenUsesNewestRuntimeUDID() throws {
    let json = """
    {
      "devices": {
        "com.apple.CoreSimulator.SimRuntime.watchOS-26-0": [
          { "name": "Apple Watch Ultra 3 (49mm)", "udid": "ultra-26", "isAvailable": true }
        ],
        "com.apple.CoreSimulator.SimRuntime.watchOS-26-5": [
          { "name": "Apple Watch Ultra 3 (49mm)", "udid": "ultra-26-5", "isAvailable": true }
        ],
        "com.apple.CoreSimulator.SimRuntime.watchOS-27-0": [
          { "name": "Apple Watch Ultra 3 (49mm)", "udid": "ultra-27", "isAvailable": true }
        ]
      }
    }
    """.data(using: .utf8)!

    let destination = try SimulatorDestinationResolver.resolveDefaultDestination(
        for: "appleWatch",
        devicesJSON: json
    )

    #expect(destination == "platform=watchOS Simulator,id=ultra-27")
}

@Test
func givenNameBasedDestinationWhenNormalizingThenUsesUDID() throws {
    let json = """
    {
      "devices": {
        "com.apple.CoreSimulator.SimRuntime.watchOS-27-0": [
          { "name": "Apple Watch Ultra 3 (49mm)", "udid": "ultra-27", "isAvailable": true }
        ],
        "com.apple.CoreSimulator.SimRuntime.watchOS-26-0": [
          { "name": "Apple Watch Ultra 3 (49mm)", "udid": "ultra-26", "isAvailable": true }
        ]
      }
    }
    """.data(using: .utf8)!

    let normalized = try SimulatorDestinationResolver.normalizeDestinationIfNeeded(
        "platform=watchOS Simulator,name=Apple Watch Ultra 3 (49mm),OS=27.0",
        platform: "appleWatch",
        devicesJSON: json
    )

    #expect(normalized == "platform=watchOS Simulator,id=ultra-27")
}

@Test
func givenDestinationStringWhenParsingSimulatorUDIDThenReturnsIDComponent() {
    let destination = "platform=watchOS Simulator,id=DDE1D3F2-7332-4F34-A7D2-6C5AB5E91E80"
    #expect(
        SimulatorStatusBarWorkflow.simulatorUDID(from: destination)
            == "DDE1D3F2-7332-4F34-A7D2-6C5AB5E91E80"
    )
}

@Test
func givenCaptureEnvironmentKeysWhenComparedToSharedIdentifiersThenTheyMatch() {
    #expect(ScreenshotCapturePlan.platformEnvironmentKey == "RETRORAPID_SCREENSHOT_PLATFORM")
    #expect(ScreenshotCapturePlan.appearanceEnvironmentKey == "RETRORAPID_SCREENSHOT_APPEARANCE")
    #expect(ScreenshotCapturePlan.fileExtensionEnvironmentKey == "RETRORAPID_SCREENSHOT_FILE_EXTENSION")
    #expect(ScreenshotCapturePlan.targetsEnvironmentKey == "RETRORAPID_SCREENSHOT_TARGETS")
    #expect(ScreenshotCapturePlan.maxRetriesEnvironmentKey == "RETRORAPID_SCREENSHOT_MAX_RETRIES")
    #expect(ScreenshotCapturePlan.skipExistingEnvironmentKey == "RETRORAPID_SCREENSHOT_SKIP_EXISTING")
    #expect(ScreenshotCaptureReport.reportFileName == "capture-report.json")
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

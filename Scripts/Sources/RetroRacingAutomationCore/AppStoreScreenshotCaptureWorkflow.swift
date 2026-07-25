//
//  AppStoreScreenshotCaptureWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import ScriptSupport

public struct AppStoreScreenshotCaptureOptions: Sendable, Equatable {
    public let stagingDirectory: URL
    public let platform: String
    public let locales: [String]
    public let slideIndexes: [Int]
    public let destination: String
    public let usesExplicitDestination: Bool
    public let maxRetries: Int
    public let forceRecapture: Bool
    public let installOnly: Bool
    public let dryRun: Bool
    public let checkOnly: Bool
    public let statusBarOverrideEnabled: Bool
    public let appearance: AppStoreScreenshotAppearance

    public init(
        stagingDirectory: URL,
        platform: String = "iphone",
        locales: [String] = ScreenshotStudioWorkflow.locales,
        slideIndexes: [Int] = Array(0..<ScreenshotStudioWorkflow.slideCount),
        destination: String = AppStoreScreenshotCaptureDefaults.fallbackDestination(for: "iphone"),
        usesExplicitDestination: Bool = false,
        maxRetries: Int = ScreenshotCapturePlan.defaultMaxRetries,
        forceRecapture: Bool = false,
        installOnly: Bool = false,
        dryRun: Bool = false,
        checkOnly: Bool = false,
        statusBarOverrideEnabled: Bool = true,
        appearance: AppStoreScreenshotAppearance = .default
    ) {
        self.stagingDirectory = stagingDirectory
        self.platform = platform
        self.locales = locales
        self.slideIndexes = slideIndexes
        self.destination = destination
        self.usesExplicitDestination = usesExplicitDestination
        self.maxRetries = maxRetries
        self.forceRecapture = forceRecapture
        self.installOnly = installOnly
        self.dryRun = dryRun
        self.checkOnly = checkOnly
        self.statusBarOverrideEnabled = statusBarOverrideEnabled
        self.appearance = appearance
    }

    public static func parse(_ arguments: CLIArguments, repositoryRoot: URL) throws -> AppStoreScreenshotCaptureOptions {
        let plans = try parsePlans(arguments, repositoryRoot: repositoryRoot)
        guard let options = plans.first, plans.count == 1 else {
            throw AppStoreScreenshotCaptureError.invalidAllPlatformsUsage(
                "parse() expects a single-platform plan; use parsePlans() with --all-platforms."
            )
        }
        return options
    }

    /// One plan per platform. `--all-platforms` expands to iphone → ipad → mac → watch in order.
    public static func parsePlans(
        _ arguments: CLIArguments,
        repositoryRoot: URL
    ) throws -> [AppStoreScreenshotCaptureOptions] {
        try arguments.rejectUnknownFlags(
            allowing: [
                "--install-only",
                "--dry-run",
                "--check",
                "--force",
                "--no-status-bar-override",
                "--status-bar-override",
                "--all-platforms",
            ],
            valueFlags: [
                "--staging-dir",
                "--platform",
                "--locales",
                "--slides",
                "--destination",
                "--retries",
                "--appearance",
            ]
        )

        let allPlatforms = arguments.contains("--all-platforms")
        let explicitPlatform = try arguments.value(after: "--platform")
        let explicitDestination = try arguments.value(after: "--destination")
        let explicitStaging = try arguments.value(after: "--staging-dir")

        if allPlatforms {
            if explicitPlatform != nil {
                throw AppStoreScreenshotCaptureError.invalidAllPlatformsUsage(
                    "Do not combine --all-platforms with --platform."
                )
            }
            if explicitDestination != nil {
                throw AppStoreScreenshotCaptureError.invalidAllPlatformsUsage(
                    "Do not combine --all-platforms with --destination (destinations are resolved per platform)."
                )
            }
            if explicitStaging != nil {
                throw AppStoreScreenshotCaptureError.invalidAllPlatformsUsage(
                    "Do not combine --all-platforms with --staging-dir (staging is per platform under .build/screenshot-capture/)."
                )
            }

            return try AppStoreScreenshotCaptureDefaults.capturePlatforms.map { platform in
                try options(
                    for: platform,
                    arguments: arguments,
                    repositoryRoot: repositoryRoot,
                    stagingPath: nil,
                    explicitDestination: nil
                )
            }
        }

        let platform = AppStoreScreenshotCaptureDefaults.normalizedPlatform(explicitPlatform ?? "iphone")
        return [
            try options(
                for: platform,
                arguments: arguments,
                repositoryRoot: repositoryRoot,
                stagingPath: explicitStaging,
                explicitDestination: explicitDestination
            ),
        ]
    }

    private static func options(
        for platform: String,
        arguments: CLIArguments,
        repositoryRoot: URL,
        stagingPath: String?,
        explicitDestination: String?
    ) throws -> AppStoreScreenshotCaptureOptions {
        let normalized = AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform)
        let defaultStaging = AppStoreScreenshotCaptureDefaults.stagingDirectory(
            repositoryRoot: repositoryRoot,
            platform: normalized
        )
        let locales = try parseCSVList(
            arguments.value(after: "--locales"),
            fallback: AppStoreScreenshotCaptureDefaults.defaultLocales(for: normalized)
        )
        let slides = try parseSlideIndexes(arguments.value(after: "--slides"), platform: normalized)
        let maxRetries = try parseMaxRetries(arguments.value(after: "--retries"))
        let appearance = try AppStoreScreenshotAppearance.parse(arguments.value(after: "--appearance"))

        return AppStoreScreenshotCaptureOptions(
            stagingDirectory: URL(
                fileURLWithPath: stagingPath ?? defaultStaging.path,
                isDirectory: true
            ),
            platform: normalized,
            locales: locales,
            slideIndexes: slides,
            destination: explicitDestination
                ?? AppStoreScreenshotCaptureDefaults.fallbackDestination(for: normalized),
            usesExplicitDestination: explicitDestination != nil,
            maxRetries: maxRetries,
            forceRecapture: arguments.contains("--force"),
            installOnly: arguments.contains("--install-only"),
            dryRun: arguments.contains("--dry-run"),
            checkOnly: arguments.contains("--check"),
            statusBarOverrideEnabled: resolvedStatusBarOverrideEnabled(
                platform: normalized,
                arguments: arguments
            ),
            appearance: appearance
        )
    }

    /// iPhone/iPad/Mac default to marketing status-bar override; Apple Watch defaults off because
    /// watchOS has no `simctl status_bar` and host-clock changes are disruptive.
    static func resolvedStatusBarOverrideEnabled(platform: String, arguments: CLIArguments) -> Bool {
        if arguments.contains("--status-bar-override") {
            return true
        }
        if arguments.contains("--no-status-bar-override") {
            return false
        }
        return AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform) != "appleWatch"
    }

    public var studioLocales: [String] {
        locales
    }

    public var captureLocales: [String] {
        ScreenshotCapturePlan.captureLocales(from: locales)
    }

    public var requestedTargets: [ScreenshotCaptureTarget] {
        ScreenshotCapturePlan.targets(locales: studioLocales, slideIndexes: slideIndexes)
    }

    public var captureTargets: [ScreenshotCaptureTarget] {
        ScreenshotCapturePlan.targets(locales: captureLocales, slideIndexes: slideIndexes)
    }

    private static func parseCSVList(_ value: String?, fallback: [String]) throws -> [String] {
        guard let value, value.isEmpty == false else { return fallback }
        return value.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private static func parseSlideIndexes(_ value: String?, platform: String) throws -> [Int] {
        let slideCount = ScreenshotStudioWorkflow.slideCount(for: platform)
        guard let value, value.isEmpty == false else {
            return Array(0..<slideCount)
        }
        return try value.split(separator: ",").map { part in
            guard let slideIndex = Int(part.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                throw AppStoreScreenshotCaptureError.invalidSlideIndex(String(part))
            }
            guard (0..<slideCount).contains(slideIndex) else {
                throw AppStoreScreenshotCaptureError.invalidSlideIndex(String(slideIndex))
            }
            return slideIndex
        }
    }

    private static func parseMaxRetries(_ value: String?) throws -> Int {
        guard let value, value.isEmpty == false else {
            return ScreenshotCapturePlan.defaultMaxRetries
        }
        guard let retries = Int(value), retries > 0 else {
            throw AppStoreScreenshotCaptureError.invalidRetryCount(value)
        }
        return retries
    }
}

public enum AppStoreScreenshotCaptureError: LocalizedError {
    case invalidSlideIndex(String)
    case invalidRetryCount(String)
    case missingStudioImages([String])
    case incompleteCapture(missing: [String], report: ScreenshotCaptureReport?)
    case simulatorNotFound(String)
    case missingSimulatorName(String)
    case simulatorLookupFailed(String)
    case invalidAllPlatformsUsage(String)
    case invalidAppearance(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidSlideIndex(value):
            return "Invalid screenshot slide index: \(value)."
        case let .invalidRetryCount(value):
            return "Invalid retry count: \(value). Expected a positive integer."
        case let .missingStudioImages(paths):
            return "Missing Screenshot Studio images:\n" + paths.joined(separator: "\n")
        case let .incompleteCapture(missing, report):
            var message = "Screenshot capture incomplete; \(missing.count) image(s) still missing:\n"
            message += missing.map { "  \($0)" }.joined(separator: "\n")
            if let report, report.failed.isEmpty == false {
                message += "\n\nFailed captures this run:"
                for failure in report.failed {
                    message += "\n  \(failure.target): \(failure.error)"
                }
            }
            return message
        case let .simulatorNotFound(name):
            return "Could not find an available iOS Simulator named \(name)."
        case let .missingSimulatorName(destination):
            return "Could not parse simulator name from destination: \(destination)"
        case let .simulatorLookupFailed(message):
            return "Simulator lookup failed: \(message)"
        case let .invalidAllPlatformsUsage(message):
            return message
        case let .invalidAppearance(value):
            return "Invalid --appearance value '\(value)'. Use light or dark."
        }
    }
}

public enum AppStoreScreenshotCaptureWorkflow {
    private static let universalScreenshotTestName =
        "RetroRacingUniversalUITests/AppStoreScreenshotTests/testCaptureConfiguredScreenshot"
    private static let watchScreenshotTestName =
        "RetroRacingWatchOSUITests/AppStoreScreenshotTests/testCaptureConfiguredScreenshot"
    private static let screenshotTestTimeout: TimeInterval = 180

    private static func captureScheme(for platform: String) -> String {
        switch AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform) {
        case "appleWatch":
            return "RetroRacingWatchOS"
        default:
            return "RetroRacingUniversal"
        }
    }

    private static func screenshotTestName(for platform: String) -> String {
        switch AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform) {
        case "appleWatch":
            return watchScreenshotTestName
        default:
            return universalScreenshotTestName
        }
    }

    private static func duplicatesDerivedLocales(for platform: String) -> Bool {
        true
    }

    private static func shouldApplySimulatorCaptureLocale(for platform: String) -> Bool {
        switch AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform) {
        case "appleWatch", "iphone", "ipad":
            return true
        default:
            return false
        }
    }

    public static func run(repositoryRoot: URL, options: AppStoreScreenshotCaptureOptions) throws {
        if options.installOnly == false {
            try capture(repositoryRoot: repositoryRoot, options: options)
        }

        let placementOptions = ScreenshotStudioPlacementOptions(
            stagingDirectory: options.stagingDirectory,
            platform: options.platform,
            locales: options.locales,
            slideIndexes: options.slideIndexes,
            dryRun: options.dryRun,
            checkOnly: options.checkOnly
        )
        if options.installOnly == false, options.dryRun == false, options.checkOnly == false {
            print("Installing any remaining staged captures into Screenshot Studio…")
        }
        let placementResult = try ScreenshotStudioPlacementWorkflow.install(
            repositoryRoot: repositoryRoot,
            options: placementOptions
        )
        printPlacementSummary(placementResult)

        if options.dryRun == false, options.checkOnly == false {
            try ScreenshotStudioWorkflow.run(repositoryRoot: repositoryRoot, mode: .write)
        }

        let stillMissing = missingStagedFileNames(options: options)
        try ScreenshotCapturePlan.reconcileReport(
            in: options.stagingDirectory,
            fileExtension: ScreenshotStudioWorkflow.imageExtension(for: options.platform) ?? ".jpeg"
        )
        let report = ScreenshotCapturePlan.loadReport(from: options.stagingDirectory)

        if options.checkOnly {
            try ScreenshotStudioWorkflow.run(repositoryRoot: repositoryRoot, mode: .check)
            print("Screenshot capture check passed.")
        } else if options.dryRun {
            print("Dry run complete; no files were written.")
        } else if options.installOnly {
            if stillMissing.isEmpty {
                try ScreenshotStudioWorkflow.run(repositoryRoot: repositoryRoot, mode: .check)
                print("Screenshot install completed.")
            } else {
                print("Install-only mode skipped UI test capture; copied staged files only.")
                print("Still missing \(stillMissing.count) staged screenshot(s); run without --install-only to capture them.")
            }
        } else if stillMissing.isEmpty {
            try ScreenshotStudioWorkflow.run(repositoryRoot: repositoryRoot, mode: .check)
            print("Screenshot capture pipeline completed.")
        } else {
            printCaptureReport(report)
            throw AppStoreScreenshotCaptureError.incompleteCapture(
                missing: stillMissing,
                report: report
            )
        }
    }

    static func resolveSimulatorDestinationIfNeeded(
        _ options: AppStoreScreenshotCaptureOptions,
        devicesJSON: Data? = nil
    ) throws -> AppStoreScreenshotCaptureOptions {
        guard options.checkOnly == false,
              AppStoreScreenshotCaptureDefaults.normalizedPlatform(options.platform) != "mac" else {
            return options
        }

        let json = try devicesJSON ?? SimulatorDestinationResolver.loadAvailableDevicesJSON()
        let destination: String
        if options.usesExplicitDestination {
            destination = try SimulatorDestinationResolver.normalizeDestinationIfNeeded(
                options.destination,
                platform: options.platform,
                devicesJSON: json
            )
        } else {
            destination = try SimulatorDestinationResolver.resolveDefaultDestination(
                for: options.platform,
                devicesJSON: json
            )
        }
        guard destination != options.destination else { return options }

        print("Using simulator destination: \(destination)")
        return AppStoreScreenshotCaptureOptions(
            stagingDirectory: options.stagingDirectory,
            platform: options.platform,
            locales: options.locales,
            slideIndexes: options.slideIndexes,
            destination: destination,
            usesExplicitDestination: options.usesExplicitDestination,
            maxRetries: options.maxRetries,
            forceRecapture: options.forceRecapture,
            installOnly: options.installOnly,
            dryRun: options.dryRun,
            checkOnly: options.checkOnly,
            statusBarOverrideEnabled: options.statusBarOverrideEnabled,
            appearance: options.appearance
        )
    }

    private static func capture(repositoryRoot: URL, options: AppStoreScreenshotCaptureOptions) throws {
        let options = try resolveSimulatorDestinationIfNeeded(options)
        try FileManager.default.createDirectory(
            at: options.stagingDirectory,
            withIntermediateDirectories: true
        )

        let fileExtension = ScreenshotStudioWorkflow.imageExtension(for: options.platform) ?? ".jpeg"
        try ScreenshotCapturePlan.reconcileReport(
            in: options.stagingDirectory,
            fileExtension: fileExtension
        )
        let requestedTargets = options.requestedTargets
        let captureTargets = options.captureTargets
        let targetsToCapture: [ScreenshotCaptureTarget]
        if options.forceRecapture {
            targetsToCapture = captureTargets
        } else {
            targetsToCapture = ScreenshotCapturePlan.missingTargets(
                in: options.stagingDirectory,
                targets: captureTargets,
                fileExtension: fileExtension
            )
        }

        if targetsToCapture.isEmpty {
            print("All requested screenshots are already staged; skipping UI test capture.")
        } else {
            let derivedCount = requestedTargets.count - captureTargets.count
            print(
                "Capturing \(targetsToCapture.count) screenshot(s) across " +
                "\(options.captureLocales.count) locale(s); " +
                "\(captureTargets.count - targetsToCapture.count) already staged."
            )
            if derivedCount > 0, duplicatesDerivedLocales(for: options.platform) {
                print(
                    "Will duplicate \(derivedCount) derived locale(s) from shared captures " +
                    "(English variants and es-MX)."
                )
            }
        }

        if targetsToCapture.isEmpty == false {
            if options.dryRun == false {
                try ScreenshotCapturePlan.resetReport(in: options.stagingDirectory)
            }
            try runCaptureLoop(
                repositoryRoot: repositoryRoot,
                options: options,
                targetsToCapture: targetsToCapture,
                fileExtension: fileExtension,
                placementOptions: makePlacementOptions(from: options)
            )
        }

        let duplicated = duplicatesDerivedLocales(for: options.platform)
            ? try ScreenshotCapturePlan.duplicateDerivedCaptures(
                in: options.stagingDirectory,
                studioLocales: options.studioLocales,
                slideIndexes: options.slideIndexes,
                fileExtension: fileExtension
            )
            : []
        if duplicated.isEmpty == false, options.dryRun == false, options.checkOnly == false {
            print("Duplicated \(duplicated.count) derived screenshot(s) from shared captures.")
            for target in duplicated {
                let placementResult = try ScreenshotStudioPlacementWorkflow.installTarget(
                    repositoryRoot: repositoryRoot,
                    options: makePlacementOptions(from: options),
                    target: target
                )
                if placementResult.installed.isEmpty == false {
                    print("  -> installed \(target.stem) in Screenshot Studio")
                }
            }
        }

        try ScreenshotCapturePlan.reconcileReport(
            in: options.stagingDirectory,
            fileExtension: fileExtension
        )

        let report = ScreenshotCapturePlan.loadReport(from: options.stagingDirectory)
        printCaptureReport(report)

        let stillMissing = missingStagedFileNames(
            options: options,
            fileExtension: fileExtension
        )
        if stillMissing.isEmpty == false {
            print("Some captures are still missing after this run; re-run the command to retry only the missing files.")
        }
    }

    private static func runCaptureLoop(
        repositoryRoot: URL,
        options: AppStoreScreenshotCaptureOptions,
        targetsToCapture: [ScreenshotCaptureTarget],
        fileExtension: String,
        placementOptions: ScreenshotStudioPlacementOptions
    ) throws {
        print("Each successful capture installs immediately into Screenshot Studio.")

        if options.dryRun == false {
            print("Building UI test runner once…")
            try TestRunnerWorkflow.runBuildForTesting(
                repositoryRoot: repositoryRoot,
                destination: options.destination,
                scheme: captureScheme(for: options.platform),
                onlyTesting: [screenshotTestName(for: options.platform)],
                timeout: screenshotTestTimeout
            )
        } else {
            print("Dry run: would build UI test runner once, then capture without rebuilding.")
        }

        var didApplyStatusBarOverride = false
        var watchClockRestoreToken: WatchSimulatorClockWorkflow.RestoreToken?
        defer {
            if didApplyStatusBarOverride {
                do {
                    try SimulatorStatusBarWorkflow.clearMarketingOverride(
                        destination: options.destination,
                        dryRun: false
                    )
                } catch {
                    fputs(
                        "Warning: could not clear simulator status bar overrides: \(error.localizedDescription)\n",
                        stderr
                    )
                }
            }
            if let watchClockRestoreToken {
                do {
                    try WatchSimulatorClockWorkflow.restoreMarketingClock(watchClockRestoreToken)
                } catch {
                    fputs(
                        "Warning: could not restore host clock after watch capture: \(error.localizedDescription)\n",
                        stderr
                    )
                }
            }
            if shouldApplySimulatorCaptureLocale(for: options.platform), options.dryRun == false {
                do {
                    try WatchScreenshotCaptureLocaleWorkflow.restoreDefaultLocale(
                        destination: options.destination,
                        platform: options.platform,
                        dryRun: false
                    )
                } catch {
                    fputs(
                        "Warning: could not restore simulator locale after capture: \(error.localizedDescription)\n",
                        stderr
                    )
                }
            }
        }

        if WatchSimulatorClockWorkflow.shouldApply(
            platform: options.platform,
            enabled: options.statusBarOverrideEnabled
        ) {
            watchClockRestoreToken = try WatchSimulatorClockWorkflow.applyMarketingClock(
                destination: options.destination,
                dryRun: options.dryRun
            )
        }

        if SimulatorStatusBarWorkflow.shouldApplyOverride(
            platform: options.platform,
            enabled: options.statusBarOverrideEnabled
        ) {
            try SimulatorStatusBarWorkflow.applyMarketingOverride(
                destination: options.destination,
                dryRun: options.dryRun
            )
            didApplyStatusBarOverride = options.dryRun == false
        }

        if SimulatorAppearanceWorkflow.shouldApply(platform: options.platform) {
            try SimulatorAppearanceWorkflow.apply(
                appearance: options.appearance,
                destination: options.destination,
                dryRun: options.dryRun
            )
        } else if options.dryRun == false {
            print("Capture appearance: \(options.appearance.rawValue) (in-app preferredColorScheme)")
        }

        var capturedThisRun = 0
        var failedThisRun = 0
        var installedThisRun = 0

        for (index, target) in targetsToCapture.enumerated() {
            print("[\(index + 1)/\(targetsToCapture.count)] \(target.stem)")
            let outputURL = options.stagingDirectory.appending(path: target.stagedFileName(fileExtension: fileExtension))

            var succeeded = false
            for attempt in 1...options.maxRetries {
                if attempt > 1 {
                    print("  retry \(attempt)/\(options.maxRetries)")
                }

                if shouldApplySimulatorCaptureLocale(for: options.platform) {
                    do {
                        try WatchScreenshotCaptureLocaleWorkflow.applyCaptureLocale(
                            appStoreLocale: target.locale,
                            destination: options.destination,
                            platform: options.platform,
                            dryRun: options.dryRun
                        )
                    } catch {
                        fputs(
                            "Warning: could not apply simulator locale for \(target.locale) " +
                            "(in-app capture strings still follow launch arguments): " +
                            "\(error.localizedDescription)\n",
                            stderr
                        )
                    }
                }

                try ScreenshotCapturePlan.writeFilePlan(
                    stagingDirectory: options.stagingDirectory,
                    platform: options.platform,
                    targets: [target],
                    maxRetries: 1,
                    skipExisting: false,
                    fileExtension: fileExtension
                )
                print("  plan -> \(ScreenshotCapturePlan.activeFilePlanURL().path) (\(target.stem))")

                let environment = ScreenshotCapturePlan.captureEnvironment(
                    targets: [target],
                    maxRetries: 1,
                    skipExisting: false,
                    stagingDirectory: options.stagingDirectory,
                    fileExtension: fileExtension,
                    platform: options.platform,
                    appearance: options.appearance.rawValue
                )

                let testOptions = TestRunnerOptions(
                    destination: options.destination,
                    dryRun: options.dryRun,
                    onlyTesting: [screenshotTestName(for: options.platform)],
                    environment: environment,
                    timeout: screenshotTestTimeout,
                    buildMode: .testWithoutBuilding,
                    scheme: captureScheme(for: options.platform)
                )

                if options.dryRun {
                    try TestRunnerWorkflow.run(repositoryRoot: repositoryRoot, options: testOptions)
                    succeeded = true
                    break
                }

                if options.forceRecapture == false,
                   macCaptureIsStaged(
                    options: options,
                    target: target,
                    fileExtension: fileExtension
                ) {
                    succeeded = true
                    try? ScreenshotCapturePlan.recordSuccess(
                        target: target,
                        in: options.stagingDirectory
                    )
                    break
                }

                if options.forceRecapture, options.dryRun == false {
                    let stagedURL = options.stagingDirectory
                        .appending(path: target.stagedFileName(fileExtension: fileExtension))
                    try? FileManager.default.removeItem(at: stagedURL)
                }

                do {
                    try TestRunnerWorkflow.run(repositoryRoot: repositoryRoot, options: testOptions)
                } catch {
                    if markMacCaptureSucceededIfStaged(
                        options: options,
                        target: target,
                        fileExtension: fileExtension
                    ) {
                        succeeded = true
                        break
                    }
                    continue
                }

                if markMacCaptureSucceededIfStaged(
                    options: options,
                    target: target,
                    fileExtension: fileExtension
                ) {
                    succeeded = true
                    break
                }
            }

            if succeeded {
                capturedThisRun += 1
                if options.dryRun == false, options.checkOnly == false {
                    installedThisRun += try installCapturedTargetAndDerivatives(
                        repositoryRoot: repositoryRoot,
                        options: options,
                        placementOptions: placementOptions,
                        target: target,
                        fileExtension: fileExtension
                    )
                }
            } else {
                failedThisRun += 1
                let failureMessage = "Capture failed after \(options.maxRetries) attempt(s)"
                print("  \(failureMessage)")
                if options.dryRun == false {
                    try? ScreenshotCapturePlan.recordFailure(
                        target: target,
                        attempts: options.maxRetries,
                        error: failureMessage,
                        in: options.stagingDirectory
                    )
                }
            }
        }

        if options.dryRun == false {
            print(
                "Capture pass finished: \(capturedThisRun) captured, " +
                "\(installedThisRun) installed, \(failedThisRun) failed."
            )
        }
    }

    private static func installCapturedTargetAndDerivatives(
        repositoryRoot: URL,
        options: AppStoreScreenshotCaptureOptions,
        placementOptions: ScreenshotStudioPlacementOptions,
        target: ScreenshotCaptureTarget,
        fileExtension: String
    ) throws -> Int {
        var installedCount = 0

        let placementResult = try ScreenshotStudioPlacementWorkflow.installTarget(
            repositoryRoot: repositoryRoot,
            options: placementOptions,
            target: target
        )
        if placementResult.installed.isEmpty == false {
            installedCount += 1
            print("  -> installed \(target.stem) in Screenshot Studio")
        }

        let duplicated = duplicatesDerivedLocales(for: options.platform)
            ? try ScreenshotCapturePlan.duplicateDerivedCaptures(
                in: options.stagingDirectory,
                studioLocales: options.studioLocales,
                slideIndexes: [target.slideIndex],
                fileExtension: fileExtension
            )
            : []
        for derivedTarget in duplicated {
            let derivedResult = try ScreenshotStudioPlacementWorkflow.installTarget(
                repositoryRoot: repositoryRoot,
                options: placementOptions,
                target: derivedTarget
            )
            if derivedResult.installed.isEmpty == false {
                installedCount += 1
                print("  -> duplicated \(derivedTarget.stem) in Screenshot Studio")
            }
        }

        return installedCount
    }

    private static func makePlacementOptions(
        from options: AppStoreScreenshotCaptureOptions
    ) -> ScreenshotStudioPlacementOptions {
        ScreenshotStudioPlacementOptions(
            stagingDirectory: options.stagingDirectory,
            platform: options.platform,
            locales: options.locales,
            slideIndexes: options.slideIndexes,
            dryRun: options.dryRun,
            checkOnly: options.checkOnly
        )
    }

    private static func missingStagedFileNames(
        options: AppStoreScreenshotCaptureOptions,
        fileExtension: String? = nil
    ) -> [String] {
        let extensionValue = fileExtension
            ?? ScreenshotStudioWorkflow.imageExtension(for: options.platform)
            ?? ".jpeg"
        return ScreenshotCapturePlan.missingTargets(
            in: options.stagingDirectory,
            targets: options.requestedTargets,
            fileExtension: extensionValue
        ).map { $0.stagedFileName(fileExtension: extensionValue) }
    }

    private static func printCaptureReport(_ report: ScreenshotCaptureReport?) {
        guard let report else { return }
        if report.captured.isEmpty == false {
            print("Captured this run:")
            for entry in report.captured {
                print("  \(entry)")
            }
        }
        if report.skippedExisting.isEmpty == false {
            print("Skipped existing staged captures:")
            for entry in report.skippedExisting {
                print("  \(entry)")
            }
        }
        if report.failed.isEmpty == false {
            print("Outstanding capture failures:")
            for failure in report.failed {
                print("  \(failure.target) (\(failure.attempts) attempts): \(failure.error)")
            }
        }
    }

    private static func printPlacementSummary(_ result: ScreenshotStudioPlacementResult) {
        if result.installed.isEmpty == false {
            print("Installed screenshot captures:")
            for entry in result.installed {
                print("  \(entry)")
            }
        }
        if result.missing.isEmpty == false {
            print("Missing staged screenshot captures:")
            for entry in result.missing {
                print("  \(entry)")
            }
        }
    }

    @discardableResult
    private static func macCaptureIsStaged(
        options: AppStoreScreenshotCaptureOptions,
        target: ScreenshotCaptureTarget,
        fileExtension: String
    ) -> Bool {
        let canonicalURL = options.stagingDirectory
            .appending(path: target.stagedFileName(fileExtension: fileExtension))
        return FileManager.default.fileExists(atPath: canonicalURL.path)
    }

    @discardableResult
    private static func markMacCaptureSucceededIfStaged(
        options: AppStoreScreenshotCaptureOptions,
        target: ScreenshotCaptureTarget,
        fileExtension: String
    ) -> Bool {
        if macCaptureIsStaged(options: options, target: target, fileExtension: fileExtension) {
            try? ScreenshotCapturePlan.recordSuccess(
                target: target,
                in: options.stagingDirectory
            )
            return true
        }
        if syncMacRuntimeCaptureIfNeeded(
            options: options,
            target: target,
            fileExtension: fileExtension
        ) {
            try? ScreenshotCapturePlan.recordSuccess(
                target: target,
                in: options.stagingDirectory
            )
            return true
        }
        return false
    }

    @discardableResult
    private static func syncMacRuntimeCaptureIfNeeded(
        options: AppStoreScreenshotCaptureOptions,
        target: ScreenshotCaptureTarget,
        fileExtension: String
    ) -> Bool {
        guard AppStoreScreenshotCaptureDefaults.normalizedPlatform(options.platform) == "mac" else {
            return false
        }

        let canonicalURL = options.stagingDirectory
            .appending(path: target.stagedFileName(fileExtension: fileExtension))
        if FileManager.default.fileExists(atPath: canonicalURL.path) {
            return true
        }

        let runtimeURL = AppStoreScreenshotCaptureDefaults.macFlatCaptureURL(
            locale: target.locale,
            slideIndex: target.slideIndex,
            fileExtension: fileExtension
        )
        if FileManager.default.fileExists(atPath: runtimeURL.path) == false {
            let runtimeDirectory = ScreenshotCapturePlan.resolvedMacRuntimeStagingDirectory()
                ?? AppStoreScreenshotCaptureDefaults.macUITestRuntimeStagingDirectory()
            let legacyURL = runtimeDirectory
                .appending(path: target.stagedFileName(fileExtension: fileExtension))
            guard FileManager.default.fileExists(atPath: legacyURL.path) else {
                return false
            }
            return copyMacRuntimeCapture(from: legacyURL, to: options, target: target, fileExtension: fileExtension)
        }

        return copyMacRuntimeCapture(from: runtimeURL, to: options, target: target, fileExtension: fileExtension)
    }

    @discardableResult
    private static func copyMacRuntimeCapture(
        from runtimeURL: URL,
        to options: AppStoreScreenshotCaptureOptions,
        target: ScreenshotCaptureTarget,
        fileExtension: String
    ) -> Bool {
        let canonicalURL = options.stagingDirectory
            .appending(path: target.stagedFileName(fileExtension: fileExtension))
        do {
            try FileManager.default.createDirectory(
                at: options.stagingDirectory,
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: canonicalURL.path) {
                try FileManager.default.removeItem(at: canonicalURL)
            }
            try FileManager.default.copyItem(at: runtimeURL, to: canonicalURL)
            return true
        } catch {
            print("  warning: failed to sync Mac capture from \(runtimeURL.path): \(error.localizedDescription)")
            return false
        }
    }
}

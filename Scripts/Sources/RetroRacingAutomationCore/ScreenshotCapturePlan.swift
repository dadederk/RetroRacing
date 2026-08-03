//
//  ScreenshotCapturePlan.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public struct ScreenshotCaptureTarget: Equatable, Sendable, Hashable {
    public let locale: String
    public let slideIndex: Int

    public init(locale: String, slideIndex: Int) {
        self.locale = locale
        self.slideIndex = slideIndex
    }

    public var stem: String {
        "\(locale)_\(slideIndex)"
    }

    public func stagedFileName(fileExtension: String = ".jpeg") -> String {
        "\(stem)\(fileExtension)"
    }
}

public struct ScreenshotCaptureReport: Codable, Equatable, Sendable {
    public struct Failure: Codable, Equatable, Sendable {
        public let target: String
        public let attempts: Int
        public let error: String

        public init(target: String, attempts: Int, error: String) {
            self.target = target
            self.attempts = attempts
            self.error = error
        }
    }

    public let captured: [String]
    public let skippedExisting: [String]
    public let failed: [Failure]

    public init(
        captured: [String],
        skippedExisting: [String],
        failed: [Failure]
    ) {
        self.captured = captured
        self.skippedExisting = skippedExisting
        self.failed = failed
    }

    public static let reportFileName = "capture-report.json"
}

public enum ScreenshotCapturePlan {
    public static let captureEnabledEnvironmentKey = "RETRORAPID_SCREENSHOT_CAPTURE"
    public static let targetsEnvironmentKey = "RETRORAPID_SCREENSHOT_TARGETS"
    public static let maxRetriesEnvironmentKey = "RETRORAPID_SCREENSHOT_MAX_RETRIES"
    public static let skipExistingEnvironmentKey = "RETRORAPID_SCREENSHOT_SKIP_EXISTING"
    public static let fileExtensionEnvironmentKey = "RETRORAPID_SCREENSHOT_FILE_EXTENSION"
    public static let platformEnvironmentKey = "RETRORAPID_SCREENSHOT_PLATFORM"
    public static let appearanceEnvironmentKey = "RETRORAPID_SCREENSHOT_APPEARANCE"
    public static let defaultMaxRetries = 3

    /// App Store locales whose in-app screenshot pixels match another locale and can be copied.
    public static let derivedLocaleMap: [String: [String]] = [
        "en-US": ["en-GB", "en-AU", "en-CA"],
        "es-ES": ["es-MX"],
    ]

    public static func sourceLocale(for appStoreLocale: String) -> String? {
        for (sourceLocale, derivedLocales) in derivedLocaleMap {
            if derivedLocales.contains(appStoreLocale) {
                return sourceLocale
            }
        }
        return nil
    }

    public static func derivedLocales(for sourceLocale: String) -> [String] {
        derivedLocaleMap[sourceLocale] ?? []
    }

    public static func captureLocales(from studioLocales: [String]) -> [String] {
        var seen = Set<String>()
        var ordered = [String]()
        for locale in studioLocales {
            let captureLocale = sourceLocale(for: locale) ?? locale
            guard seen.insert(captureLocale).inserted else { continue }
            ordered.append(captureLocale)
        }
        return ordered
    }

    public static func targets(
        locales: [String],
        slideIndexes: [Int]
    ) -> [ScreenshotCaptureTarget] {
        locales.flatMap { locale in
            slideIndexes.map { slideIndex in
                ScreenshotCaptureTarget(locale: locale, slideIndex: slideIndex)
            }
        }
    }

    public static func encode(_ targets: [ScreenshotCaptureTarget]) -> String {
        targets.map(\.stem).joined(separator: ",")
    }

    public static func decode(_ value: String) -> [ScreenshotCaptureTarget] {
        value
            .split(separator: ",")
            .compactMap { parseTargetStem(String($0)) }
    }

    public static func parseTargetStem(_ stem: String) -> ScreenshotCaptureTarget? {
        guard let separatorIndex = stem.lastIndex(of: "_") else { return nil }
        let locale = String(stem[..<separatorIndex])
        let slideIndexString = String(stem[stem.index(after: separatorIndex)...])
        guard let slideIndex = Int(slideIndexString) else { return nil }
        return ScreenshotCaptureTarget(locale: locale, slideIndex: slideIndex)
    }

    public static func missingTargets(
        in stagingDirectory: URL,
        targets: [ScreenshotCaptureTarget],
        fileExtension: String = ".jpeg"
    ) -> [ScreenshotCaptureTarget] {
        targets.filter { target in
            let url = stagingDirectory.appending(path: target.stagedFileName(fileExtension: fileExtension))
            return FileManager.default.fileExists(atPath: url.path) == false
        }
    }

    public static func reportURL(in stagingDirectory: URL) -> URL {
        stagingDirectory.appending(path: ScreenshotCaptureReport.reportFileName)
    }

    public static func loadReport(from stagingDirectory: URL) -> ScreenshotCaptureReport? {
        let url = reportURL(in: stagingDirectory)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ScreenshotCaptureReport.self, from: data)
    }

    public static func captureEnvironment(
        targets: [ScreenshotCaptureTarget],
        maxRetries: Int,
        skipExisting: Bool,
        stagingDirectory: URL,
        fileExtension: String,
        platform: String,
        appearance: String = AppStoreScreenshotAppearance.default.rawValue
    ) -> [String: String] {
        [
            captureEnabledEnvironmentKey: "1",
            "RETRORAPID_SCREENSHOT_STAGING": stagingDirectory.path,
            targetsEnvironmentKey: encode(targets),
            maxRetriesEnvironmentKey: String(maxRetries),
            skipExistingEnvironmentKey: skipExisting ? "1" : "0",
            fileExtensionEnvironmentKey: fileExtension,
            platformEnvironmentKey: platform,
            appearanceEnvironmentKey: appearance,
        ]
    }

    public struct FilePlan: Codable, Equatable, Sendable {
        public let stagingDirectory: String
        public let runtimeStagingDirectory: String?
        public let targets: [String]
        public let maxRetries: Int
        public let skipExisting: Bool
        public let fileExtension: String?
        public let platform: String?

        public init(
            stagingDirectory: URL,
            targets: [ScreenshotCaptureTarget],
            maxRetries: Int,
            skipExisting: Bool,
            fileExtension: String,
            platform: String,
            runtimeStagingDirectory: URL? = nil
        ) {
            self.stagingDirectory = stagingDirectory.path
            self.runtimeStagingDirectory = runtimeStagingDirectory?.path
            self.targets = targets.map(\.stem)
            self.maxRetries = maxRetries
            self.skipExisting = skipExisting
            self.fileExtension = fileExtension
            self.platform = platform
        }

        public var resolvedFileExtension: String {
            fileExtension ?? ".jpeg"
        }

        public var resolvedRuntimeStagingDirectory: URL? {
            guard let runtimeStagingDirectory, runtimeStagingDirectory.isEmpty == false else {
                return nil
            }
            return URL(fileURLWithPath: runtimeStagingDirectory, isDirectory: true)
        }
    }

    public static let filePlanFileName = "capture-plan.json"
    public static let activeFilePlanFileName = "retrorapid-capture-plan-active.json"

    public static func platformFilePlanURL(platform: String) -> URL {
        URL(fileURLWithPath: "/tmp/retrorapid-capture-plan-\(platform).json")
    }

    public static func activeFilePlanURL() -> URL {
        URL(fileURLWithPath: "/tmp/\(activeFilePlanFileName)")
    }

    public static func filePlanURL(in stagingDirectory: URL) -> URL {
        stagingDirectory.appending(path: filePlanFileName)
    }

    public static func writeFilePlan(
        stagingDirectory: URL,
        platform: String,
        targets: [ScreenshotCaptureTarget],
        maxRetries: Int,
        skipExisting: Bool,
        fileExtension: String
    ) throws {
        let plan = FilePlan(
            stagingDirectory: stagingDirectory,
            targets: targets,
            maxRetries: maxRetries,
            skipExisting: skipExisting,
            fileExtension: fileExtension,
            platform: platform
        )
        let data = try JSONEncoder().encode(plan)
        let stagingPlanURL = filePlanURL(in: stagingDirectory)
        try data.write(to: stagingPlanURL, options: .atomic)
        try data.write(to: platformFilePlanURL(platform: platform), options: .atomic)
        try data.write(to: activeFilePlanURL(), options: .atomic)
    }

    public static func loadFilePlan(from stagingDirectory: URL) -> FilePlan? {
        let url = filePlanURL(in: stagingDirectory)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(FilePlan.self, from: data)
    }

    public static func loadFilePlan(platform: String) -> FilePlan? {
        let url = platformFilePlanURL(platform: platform)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(FilePlan.self, from: data)
    }

    public static func loadActiveFilePlan() -> FilePlan? {
        let url = activeFilePlanURL()
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(FilePlan.self, from: data)
    }

    public static func resolvedMacRuntimeStagingDirectory() -> URL? {
        if let plan = loadActiveFilePlan()?.resolvedRuntimeStagingDirectory {
            return plan
        }
        if let plan = loadFilePlan(platform: "mac")?.resolvedRuntimeStagingDirectory {
            return plan
        }
        return nil
    }

    public static func reconcileReport(
        in stagingDirectory: URL,
        fileExtension: String = ".jpeg"
    ) throws {
        guard var report = loadReport(from: stagingDirectory) else { return }

        let reconciledFailures = report.failed.filter { failure in
            guard let target = parseTargetStem(failure.target) else { return true }
            let url = stagingDirectory.appending(path: target.stagedFileName(fileExtension: fileExtension))
            return FileManager.default.fileExists(atPath: url.path) == false
        }

        guard reconciledFailures.count != report.failed.count else { return }

        report = ScreenshotCaptureReport(
            captured: report.captured,
            skippedExisting: report.skippedExisting,
            failed: reconciledFailures
        )
        try writeReport(report, to: stagingDirectory)
    }

    public static func resetReport(in stagingDirectory: URL) throws {
        try writeReport(
            ScreenshotCaptureReport(captured: [], skippedExisting: [], failed: []),
            to: stagingDirectory
        )
    }

    public static func writeReport(_ report: ScreenshotCaptureReport, to stagingDirectory: URL) throws {
        let data = try JSONEncoder().encode(report)
        try data.write(to: reportURL(in: stagingDirectory), options: .atomic)
    }

    public static func recordFailure(
        target: ScreenshotCaptureTarget,
        attempts: Int,
        error: String,
        in stagingDirectory: URL
    ) throws {
        var report = loadReport(from: stagingDirectory) ?? ScreenshotCaptureReport(
            captured: [],
            skippedExisting: [],
            failed: []
        )
        var failures = report.failed.filter { $0.target != target.stem }
        failures.append(
            ScreenshotCaptureReport.Failure(
                target: target.stem,
                attempts: attempts,
                error: error
            )
        )
        let captured = report.captured.filter { $0 != target.stem }
        report = ScreenshotCaptureReport(
            captured: captured,
            skippedExisting: report.skippedExisting,
            failed: failures
        )
        try writeReport(report, to: stagingDirectory)
    }

    public static func recordSuccess(
        target: ScreenshotCaptureTarget,
        in stagingDirectory: URL
    ) throws {
        var report = loadReport(from: stagingDirectory) ?? ScreenshotCaptureReport(
            captured: [],
            skippedExisting: [],
            failed: []
        )
        var captured = report.captured.filter { $0 != target.stem }
        captured.append(target.stem)
        let failures = report.failed.filter { $0.target != target.stem }
        report = ScreenshotCaptureReport(
            captured: captured,
            skippedExisting: report.skippedExisting,
            failed: failures
        )
        try writeReport(report, to: stagingDirectory)
    }

    @discardableResult
    public static func duplicateDerivedCaptures(
        in stagingDirectory: URL,
        studioLocales: [String],
        slideIndexes: [Int],
        fileExtension: String = ".jpeg"
    ) throws -> [ScreenshotCaptureTarget] {
        var duplicated = [ScreenshotCaptureTarget]()

        for (sourceLocale, derivedLocales) in derivedLocaleMap {
            let requestedDerivedLocales = derivedLocales.filter { studioLocales.contains($0) }
            guard studioLocales.contains(sourceLocale) || requestedDerivedLocales.isEmpty == false else {
                continue
            }

            for slideIndex in slideIndexes {
                let sourceTarget = ScreenshotCaptureTarget(locale: sourceLocale, slideIndex: slideIndex)
                let sourceURL = stagingDirectory.appending(
                    path: sourceTarget.stagedFileName(fileExtension: fileExtension)
                )
                guard FileManager.default.fileExists(atPath: sourceURL.path) else { continue }

                let sourceData = try Data(contentsOf: sourceURL)
                for derivedLocale in requestedDerivedLocales {
                    let derivedTarget = ScreenshotCaptureTarget(locale: derivedLocale, slideIndex: slideIndex)
                    let destinationURL = stagingDirectory.appending(
                        path: derivedTarget.stagedFileName(fileExtension: fileExtension)
                    )
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        continue
                    }
                    try sourceData.write(to: destinationURL, options: .atomic)
                    duplicated.append(derivedTarget)
                }
            }
        }

        return duplicated
    }
}

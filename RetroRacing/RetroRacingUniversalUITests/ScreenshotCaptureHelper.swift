//
//  ScreenshotCaptureHelper.swift
//  RetroRacingUniversalUITests
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import XCTest
#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

enum AppStoreScreenshotCaptureConstants {
    // Keep in sync with RetroRacingShared/ScreenshotCapture/ScreenshotCaptureIdentifiers.swift
    // and Scripts/Sources/RetroRacingAutomationCore/ScreenshotCapturePlan.swift.
    static let captureEnabledKey = "RETRORAPID_SCREENSHOT_CAPTURE"
    static let slideIndexKey = "RETRORAPID_SCREENSHOT_SLIDE"
    static let stagingDirectoryKey = "RETRORAPID_SCREENSHOT_STAGING"
    static let targetsKey = "RETRORAPID_SCREENSHOT_TARGETS"
    static let maxRetriesKey = "RETRORAPID_SCREENSHOT_MAX_RETRIES"
    static let skipExistingKey = "RETRORAPID_SCREENSHOT_SKIP_EXISTING"
    static let fileExtensionKey = "RETRORAPID_SCREENSHOT_FILE_EXTENSION"
    static let platformKey = "RETRORAPID_SCREENSHOT_PLATFORM"
    static let appearanceKey = "RETRORAPID_SCREENSHOT_APPEARANCE"
    static let activeFilePlanFileName = "retrorapid-capture-plan-active.json"
    static let filePlanFileName = "capture-plan.json"
    static let reportFileName = "capture-report.json"
    static let universalSlideCount = 10
    static let macSlideCount = 9
    static let defaultMaxRetries = 3

    static func readinessIdentifier(slideIndex: Int) -> String {
        "screenshot-ready-slide-\(slideIndex)"
    }

    static func inAppLanguageIdentifier(for appStoreLocale: String) -> String {
        switch appStoreLocale {
        case "de-DE": return "de"
        case "nl-NL": return "nl"
        case "fr-FR": return "fr"
        case "es-ES", "es-MX": return "es"
        case "ca": return "ca"
        case "en-US": return "en"
        case "en-GB": return "en-GB"
        case "en-AU": return "en-AU"
        case "en-CA": return "en-CA"
        default: return appStoreLocale
        }
    }
}

struct ScreenshotCapturePlanTarget {
    let locale: String
    let slideIndex: Int

    var key: String {
        "\(locale)_\(slideIndex)"
    }
}

struct ScreenshotCaptureRunPlan {
    let targets: [ScreenshotCapturePlanTarget]
    let maxRetries: Int
    let skipExisting: Bool
}

struct ScreenshotCaptureReportFailure: Codable {
    let target: String
    let attempts: Int
    let error: String
}

private struct ScreenshotCaptureFilePlan: Codable {
    let stagingDirectory: String
    let runtimeStagingDirectory: String?
    let targets: [String]
    let maxRetries: Int
    let skipExisting: Bool
    let fileExtension: String?
    let platform: String?

    init(
        stagingDirectory: String,
        runtimeStagingDirectory: String? = nil,
        targets: [String],
        maxRetries: Int,
        skipExisting: Bool,
        fileExtension: String?,
        platform: String?
    ) {
        self.stagingDirectory = stagingDirectory
        self.runtimeStagingDirectory = runtimeStagingDirectory
        self.targets = targets
        self.maxRetries = maxRetries
        self.skipExisting = skipExisting
        self.fileExtension = fileExtension
        self.platform = platform
    }

    var resolvedFileExtension: String {
        fileExtension ?? ".jpeg"
    }

    var resolvedPlatform: String? {
        if let platform, platform.isEmpty == false {
            return platform
        }
        if stagingDirectory.contains("/screenshot-capture/ipad") {
            return "ipad"
        }
        if stagingDirectory.contains("/screenshot-capture/mac") {
            return "mac"
        }
        if stagingDirectory.contains("/screenshot-capture/iphone") {
            return "iphone"
        }
        return nil
    }
}

enum ScreenshotCaptureHelper {
    static let filePlanFileName = AppStoreScreenshotCaptureConstants.filePlanFileName

    static func readinessIdentifier(slideIndex: Int) -> String {
        AppStoreScreenshotCaptureConstants.readinessIdentifier(slideIndex: slideIndex)
    }

    static func readinessSignalFileName(slideIndex: Int) -> String {
        "capture-ready-\(slideIndex).signal"
    }

    static func captureRootSignalFileName(slideIndex: Int) -> String {
        "capture-root-\(slideIndex).signal"
    }

    static func removeReadinessSignals(slideIndex: Int) {
        for fileName in [
            readinessSignalFileName(slideIndex: slideIndex),
            captureRootSignalFileName(slideIndex: slideIndex),
        ] {
            #if os(macOS)
            let url = URL(fileURLWithPath: "/tmp", isDirectory: true).appendingPathComponent(fileName)
            #else
            let url = stagingDirectory().appendingPathComponent(fileName)
            #endif
            try? FileManager.default.removeItem(at: url)
        }
    }

    static func waitForReadinessSignal(slideIndex: Int, timeout: TimeInterval) -> Bool {
        let signalURL = stagingDirectory().appendingPathComponent(readinessSignalFileName(slideIndex: slideIndex))
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if FileManager.default.fileExists(atPath: signalURL.path) {
                return true
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return false
    }

    static func readinessSignalExists(slideIndex: Int) -> Bool {
        #if os(macOS)
        let signalURL = URL(fileURLWithPath: "/tmp", isDirectory: true)
            .appendingPathComponent(readinessSignalFileName(slideIndex: slideIndex))
        #else
        let signalURL = stagingDirectory().appendingPathComponent(readinessSignalFileName(slideIndex: slideIndex))
        #endif
        return FileManager.default.fileExists(atPath: signalURL.path)
    }

    private static func configuredStagingDirectoryURL() -> URL? {
        guard let configured = ProcessInfo.processInfo.environment[
            AppStoreScreenshotCaptureConstants.stagingDirectoryKey
        ] else {
            return nil
        }
        return URL(fileURLWithPath: configured, isDirectory: true)
    }

    static func stagingDirectory() -> URL {
        if let filePlan = loadFilePlan() {
            return URL(fileURLWithPath: filePlan.stagingDirectory, isDirectory: true)
        }
        if let configured = configuredStagingDirectoryURL() {
            return configured
        }
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("retrorapid-screenshot-capture", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func outputURL(locale: String, slideIndex: Int) -> URL {
        return stagingDirectory().appendingPathComponent("\(locale)_\(slideIndex)\(fileExtension())")
    }

    static func fileExtension() -> String {
        if let filePlan = loadFilePlan() {
            return filePlan.resolvedFileExtension
        }
        if let configured = ProcessInfo.processInfo.environment[AppStoreScreenshotCaptureConstants.fileExtensionKey],
           configured.isEmpty == false {
            return configured.hasPrefix(".") ? configured : ".\(configured)"
        }
        return ".jpeg"
    }

    static func prefersLandscapeCapture() -> Bool {
        loadFilePlan()?.resolvedPlatform == "ipad"
    }

    static func capturePlan() -> ScreenshotCaptureRunPlan {
        if let filePlan = loadFilePlan() {
            return ScreenshotCaptureRunPlan(
                targets: parseTargetStems(filePlan.targets),
                maxRetries: max(1, filePlan.maxRetries),
                skipExisting: filePlan.skipExisting
            )
        }

        let environment = ProcessInfo.processInfo.environment
        let targets = parseTargets(from: environment[AppStoreScreenshotCaptureConstants.targetsKey])
        let maxRetries = Int(environment[AppStoreScreenshotCaptureConstants.maxRetriesKey] ?? "")
            ?? AppStoreScreenshotCaptureConstants.defaultMaxRetries
        let skipExisting = environment[AppStoreScreenshotCaptureConstants.skipExistingKey] != "0"
        return ScreenshotCaptureRunPlan(
            targets: targets,
            maxRetries: max(1, maxRetries),
            skipExisting: skipExisting
        )
    }

    static func configureLaunch(
        for app: XCUIApplication,
        locale: String,
        slideIndex: Int
    ) {
        let language = AppStoreScreenshotCaptureConstants.inAppLanguageIdentifier(for: locale)
        let appearance = appearanceArgument()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale.replacingOccurrences(of: "-", with: "_"),
            "-ScreenshotCaptureEnabled", "1",
            "-ScreenshotCaptureSlide", String(slideIndex),
            "-ScreenshotCaptureStaging", stagingDirectory().path,
            "-ScreenshotCapturePlatform", loadFilePlan()?.resolvedPlatform ?? "",
            "-ScreenshotCaptureAppearance", appearance,
        ]
        app.launchEnvironment = [
            AppStoreScreenshotCaptureConstants.captureEnabledKey: "1",
            AppStoreScreenshotCaptureConstants.slideIndexKey: String(slideIndex),
            AppStoreScreenshotCaptureConstants.stagingDirectoryKey: stagingDirectory().path,
            AppStoreScreenshotCaptureConstants.fileExtensionKey: fileExtension(),
            AppStoreScreenshotCaptureConstants.platformKey: loadFilePlan()?.resolvedPlatform ?? "",
            AppStoreScreenshotCaptureConstants.appearanceKey: appearance,
            "UITesting": "1",
        ]
    }

    static func appearanceArgument() -> String {
        let raw = ProcessInfo.processInfo.environment[AppStoreScreenshotCaptureConstants.appearanceKey]
            ?? "light"
        switch raw.lowercased() {
        case "dark":
            return "dark"
        default:
            return "light"
        }
    }

    static func saveScreenshot(_ screenshot: XCUIScreenshot, to url: URL) throws {
        let pngData = screenshot.pngRepresentation
        guard pngData.isEmpty == false else {
            throw ScreenshotCaptureError.emptyScreenshotData
        }
        let outputData = try encodedScreenshotData(pngData: pngData, destinationURL: url)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        #if os(macOS)
        try outputData.write(to: url, options: .atomic)
        #else
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("retrorapid-screenshot-\(UUID().uuidString)\(url.pathExtension.isEmpty ? "" : ".\(url.pathExtension)")")
        defer {
            try? FileManager.default.removeItem(at: temporaryURL)
        }

        try outputData.write(to: temporaryURL, options: .atomic)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try FileManager.default.moveItem(at: temporaryURL, to: url)
        #endif

        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attributes[.size] as? Int ?? 0
        guard size > 0 else {
            throw ScreenshotCaptureError.missingOutputFile(url.lastPathComponent)
        }
    }

    private static func encodedScreenshotData(pngData: Data, destinationURL: URL) throws -> Data {
        let ext = destinationURL.pathExtension.lowercased()
        guard ext == "jpeg" || ext == "jpg" else {
            return normalizedLandscapePNGDataIfNeeded(pngData) ?? pngData
        }
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        guard var image = UIImage(data: pngData) else {
            throw ScreenshotCaptureError.emptyScreenshotData
        }
        image = normalizedLandscapeCaptureImage(image)
        if prefersLandscapeCapture() {
            print(
                "Saving iPad landscape capture at \(Int(image.size.width))x\(Int(image.size.height)) " +
                "(\(destinationURL.lastPathComponent))"
            )
        }
        try validateLandscapeCaptureDimensions(image)
        guard let jpegData = image.jpegData(compressionQuality: 0.92) else {
            throw ScreenshotCaptureError.emptyScreenshotData
        }
        return jpegData
        #elseif os(macOS)
        guard let image = NSImage(data: pngData),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(
                using: .jpeg,
                properties: [.compressionFactor: 0.92]
              ) else {
            throw ScreenshotCaptureError.emptyScreenshotData
        }
        return jpegData
        #else
        return pngData
        #endif
    }

    private static func normalizedLandscapePNGDataIfNeeded(_ pngData: Data) -> Data? {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        guard prefersLandscapeCapture(),
              let image = UIImage(data: pngData) else {
            return nil
        }
        let normalized = normalizedLandscapeCaptureImage(image)
        return normalized.pngData()
        #else
        return nil
        #endif
    }

    #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
    private static func normalizedLandscapeCaptureImage(_ image: UIImage) -> UIImage {
        guard prefersLandscapeCapture() else { return image }

        let upright = image.uprightNormalized()
        guard upright.size.width < upright.size.height else {
            return upright
        }

        // Portrait-sized buffers from landscape simulators keep upright content;
        // rotate counter-clockwise to landscape dimensions.
        return upright.rotated(by: -.pi / 2) ?? upright
    }

    private static func validateLandscapeCaptureDimensions(_ image: UIImage) throws {
        guard prefersLandscapeCapture() else { return }
        guard image.size.width >= image.size.height else {
            throw ScreenshotCaptureError.portraitOutputInLandscapeCapture(
                width: Int(image.size.width),
                height: Int(image.size.height)
            )
        }
    }
    #endif

    static func writeReport(
        captured: [String],
        skippedExisting: [String],
        failures: [ScreenshotCaptureReportFailure]
    ) throws {
        let existing = loadExistingReport()
        let mergedCaptured = orderedUnique(existing?.captured ?? [] + captured)
        let mergedSkipped = orderedUnique(existing?.skippedExisting ?? [] + skippedExisting)
        var mergedFailures = existing?.failed ?? []
        let capturedTargets = Set(mergedCaptured)
        mergedFailures.removeAll { capturedTargets.contains($0.target) }
        let failureTargets = Set(mergedFailures.map(\.target))
        for failure in failures where failureTargets.contains(failure.target) == false {
            mergedFailures.append(failure)
        }

        let payload: [String: Any] = [
            "captured": mergedCaptured,
            "skippedExisting": mergedSkipped,
            "failed": mergedFailures.map {
                [
                    "target": $0.target,
                    "attempts": $0.attempts,
                    "error": $0.error,
                ]
            },
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys, .prettyPrinted])
        let url = stagingDirectory().appendingPathComponent(AppStoreScreenshotCaptureConstants.reportFileName)
        try data.write(to: url, options: .atomic)
    }

    private static func loadExistingReport() -> (captured: [String], skippedExisting: [String], failed: [ScreenshotCaptureReportFailure])? {
        let url = stagingDirectory().appendingPathComponent(AppStoreScreenshotCaptureConstants.reportFileName)
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let captured = json["captured"] as? [String] ?? []
        let skippedExisting = json["skippedExisting"] as? [String] ?? []
        let failedPayload = json["failed"] as? [[String: Any]] ?? []
        let failed = failedPayload.compactMap { entry -> ScreenshotCaptureReportFailure? in
            guard let target = entry["target"] as? String,
                  let attempts = entry["attempts"] as? Int,
                  let error = entry["error"] as? String else {
                return nil
            }
            return ScreenshotCaptureReportFailure(target: target, attempts: attempts, error: error)
        }
        return (captured, skippedExisting, failed)
    }

    private static func orderedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var ordered = [String]()
        for value in values where seen.insert(value).inserted {
            ordered.append(value)
        }
        return ordered
    }

    private static func activeFilePlanURL() -> URL {
        URL(fileURLWithPath: "/tmp/\(AppStoreScreenshotCaptureConstants.activeFilePlanFileName)")
    }

    private static func platformFilePlanURL(platform: String) -> URL {
        URL(fileURLWithPath: "/tmp/retrorapid-capture-plan-\(platform).json")
    }

    private static func inferredPlatform(from stagingPath: String) -> String? {
        if stagingPath.hasSuffix("/ipad") || stagingPath.contains("/screenshot-capture/ipad") {
            return "ipad"
        }
        if stagingPath.hasSuffix("/mac") || stagingPath.contains("/screenshot-capture/mac") {
            return "mac"
        }
        if stagingPath.hasSuffix("/iphone") || stagingPath.contains("/screenshot-capture/iphone") {
            return "iphone"
        }
        return nil
    }

    private static func decodeFilePlan(at url: URL) -> ScreenshotCaptureFilePlan? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ScreenshotCaptureFilePlan.self, from: data)
    }

    private static func loadFilePlan() -> ScreenshotCaptureFilePlan? {
        if let plan = decodeFilePlan(at: activeFilePlanURL()) {
            return plan
        }

        let environment = ProcessInfo.processInfo.environment
        let stagingPath = environment[AppStoreScreenshotCaptureConstants.stagingDirectoryKey]
        let platform = environment[AppStoreScreenshotCaptureConstants.platformKey]
            ?? stagingPath.flatMap(inferredPlatform(from:))

        if let stagingPath,
           let plan = decodeFilePlan(
               at: URL(fileURLWithPath: stagingPath, isDirectory: true)
                   .appendingPathComponent(AppStoreScreenshotCaptureConstants.filePlanFileName)
           ) {
            return plan
        }

        if let platform,
           let plan = decodeFilePlan(at: platformFilePlanURL(platform: platform)) {
            return plan
        }

        let platformPlans = (["ipad", "iphone", "mac"]).compactMap { platform -> (Date, ScreenshotCaptureFilePlan)? in
            let url = platformFilePlanURL(platform: platform)
            guard let plan = decodeFilePlan(at: url),
                  let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let modified = attributes[.modificationDate] as? Date else {
                return nil
            }
            return (modified, plan)
        }
        return platformPlans.max(by: { $0.0 < $1.0 })?.1
    }

    private static func parseTargets(from value: String?) -> [ScreenshotCapturePlanTarget] {
        guard let value, value.isEmpty == false else {
            return []
        }
        return parseTargetStems(
            value.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        )
    }

    private static func parseTargetStems(_ stems: [String]) -> [ScreenshotCapturePlanTarget] {
        stems.compactMap { stem in
            guard let separatorIndex = stem.lastIndex(of: "_") else { return nil }
            let locale = String(stem[..<separatorIndex])
            let slideIndexString = String(stem[stem.index(after: separatorIndex)...])
            guard let slideIndex = Int(slideIndexString) else { return nil }
            return ScreenshotCapturePlanTarget(locale: locale, slideIndex: slideIndex)
        }
    }
}

#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
private extension UIImage {
    func uprightNormalized() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func rotated(by radians: CGFloat) -> UIImage? {
        let rotatedBounds = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral
        let renderer = UIGraphicsImageRenderer(size: rotatedBounds.size)
        return renderer.image { context in
            context.cgContext.translateBy(x: rotatedBounds.width / 2, y: rotatedBounds.height / 2)
            context.cgContext.rotate(by: radians)
            draw(
                in: CGRect(
                    x: -size.width / 2,
                    y: -size.height / 2,
                    width: size.width,
                    height: size.height
                )
            )
        }
    }
}
#endif

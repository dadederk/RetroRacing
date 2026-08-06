//
//  LocalizationReviewWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation

public enum LocalizationReviewWorkflow {
    public static let reviewDirectoryRelativePath = "AppStore/localization/reviews"
    public static let indexRelativePath = "AppStore/localization/README.md"
    public static let expectedInAppStringCount = 401
    public static let expectedReviewItemCount = 556

    public static func audit(
        repositoryRoot: URL,
        locale: String?,
        requireApproval: Bool
    ) throws -> [LocalizationReviewSnapshot] {
        let snapshots = try LocalizationReviewCollector.snapshots(
            repositoryRoot: repositoryRoot,
            selectedLocale: locale
        )
        var errors: [String] = []
        for snapshot in snapshots {
            let empty = snapshot.items.filter {
                $0.identifier.isEmpty == false
                    && $0.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            errors += empty.map {
                "\(snapshot.locale) has an empty \($0.layer) value for \($0.identifier)."
            }
            let appItems = snapshot.items.filter { $0.layer == "In-app" }
            if appItems.count != expectedInAppStringCount {
                errors.append(
                    "\(snapshot.locale) has \(appItems.count) in-app strings; "
                        + "expected \(expectedInAppStringCount)."
                )
            }
            let expectedLayerCounts = [
                "In-app": expectedInAppStringCount,
                "App Store metadata": 6,
                "IAP": 2,
                "Game Center": 126,
                "Screenshots": 20,
                "TestFlight": 1,
            ]
            for (layer, expectedCount) in expectedLayerCounts {
                let actualCount = snapshot.items.filter { $0.layer == layer }.count
                if actualCount != expectedCount {
                    errors.append(
                        "\(snapshot.locale) has \(actualCount) \(layer) review items; expected \(expectedCount)."
                    )
                }
            }
            let validStates = Set(["source", "inherited", "new", "translated", "needs_review"])
            for item in snapshot.items where validStates.contains(item.state) == false {
                errors.append(
                    "\(snapshot.locale) has invalid state \(item.state) for \(item.identifier)."
                )
            }
            for item in appItems where placeholders(in: item.english) != placeholders(in: item.translation) {
                errors.append("\(snapshot.locale) placeholder mismatch for \(item.identifier).")
            }
            errors += limitErrors(for: snapshot)
            if requireApproval {
                errors += approvalErrors(for: snapshot)
            }
        }
        if locale == nil {
            errors += globalCoverageErrors(
                repositoryRoot: repositoryRoot,
                snapshots: snapshots
            )
        }
        errors += retiredSourceErrors(repositoryRoot: repositoryRoot)
        guard errors.isEmpty else { throw LocalizationReviewError.auditFailed(errors) }
        return snapshots
    }

    public static func renderReviews(
        repositoryRoot: URL,
        locale: String?,
        check: Bool
    ) throws -> [LocalizationReviewSnapshot] {
        let snapshots = try LocalizationReviewCollector.snapshots(
            repositoryRoot: repositoryRoot,
            selectedLocale: locale
        )
        var artifacts: [(URL, String)] = snapshots.map { snapshot in
            let url = repositoryRoot
                .appending(path: reviewDirectoryRelativePath)
                .appending(path: "\(snapshot.locale).csv")
            return (url, LocalizationReviewRenderer.csv(for: snapshot))
        }
        if locale == nil {
            artifacts.append((
                repositoryRoot.appending(path: indexRelativePath),
                LocalizationReviewRenderer.index(for: snapshots)
            ))
        }

        if check {
            let stale = artifacts.compactMap { url, expected -> String? in
                guard let current = try? String(contentsOf: url, encoding: .utf8),
                      current == expected else {
                    return relativePath(url, repositoryRoot: repositoryRoot)
                }
                return nil
            }
            guard stale.isEmpty else {
                throw LocalizationReviewError.generatedFilesOutOfDate(stale)
            }
        } else {
            for (url, value) in artifacts {
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try value.write(to: url, atomically: true, encoding: .utf8)
            }
        }
        return snapshots
    }

    private static func approvalErrors(
        for snapshot: LocalizationReviewSnapshot
    ) -> [String] {
        let record = snapshot.record
        guard record.status == .approved else {
            return ["\(snapshot.locale) still needs fluent approval."]
        }
        var errors: [String] = []
        if record.reviewer?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            errors.append("\(snapshot.locale) approval has no reviewer.")
        }
        if record.reviewedAt?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            errors.append("\(snapshot.locale) approval has no review date.")
        }
        if record.approvedContentDigest != snapshot.digest {
            errors.append("\(snapshot.locale) approval digest is missing or stale; current digest is \(snapshot.digest).")
        }
        let pending = snapshot.items.filter {
            $0.layer == "In-app" && $0.state == "needs_review"
        }
        if pending.isEmpty == false {
            errors.append("\(snapshot.locale) still has \(pending.count) in-app strings marked needs_review.")
        }
        return errors
    }

    private static func placeholders(in value: String) -> [String] {
        guard let expression = try? NSRegularExpression(
            pattern: #"%(?:\d+\$)?(?:lld|ld|d|@)"#
        ) else { return [] }
        let range = NSRange(value.startIndex..., in: value)
        return expression.matches(in: value, range: range).compactMap {
            Range($0.range, in: value).map { String(value[$0]) }
        }
    }

    private static func limitErrors(
        for snapshot: LocalizationReviewSnapshot
    ) -> [String] {
        snapshot.items.compactMap { item in
            guard item.limit.hasPrefix("≤ ") else { return nil }
            let renderedLimit = item.limit.dropFirst(2)
                .prefix { $0.isNumber || $0 == "," }
                .filter(\.isNumber)
            guard let limit = Int(renderedLimit) else { return nil }
            let actual = item.limit.contains("UTF-8")
                ? item.translation.lengthOfBytes(using: .utf8)
                : item.translation.count
            guard actual > limit else { return nil }
            return "\(snapshot.locale) \(item.identifier) uses \(actual); limit is \(limit)."
        }
    }

    private static func globalCoverageErrors(
        repositoryRoot: URL,
        snapshots: [LocalizationReviewSnapshot]
    ) -> [String] {
        var errors: [String] = []
        if snapshots.count != 20 {
            errors.append("Review manifest resolves \(snapshots.count) locales; expected 20.")
        }
        let sourceLocales = ScreenshotCapturePlan.captureLocales(
            from: ScreenshotStudioWorkflow.locales
        )
        let derivedCount = ScreenshotCapturePlan.derivedLocaleMap.values
            .reduce(0) { $0 + $1.count }
        if sourceLocales.count != 17 || derivedCount != 3 {
            errors.append(
                "Screenshot capture model has \(sourceLocales.count) source and \(derivedCount) derived locales; expected 17 and 3."
            )
        }
        if ScreenshotCapturePlan.sourceLocale(for: "es-MX") != nil
            || sourceLocales.contains("es-MX") == false {
            errors.append("es-MX must remain an independent screenshot source locale.")
        }

        let expectedRegions = ScreenshotStudioWorkflow.locales.map(bundleRegion(for:))
        let plistURL = repositoryRoot.appending(
            path: "RetroRacing/Config/RetroRacingUniversalInfo.plist"
        )
        if let data = try? Data(contentsOf: plistURL),
           let plist = try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
           ) as? [String: Any],
           let regions = plist["CFBundleLocalizations"] as? [String] {
            for region in expectedRegions where regions.contains(region) == false {
                errors.append("Bundle localisations are missing \(region).")
            }
        } else {
            errors.append("Could not read CFBundleLocalizations for coverage auditing.")
        }

        let projectURL = repositoryRoot.appending(
            path: "RetroRacing/RetroRacing.xcodeproj/project.pbxproj"
        )
        if let project = try? String(contentsOf: projectURL, encoding: .utf8) {
            for region in expectedRegions {
                let quoted = "\t\t\t\t\"\(region)\","
                let unquoted = "\t\t\t\t\(region),"
                if project.contains(quoted) == false && project.contains(unquoted) == false {
                    errors.append("Xcode known regions are missing \(region).")
                }
            }
        } else {
            errors.append("Could not read Xcode known regions for coverage auditing.")
        }
        return errors
    }

    private static func bundleRegion(for locale: String) -> String {
        switch locale {
        case "en-US": "en"
        case "de-DE": "de"
        case "nl-NL": "nl"
        case "fr-FR": "fr"
        case "es-ES": "es"
        default: locale
        }
    }

    private static func retiredSourceErrors(repositoryRoot: URL) -> [String] {
        [
            "Scripts/Resources/eu_localizations.json",
            "Scripts/Resources/asia_latam_localizations.json",
            "Scripts/Resources/turkish_polish_localizations.json",
            "Scripts/Sources/MergeAsiaLatamLocalizations",
            "Scripts/Resources/build_asia_latam_localizations.py",
            "Scripts/Resources/asia_latam_translations_data.py",
        ].compactMap { path in
            FileManager.default.fileExists(atPath: repositoryRoot.appending(path: path).path)
                ? "Retired translation source still exists: \(path)." : nil
        }
    }

    private static func relativePath(_ url: URL, repositoryRoot: URL) -> String {
        let prefix = repositoryRoot.path + "/"
        return url.path.hasPrefix(prefix) ? String(url.path.dropFirst(prefix.count)) : url.path
    }
}

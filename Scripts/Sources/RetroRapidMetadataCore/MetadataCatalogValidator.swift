//
//  MetadataCatalogValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public enum MetadataCatalogValidator {
    private static let parkedScreenshotPlatforms = Set(["appleTv", "appleVision"])

    public static func validationErrors(
        in catalog: MetadataCatalog,
        repositoryRoot: URL? = nil,
        copyDocument: String? = nil,
        validationDocument: String? = nil
    ) -> [String] {
        var errors = validateStatusVocabulary(in: catalog)
            + validateLocaleOrder(in: catalog)
            + catalog.orderedLocales.flatMap {
                validateLocale($0, catalog: catalog)
            }

        if let copyDocument {
            errors += validateDocumentSync(catalog: catalog, copyDocument: copyDocument)
        }
        if let validationDocument {
            errors += validateCountSummaries(
                catalog: catalog,
                validationDocument: validationDocument
            )
        }
        if let repositoryRoot {
            errors += validateScreenshotPlatforms(
                catalog: catalog,
                repositoryRoot: repositoryRoot
            )
        }
        return errors
    }

    public static func counts(
        for locale: LocaleMetadata
    ) -> MetadataFieldCounts {
        MetadataFieldCounts(
            nameCharacters: locale.name.count,
            subtitleCharacters: locale.subtitle.count,
            promotionalTextCharacters: locale.promotionalText.count,
            descriptionCharacters: locale.description.count,
            keywordCharacters: locale.keywords.count,
            keywordBytes: locale.keywords.lengthOfBytes(using: .utf8),
            whatsNewCharacters: locale.whatsNew.count
        )
    }

    public static func countSummaryRow(
        for locale: LocaleMetadata,
        catalog: MetadataCatalog
    ) -> String {
        let counts = counts(for: locale)
        return "| \(locale.code) | "
            + "\(counts.nameCharacters)/\(catalog.limits.nameCharacters) | "
            + "\(counts.subtitleCharacters)/\(catalog.limits.subtitleCharacters) | "
            + "\(counts.promotionalTextCharacters)/\(catalog.limits.promotionalTextCharacters) | "
            + "\(counts.keywordCharacters) chars | "
            + "\(counts.keywordBytes)/\(catalog.limits.keywordBytes) | "
            + "\(counts.descriptionCharacters)/\(catalog.limits.descriptionCharacters) | "
            + "\(counts.whatsNewCharacters)/\(catalog.limits.whatsNewCharacters) |"
    }

    private static func validateStatusVocabulary(
        in catalog: MetadataCatalog
    ) -> [String] {
        let allowedStatuses = Set([
            "LIVE",
            "DRAFT_APPLIED",
            "READY",
            "BLOCKED",
            "PLANNED",
        ])
        let statuses = [catalog.submissionStatus]
            + Array(catalog.fieldStatuses.values)
        let invalidStatuses = Set(statuses).subtracting(allowedStatuses).sorted()

        guard invalidStatuses.isEmpty else {
            return ["Invalid statuses: \(invalidStatuses.joined(separator: ", "))"]
        }
        return []
    }

    private static func validateLocaleOrder(
        in catalog: MetadataCatalog
    ) -> [String] {
        guard Set(catalog.localeOrder) == Set(catalog.locales.keys) else {
            return ["localeOrder and locales must contain the same locale codes"]
        }
        return []
    }

    private static func validateLocale(
        _ locale: LocaleMetadata,
        catalog: MetadataCatalog
    ) -> [String] {
        let counts = counts(for: locale)
        var errors = validateFieldLimits(
            locale: locale,
            counts: counts,
            limits: catalog.limits
        )
        if locale.name.contains("!") {
            errors.append("\(locale.code) name must not contain `!`")
        }
        if !locale.name.hasPrefix("RetroRapid: ") {
            errors.append("\(locale.code) name must start with `RetroRapid: `")
        }
        errors += MetadataKeywordRules.keywordRuleErrors(
            locale: locale.code,
            appName: locale.name,
            subtitle: locale.subtitle,
            keywords: locale.keywords,
            allowedShortKeywords: catalog.allowedShortKeywords
        )
        return errors
    }

    private static func validateFieldLimits(
        locale: LocaleMetadata,
        counts: MetadataFieldCounts,
        limits: MetadataLimits
    ) -> [String] {
        let checks = [
            ("name", counts.nameCharacters, limits.nameCharacters),
            ("subtitle", counts.subtitleCharacters, limits.subtitleCharacters),
            (
                "promotional text",
                counts.promotionalTextCharacters,
                limits.promotionalTextCharacters
            ),
            (
                "description",
                counts.descriptionCharacters,
                limits.descriptionCharacters
            ),
            ("keywords", counts.keywordBytes, limits.keywordBytes),
            (
                "What's New",
                counts.whatsNewCharacters,
                limits.whatsNewCharacters
            ),
        ]

        return checks.compactMap { field, count, limit in
            count > limit
                ? "\(locale.code) \(field) is \(count)/\(limit)"
                : nil
        }
    }

    private static func validateDocumentSync(
        catalog: MetadataCatalog,
        copyDocument: String
    ) -> [String] {
        var errors: [String] = []
        let fields: [(String, (LocaleMetadata) -> String)] = [
            ("name", \.name),
            ("subtitle", \.subtitle),
            ("keywords", \.keywords),
            ("promotional text", \.promotionalText),
            ("description", \.description),
            ("What's New", \.whatsNew),
        ]

        for locale in catalog.orderedLocales {
            for (field, accessor) in fields {
                let value = accessor(locale)
                if !copyDocument.contains(value) {
                    errors.append(
                        "\(locale.code) \(field) is not synchronized with 05-metadata-copy.md"
                    )
                }
            }
        }
        return errors
    }

    private static func validateCountSummaries(
        catalog: MetadataCatalog,
        validationDocument: String
    ) -> [String] {
        catalog.orderedLocales.compactMap { locale in
            let summary = countSummaryRow(for: locale, catalog: catalog)
            return validationDocument.contains(summary)
                ? nil
                : "\(locale.code) counts are not synchronized with 12-validation-results.md"
        }
    }

    private static func validateScreenshotPlatforms(
        catalog: MetadataCatalog,
        repositoryRoot: URL
    ) -> [String] {
        let projectURL = repositoryRoot.appending(
            path: "AppStore/RetroRapid.screenshotstudio/project.plist"
        )
        guard FileManager.default.fileExists(atPath: projectURL.path) else {
            return ["Screenshot Studio project.plist could not be found"]
        }

        do {
            let data = try Data(contentsOf: projectURL)
            var format = PropertyListSerialization.PropertyListFormat.xml
            guard let project = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: &format
            ) as? [String: Any] else {
                return ["Screenshot Studio project.plist has an invalid shape"]
            }

            let projectLocales = Set(project["localizations"] as? [String] ?? [])
            let stagedLocales = Set(catalog.localeOrder)
            if projectLocales != stagedLocales {
                return [
                    "Screenshot Studio project locales differ from staged metadata: "
                        + "project=\(projectLocales.sorted()) "
                        + "staged=\(stagedLocales.sorted())",
                ]
            }

            let projectPlatforms = Set(project["selectedPlatforms"] as? [String] ?? [])
            let stagedPlatforms = Set(
                catalog.screenshotProfiles.keys.map(screenshotStudioPlatformName)
            )
            if projectPlatforms != stagedPlatforms {
                return [
                    "Screenshot Studio selected platforms differ from staged metadata: "
                        + "project=\(projectPlatforms.sorted()) "
                        + "staged=\(stagedPlatforms.sorted())",
                ]
            }

            let parked = projectPlatforms.intersection(parkedScreenshotPlatforms).sorted()
            if !parked.isEmpty {
                return [
                    "Screenshot Studio includes parked platforms: "
                        + parked.joined(separator: ", "),
                ]
            }
            return []
        } catch {
            return ["Screenshot Studio project.plist could not be read: \(error)"]
        }
    }

    private static func screenshotStudioPlatformName(
        for metadataPlatform: String
    ) -> String {
        switch metadataPlatform {
        case "iphone":
            "iPhone"
        case "ipad":
            "iPad"
        default:
            metadataPlatform
        }
    }
}

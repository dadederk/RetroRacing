//
//  MetadataCatalogValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public enum MetadataCatalogValidator {
    public static func validationErrors(
        in catalog: MetadataCatalog
    ) -> [String] {
        validateStatusVocabulary(in: catalog)
            + validateLocaleOrder(in: catalog)
            + catalog.orderedLocales.flatMap {
                validateLocale($0, limits: catalog.limits)
            }
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
        limits: MetadataLimits
    ) -> [String] {
        let counts = counts(for: locale)
        var errors = validateFieldLimits(
            locale: locale,
            counts: counts,
            limits: limits
        )
        errors += validateKeywords(locale)
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

    private static func validateKeywords(
        _ locale: LocaleMetadata
    ) -> [String] {
        let tokens = locale.keywords.split(
            separator: ",",
            omittingEmptySubsequences: false
        ).map(String.init)
        var errors: [String] = []

        if tokens.contains(where: \.isEmpty) {
            errors.append("\(locale.code) keywords contain an empty token")
        }
        if tokens.contains(where: { $0 != $0.trimmingCharacters(in: .whitespaces) }) {
            errors.append("\(locale.code) keywords contain whitespace around commas")
        }

        let duplicates = Dictionary(grouping: tokens, by: { $0 })
            .filter { $0.value.count > 1 }
            .keys
            .sorted()
        if !duplicates.isEmpty {
            errors.append(
                "\(locale.code) keywords contain duplicates: "
                    + duplicates.joined(separator: ", ")
            )
        }
        return errors
    }
}

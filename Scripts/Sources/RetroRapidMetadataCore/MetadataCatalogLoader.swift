//
//  MetadataCatalogLoader.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public enum MetadataCatalogLoader {
    public static func loadValidatedCatalog(from url: URL) throws -> MetadataCatalog {
        let catalog = try loadCatalog(from: url)
        let repositoryRoot = url
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let paths = MetadataRepositoryPaths(repositoryRoot: repositoryRoot)
        let copyDocument = try? String(
            contentsOf: paths.metadataCopyDocument,
            encoding: .utf8
        )
        let validationDocument = try? String(
            contentsOf: paths.validationDocument,
            encoding: .utf8
        )
        let validationErrors = MetadataCatalogValidator.validationErrors(
            in: catalog,
            repositoryRoot: repositoryRoot,
            copyDocument: copyDocument,
            validationDocument: validationDocument
        )

        guard validationErrors.isEmpty else {
            throw MetadataToolError.validationFailed(validationErrors)
        }
        return catalog
    }

    public static func loadCatalog(from url: URL) throws -> MetadataCatalog {
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(MetadataCatalogFile.self, from: data)
        return try file.makeCatalog(sourceURL: url)
    }
}

private struct MetadataCatalogFile: Decodable {
    let schemaVersion: Int
    let release: Release
    let limits: MetadataLimits
    let localeOrder: [String]
    let sharedCopy: [String: SharedCopy]
    let locales: [String: LocaleFile]
    let platformDrafts: [String: PlatformDraftFile]
    let allowedShortKeywords: [String]?
    let screenshotProfiles: [String: Int]?

    func makeCatalog(sourceURL: URL) throws -> MetadataCatalog {
        guard schemaVersion == 1 else {
            throw MetadataToolError.unsupportedSchemaVersion(schemaVersion)
        }

        let resolvedLocales = try localeOrder.reduce(into: [String: LocaleMetadata]()) {
            result,
            code in
            guard let locale = locales[code] else {
                throw MetadataToolError.missingLocale(code)
            }
            result[code] = try locale.resolve(
                code: code,
                sharedCopy: sharedCopy
            )
        }

        let resolvedDrafts = try platformDrafts.mapValues { draft in
            try draft.resolve(localeOrder: localeOrder)
        }

        return MetadataCatalog(
            sourceURL: sourceURL,
            version: release.version,
            lastUpdated: release.lastUpdated,
            submissionStatus: release.submissionStatus,
            fieldStatuses: release.fieldStatuses,
            limits: limits,
            localeOrder: localeOrder,
            locales: resolvedLocales,
            platformDrafts: resolvedDrafts,
            allowedShortKeywords: Set(allowedShortKeywords ?? []),
            screenshotProfiles: screenshotProfiles ?? [:]
        )
    }
}

private struct Release: Decodable {
    let version: String
    let lastUpdated: String
    let submissionStatus: String
    let fieldStatuses: [String: String]
}

private struct SharedCopy: Decodable {
    let promotionalText: String
    let description: String
    let whatsNew: String
}

private struct LocaleFile: Decodable {
    let label: String
    let copyGroup: String?
    let name: String
    let subtitle: String
    let keywords: String
    let promotionalText: String?
    let description: String?
    let whatsNew: String?

    func resolve(
        code: String,
        sharedCopy: [String: SharedCopy]
    ) throws -> LocaleMetadata {
        let shared = copyGroup.flatMap { sharedCopy[$0] }

        return LocaleMetadata(
            code: code,
            label: label,
            name: name,
            subtitle: subtitle,
            keywords: keywords,
            promotionalText: try requiredCopy(
                promotionalText ?? shared?.promotionalText,
                field: "promotionalText",
                locale: code
            ),
            description: try requiredCopy(
                description ?? shared?.description,
                field: "description",
                locale: code
            ),
            whatsNew: try requiredCopy(
                whatsNew ?? shared?.whatsNew,
                field: "whatsNew",
                locale: code
            )
        )
    }

    private func requiredCopy(
        _ value: String?,
        field: String,
        locale: String
    ) throws -> String {
        guard let value, !value.isEmpty else {
            throw MetadataToolError.missingCopy(field: field, locale: locale)
        }
        return value
    }
}

private struct PlatformDraftFile: Decodable {
    let versionId: String
    let localizationIds: [String: String]

    func resolve(localeOrder: [String]) throws -> PlatformDraft {
        let missingLocales = localeOrder.filter { localizationIds[$0] == nil }
        guard missingLocales.isEmpty else {
            throw MetadataToolError.missingLocalizationIDs(missingLocales)
        }

        return PlatformDraft(
            versionID: versionId,
            localizationIDs: localizationIds
        )
    }
}

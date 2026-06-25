//
//  MetadataToolError.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public enum MetadataToolError: LocalizedError {
    case repositoryRootNotFound
    case unsupportedSchemaVersion(Int)
    case missingLocale(String)
    case missingCopy(field: String, locale: String)
    case missingLocalizationIDs([String])
    case validationFailed([String])
    case generatedDocumentsOutOfDate([String])
    case helmNotFound(String)
    case helmFailed(String)
    case invalidArguments(String)

    public var errorDescription: String? {
        switch self {
        case .repositoryRootNotFound:
            "Could not find the RetroRacing repository root."
        case let .unsupportedSchemaVersion(version):
            "Unsupported metadata schema version: \(version)."
        case let .missingLocale(locale):
            "Missing metadata locale: \(locale)."
        case let .missingCopy(field, locale):
            "Missing \(field) copy for \(locale)."
        case let .missingLocalizationIDs(locales):
            "Missing App Store localization IDs: \(locales.joined(separator: ", "))."
        case let .validationFailed(errors):
            "Metadata validation failed:\n\(errors.joined(separator: "\n"))"
        case let .generatedDocumentsOutOfDate(paths):
            "Generated documents are out of date:\n\(paths.joined(separator: "\n"))"
        case let .helmNotFound(path):
            "Helm CLI not found at \(path)."
        case let .helmFailed(message):
            "Helm update failed: \(message)"
        case let .invalidArguments(message):
            message
        }
    }
}

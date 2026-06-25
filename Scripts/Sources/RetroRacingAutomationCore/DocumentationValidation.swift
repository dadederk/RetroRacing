//
//  DocumentationValidation.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import RetroRapidMetadataCore

public struct DocumentationValidationReport: Equatable, Sendable {
    public let checkedFileCount: Int
    public let errors: [String]
    public let warnings: [String]

    public init(
        checkedFileCount: Int,
        errors: [String],
        warnings: [String]
    ) {
        self.checkedFileCount = checkedFileCount
        self.errors = errors
        self.warnings = warnings
    }
}

public enum DocumentationValidator {
    public static func validate(
        repositoryRoot: URL,
        includeMetadata: Bool = true
    ) throws -> DocumentationValidationReport {
        let markdownFiles = try discoverMarkdownFiles(
            repositoryRoot: repositoryRoot
        )
        var errors = markdownFiles.flatMap {
            missingLinkErrors(in: $0, repositoryRoot: repositoryRoot)
        }
        let warnings: [String] = []

        if includeMetadata {
            errors += try metadataValidationErrors(repositoryRoot: repositoryRoot)
        }

        return DocumentationValidationReport(
            checkedFileCount: markdownFiles.count,
            errors: errors,
            warnings: warnings
        )
    }

    public static func missingLinkErrors(
        in file: URL,
        repositoryRoot: URL
    ) -> [String] {
        guard let source = try? String(contentsOf: file, encoding: .utf8) else {
            return ["\(relativePath(file, repositoryRoot: repositoryRoot)): unreadable"]
        }
        let pattern = #"\[[^\]]*\]\(([^)]+)\)"#
        guard let regularExpression = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let range = NSRange(source.startIndex..., in: source)

        return regularExpression.matches(in: source, range: range).compactMap {
            guard let targetRange = Range($0.range(at: 1), in: source) else {
                return nil
            }
            let rawTarget = String(source[targetRange])
            guard let target = localTarget(from: rawTarget) else {
                return nil
            }
            let destination = file.deletingLastPathComponent()
                .appending(path: target)
                .standardizedFileURL
            guard !FileManager.default.fileExists(atPath: destination.path) else {
                return nil
            }
            return "\(relativePath(file, repositoryRoot: repositoryRoot)): "
                + "missing link target \(target)"
        }
    }

    private static func metadataValidationErrors(
        repositoryRoot: URL
    ) throws -> [String] {
        let paths = MetadataRepositoryPaths(repositoryRoot: repositoryRoot)
        let catalog = try MetadataCatalogLoader.loadCatalog(from: paths.defaultCatalog)
        let copyDocument = try String(
            contentsOf: paths.metadataCopyDocument,
            encoding: .utf8
        )
        let validationDocument = try String(
            contentsOf: paths.validationDocument,
            encoding: .utf8
        )
        return MetadataCatalogValidator.validationErrors(
            in: catalog,
            repositoryRoot: repositoryRoot,
            copyDocument: copyDocument,
            validationDocument: validationDocument
        ).map { "App Store metadata: \($0)" }
    }

    private static func discoverMarkdownFiles(
        repositoryRoot: URL
    ) throws -> [URL] {
        let fileManager = FileManager.default
        var files = try fileManager.contentsOfDirectory(
            at: repositoryRoot,
            includingPropertiesForKeys: nil
        ).filter {
            ($0.lastPathComponent == "README.md" || $0.lastPathComponent.hasPrefix("AGENTS"))
                && $0.pathExtension == "md"
        }

        for directory in ["AppStore", "Docs", "Plans", "Requirements"] {
            let root = repositoryRoot.appending(path: directory)
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey]
            ) else {
                continue
            }
            for case let file as URL in enumerator where file.pathExtension == "md" {
                files.append(file)
            }
        }
        return Array(Set(files)).sorted { $0.path < $1.path }
    }

    private static func localTarget(from rawTarget: String) -> String? {
        var target = rawTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        if target.hasPrefix("<"), target.hasSuffix(">") {
            target = String(target.dropFirst().dropLast())
        }
        target = target.components(separatedBy: "#").first ?? ""
        guard !target.isEmpty else { return nil }
        guard !target.hasPrefix("http://"),
              !target.hasPrefix("https://"),
              !target.hasPrefix("mailto:") else {
            return nil
        }
        return target.removingPercentEncoding ?? target
    }

    private static func relativePath(
        _ file: URL,
        repositoryRoot: URL
    ) -> String {
        file.resolvingSymlinksInPath().path.replacingOccurrences(
            of: repositoryRoot.resolvingSymlinksInPath().path + "/",
            with: ""
        )
    }
}

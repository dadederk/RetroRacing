//
//  AppIconProjectConfigurationValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 15/08/2026.
//

import Foundation

enum AppIconProjectConfigurationValidator {
    static func issues(repositoryRoot: URL, alternateNames: [String]) throws -> [String] {
        try projectIssues(
            repositoryRoot: repositoryRoot,
            alternateNames: alternateNames
        ) + sharedCatalogIssues(
            repositoryRoot: repositoryRoot,
            alternateNames: alternateNames
        )
    }

    private static func projectIssues(
        repositoryRoot: URL,
        alternateNames: [String]
    ) throws -> [String] {
        let projectURL = repositoryRoot.appending(
            path: "RetroRacing/RetroRacing.xcodeproj/project.pbxproj"
        )
        let project = try String(contentsOf: projectURL, encoding: .utf8)
        let declarations = alternateIconNameDeclarations(in: project)
        var issues: [String] = []
        if declarations.count != 2 {
            issues.append("Universal Debug and Release must both declare alternate app icon names")
        }
        for name in alternateNames {
            if declarations.count != 2 || declarations.contains(where: { !$0.contains(name) }) {
                issues.append("Universal Debug and Release must both declare \(name)")
            }
        }
        return issues
    }

    private static func alternateIconNameDeclarations(in project: String) -> [Substring] {
        let key = "ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES"
        var declarations: [Substring] = []
        var searchStart = project.startIndex

        while let keyRange = project.range(of: key, range: searchStart..<project.endIndex),
              let terminatorRange = project.range(
                of: ";",
                range: keyRange.upperBound..<project.endIndex
              ) {
            declarations.append(project[keyRange.lowerBound..<terminatorRange.upperBound])
            searchStart = terminatorRange.upperBound
        }
        return declarations
    }

    private static func sharedCatalogIssues(
        repositoryRoot: URL,
        alternateNames: [String]
    ) throws -> [String] {
        let catalogURL = repositoryRoot.appending(
            path: "RetroRacing/RetroRacingShared/AppIcon/AppIconCatalog.swift"
        )
        let catalog = try String(contentsOf: catalogURL, encoding: .utf8)
        return alternateNames.compactMap { name in
            catalog.contains("systemIconName: \"\(name)\"")
                ? nil
                : "Shared app icon catalog is missing permanent system name \(name)"
        }
    }
}

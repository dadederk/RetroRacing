//
//  AlternateAppIconValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 13/08/2026.
//

import Foundation

enum AlternateAppIconValidator {
    static let alternateNames = [
        "RetroRapidPocket",
        "RetroRapidLCD",
        "RetroRapidCartridge",
        "RetroRapidCRT",
        "RetroRapidDisc",
        "RetroRapidPolygon",
        "RetroRapidGameCartridge",
        "RetroRapidVideoGame",
        "RetroRapidGameBox",
    ]

    static func issues(repositoryRoot: URL) throws -> [String] {
        let universalRoot = repositoryRoot.appending(path: "RetroRacing/RetroRacingUniversal")
        let assetsRoot = universalRoot.appending(path: "Assets")
        let catalogRoot = universalRoot.appending(path: "Assets.xcassets")
        var issues = AppIconPackageValidator.issues(
            packageURL: assetsRoot.appending(path: "RetroRapid.icon"),
            expectedName: "RetroRapid"
        )

        for name in alternateNames {
            issues += AppIconPackageValidator.issues(
                packageURL: assetsRoot.appending(path: "\(name).icon"),
                expectedName: name
            )
        }
        issues += AppIconPreviewValidator.issues(catalogRoot: catalogRoot)
        issues += try AppIconProjectConfigurationValidator.issues(
            repositoryRoot: repositoryRoot,
            alternateNames: alternateNames
        )
        issues += try AppIconAssetWorkflow.stalePaths(repositoryRoot: repositoryRoot).map {
            "Generated app icon asset is out of date: \($0)"
        }
        return issues
    }
}

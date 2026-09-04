//
//  AppIconPilotPackageValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 15/08/2026.
//

import Foundation

enum AppIconPilotPackageValidator {
    static func issues(
        packageURL: URL,
        relativeName: String,
        object: [String: Any],
        groups: [[String: Any]],
        pilotID: AppIconPilotID
    ) -> [String] {
        var issues = AppIconAppearanceContractValidator.documentFillIssues(
            object: object,
            relativeName: relativeName
        )
        let appearances = AppIconAppearanceContractValidator.appearanceNames(in: object)
        for appearance in ["dark", "tinted"] where appearances.contains(appearance) == false {
            issues.append(
                "Pilot app icon package is missing \(appearance) appearance annotations: \(relativeName)"
            )
        }

        let layers = groups.flatMap { $0["layers"] as? [[String: Any]] ?? [] }
        let referencedNames = Set(layers.flatMap { layer in
            let base = [layer["image-name"] as? String].compactMap { $0 }
            let specialized = (layer["image-name-specializations"] as? [[String: Any]])?
                .compactMap { $0["value"] as? String } ?? []
            return base + specialized
        })
        for filename in pilotID.layerFilenames where referencedNames.contains(filename) == false {
            issues.append("Pilot app icon package does not reference \(filename): \(relativeName)")
        }
        if AppIconAppearanceContractValidator.containsLegacySpecializationSlot(in: object) {
            issues.append(
                "Pilot app icon package uses unsupported nested specialization slots: \(relativeName)"
            )
        }

        switch pilotID {
        case .pocket, .lcd, .cartridge, .crt, .disc:
            issues += layeredThemeIssues(
                packageURL: packageURL,
                relativeName: relativeName,
                groups: groups,
                layers: layers,
                pilotID: pilotID
            )
        case .retroCartridge, .retroVideoGame:
            issues += flattenedArtworkIssues(
                packageURL: packageURL,
                relativeName: relativeName,
                groups: groups,
                layers: layers,
                groupName: "Approved v4 Artwork",
                assetDescription: "Special Edition",
                darkImageName: "Dark.png"
            )
        case .retroGameBox:
            issues += flattenedArtworkIssues(
                packageURL: packageURL,
                relativeName: relativeName,
                groups: groups,
                layers: layers,
                groupName: "Approved v7 Artwork",
                assetDescription: "Special Edition",
                darkImageName: "Dark.png"
            )
        }
        return issues
    }

    private static func layeredThemeIssues(
        packageURL: URL,
        relativeName: String,
        groups: [[String: Any]],
        layers: [[String: Any]],
        pilotID: AppIconPilotID
    ) -> [String] {
        var issues: [String] = []
        if groups.count < 2 {
            issues.append("Layered theme app icon requires multiple semantic groups: \(relativeName)")
        }
        let expectedGroupNames = pilotID == .crt
            ? ["Accents", "Subject", "World"]
            : ["Subject", "World"]
        let groupNames = groups.compactMap { $0["name"] as? String }
        if groupNames != expectedGroupNames {
            issues.append(
                "Layered theme app icon group order is \(groupNames), expected \(expectedGroupNames): \(relativeName)"
            )
        }
        if FileManager.default.fileExists(
            atPath: packageURL.appending(path: "Assets/Default.png").path
        ) {
            issues.append("Layered theme app icon contains flattened Default.png: \(relativeName)")
        }
        if AppIconValidationSupport.imageHasAlpha(
            at: packageURL.appending(path: "Assets/Car.png")
        ) != true {
            issues.append("Layered theme app icon car must retain transparency: \(relativeName)")
        }

        issues += AppIconAppearanceContractValidator.expectedLayerIssues(
            groupName: "Subject",
            expectedImageNames: ["Car.png", "LaneMarks.svg"],
            groups: groups,
            relativeName: relativeName
        )
        let worldImageNames: [String] = switch pilotID {
        case .disc:
            ["Road.svg", "CircuitTexture.png"]
        case .pocket, .lcd, .cartridge, .crt:
            ["Road.svg"]
        case .retroCartridge, .retroVideoGame, .retroGameBox:
            []
        }
        issues += AppIconAppearanceContractValidator.expectedLayerIssues(
            groupName: "World",
            expectedImageNames: worldImageNames,
            groups: groups,
            relativeName: relativeName
        )
        issues += appearanceIssues(
            defaultName: "LaneMarks.svg",
            darkName: "LaneMarksDark.svg",
            layers: layers,
            relativeName: relativeName
        )
        issues += appearanceIssues(
            defaultName: "Road.svg",
            darkName: "RoadDark.svg",
            layers: layers,
            relativeName: relativeName
        )
        issues += AppIconAppearanceContractValidator.opacityHierarchyIssues(
            foregroundImageName: "LaneMarks.svg",
            backgroundImageName: "Road.svg",
            layers: layers,
            relativeName: relativeName
        )
        if let carLayer = layers.first(where: {
            AppIconAppearanceContractValidator.defaultImageName(in: $0) == "Car.png"
        }), (carLayer["opacity"] as? NSNumber)?.doubleValue != 1 {
            issues.append("Layered theme app icon car must remain fully opaque: \(relativeName)")
        }

        if pilotID == .crt {
            issues += AppIconAppearanceContractValidator.expectedLayerIssues(
                groupName: "Accents",
                expectedImageNames: ["CRTOverlay.png"],
                groups: groups,
                relativeName: relativeName
            )
            issues += appearanceIssues(
                defaultName: "CRTOverlay.png",
                darkName: "CRTOverlayDark.png",
                layers: layers,
                relativeName: relativeName
            )
            for filename in ["CRTOverlay.png", "CRTOverlayDark.png"] {
                let overlayURL = packageURL.appending(path: "Assets/\(filename)")
                if AppIconValidationSupport.imageHasAlpha(at: overlayURL) != true {
                    issues.append("CRT effect layer must retain transparency: \(filename)")
                }
            }
        }
        if pilotID == .disc,
           AppIconValidationSupport.imageHasAlpha(
               at: packageURL.appending(path: "Assets/CircuitTexture.png")
           ) != true {
            issues.append("Disc circuit environment must retain transparency: \(relativeName)")
        }
        return issues
    }

    private static func flattenedArtworkIssues(
        packageURL: URL,
        relativeName: String,
        groups: [[String: Any]],
        layers: [[String: Any]],
        groupName: String,
        assetDescription: String,
        darkImageName: String
    ) -> [String] {
        var issues = AppIconAppearanceContractValidator.expectedLayerIssues(
            groupName: groupName,
            expectedImageNames: ["Default.png"],
            groups: groups,
            relativeName: relativeName
        )
        issues += AppIconAppearanceContractValidator.imageSpecializationIssues(
            defaultImageName: "Default.png",
            darkImageName: darkImageName,
            layers: layers,
            relativeName: relativeName
        )
        for filename in Set(["Default.png", darkImageName]) {
            let artworkURL = packageURL.appending(path: "Assets/\(filename)")
            if AppIconValidationSupport.imageHasAlpha(at: artworkURL) == true {
                issues.append("\(assetDescription) \(filename) must remain opaque: \(relativeName)")
            }
        }
        return issues
    }

    private static func appearanceIssues(
        defaultName: String,
        darkName: String,
        layers: [[String: Any]],
        relativeName: String
    ) -> [String] {
        AppIconAppearanceContractValidator.imageSpecializationIssues(
            defaultImageName: defaultName,
            darkImageName: darkName,
            layers: layers,
            relativeName: relativeName
        ) + AppIconAppearanceContractValidator.opacitySpecializationIssues(
            defaultImageName: defaultName,
            layers: layers,
            relativeName: relativeName
        )
    }
}

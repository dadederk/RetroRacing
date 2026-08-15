//
//  AlternateAppIconValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 13/08/2026.
//

import Foundation
import ImageIO

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
    ]

    static func issues(repositoryRoot: URL) throws -> [String] {
        var issues: [String] = []
        let universalRoot = repositoryRoot.appending(path: "RetroRacing/RetroRacingUniversal")
        let assetsRoot = universalRoot.appending(path: "Assets")
        let catalogRoot = universalRoot.appending(path: "Assets.xcassets")

        issues += iconPackageIssues(
            packageURL: assetsRoot.appending(path: "RetroRapid.icon"),
            expectedName: "RetroRapid"
        )

        for name in alternateNames {
            issues += iconPackageIssues(
                packageURL: assetsRoot.appending(path: "\(name).icon"),
                expectedName: name
            )
        }

        for previewName in previewNames {
            issues += previewIssues(
                imageSetURL: catalogRoot.appending(path: "\(previewName).imageset"),
                previewName: previewName
            )
        }

        issues += try projectConfigurationIssues(repositoryRoot: repositoryRoot)
        issues += try sharedCatalogMappingIssues(repositoryRoot: repositoryRoot)
        issues += try AppIconAssetWorkflow.stalePaths(repositoryRoot: repositoryRoot).map {
            "Generated app icon asset is out of date: \($0)"
        }
        return issues
    }

    private static func iconPackageIssues(packageURL: URL, expectedName: String) -> [String] {
        let relativeName = "\(expectedName).icon"
        let iconJSONURL = packageURL.appending(path: "icon.json")
        guard let data = try? Data(contentsOf: iconJSONURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return ["Alternate app icon package is missing valid JSON: \(relativeName)"]
        }

        guard let groups = object["groups"] as? [[String: Any]], groups.isEmpty == false else {
            return ["Alternate app icon package has no groups: \(relativeName)"]
        }

        var issues: [String] = []
        if groups.count > 4 {
            issues.append("Alternate app icon package exceeds four groups: \(relativeName)")
        }
        if let pilotID = AppIconPilotID(rawValue: expectedName) {
            issues += pilotStructureIssues(
                packageURL: packageURL,
                relativeName: relativeName,
                object: object,
                groups: groups,
                pilotID: pilotID
            )
        }
        for group in groups {
            guard let layers = group["layers"] as? [[String: Any]], layers.isEmpty == false else {
                issues.append("Alternate app icon package has an empty group: \(relativeName)")
                continue
            }
            for layer in layers {
                let imageName = layer["image-name"] as? String
                let specializedNames = (layer["image-name-specializations"] as? [[String: Any]])?
                    .compactMap { $0["value"] as? String } ?? []
                guard imageName != nil || specializedNames.isEmpty == false else {
                    issues.append("Alternate app icon layer has no image-name: \(relativeName)")
                    continue
                }
                for imageName in Set([imageName].compactMap { $0 } + specializedNames) {
                    issues += layerAssetIssues(
                        imageName: imageName,
                        packageURL: packageURL,
                        relativeName: relativeName
                    )
                }
            }
        }
        return issues
    }

    private static func pilotStructureIssues(
        packageURL: URL,
        relativeName: String,
        object: [String: Any],
        groups: [[String: Any]],
        pilotID: AppIconPilotID
    ) -> [String] {
        var issues: [String] = []
        issues += documentFillSpecializationIssues(
            object: object,
            relativeName: relativeName
        )
        let appearances = appearanceNames(in: object)
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
        if containsLegacySpecializationSlot(in: object) {
            issues.append(
                "Pilot app icon package uses unsupported nested specialization slots: \(relativeName)"
            )
        }

        switch pilotID {
        case .pocket, .lcd, .cartridge:
            if groups.count < 2 {
                issues.append("Layered theme app icon requires multiple semantic groups: \(relativeName)")
            }
            let defaultURL = packageURL.appending(path: "Assets/Default.png")
            if FileManager.default.fileExists(atPath: defaultURL.path) {
                issues.append("Layered theme app icon contains flattened Default.png: \(relativeName)")
            }
            let carURL = packageURL.appending(path: "Assets/Car.png")
            if imageHasAlpha(at: carURL) != true {
                issues.append("Layered theme app icon car must retain transparency: \(relativeName)")
            }
            issues += expectedLayerIssues(
                groupName: "Subject",
                expectedImageNames: ["Car.png", "LaneMarks.svg"],
                groups: groups,
                relativeName: relativeName
            )
            issues += expectedLayerIssues(
                groupName: "World",
                expectedImageNames: ["Road.svg"],
                groups: groups,
                relativeName: relativeName
            )
            issues += appearanceImageSpecializationIssues(
                defaultImageName: "LaneMarks.svg",
                darkImageName: "LaneMarksDark.svg",
                layers: layers,
                relativeName: relativeName
            )
            issues += appearanceImageSpecializationIssues(
                defaultImageName: "Road.svg",
                darkImageName: "RoadDark.svg",
                layers: layers,
                relativeName: relativeName
            )
        case .retroCartridge, .retroVideoGame:
            issues += expectedLayerIssues(
                groupName: "Approved v4 Artwork",
                expectedImageNames: ["Default.png"],
                groups: groups,
                relativeName: relativeName
            )
            issues += appearanceImageSpecializationIssues(
                defaultImageName: "Default.png",
                darkImageName: "Dark.png",
                layers: layers,
                relativeName: relativeName
            )
            for filename in ["Default.png", "Dark.png"] {
                let artworkURL = packageURL.appending(path: "Assets/\(filename)")
                if imageHasAlpha(at: artworkURL) == true {
                    issues.append(
                        "Special Edition \(filename) must remain opaque: \(relativeName)"
                    )
                }
            }
        }
        return issues
    }

    private static func documentFillSpecializationIssues(
        object: [String: Any],
        relativeName: String
    ) -> [String] {
        let specializations = object["fill-specializations"] as? [[String: Any]] ?? []
        let hasDefault = specializations.contains { $0["appearance"] == nil }
        let hasDark = specializations.contains { $0["appearance"] as? String == "dark" }
        let hasTinted = specializations.contains { $0["appearance"] as? String == "tinted" }
        return hasDefault && hasDark && hasTinted
            ? []
            : [
                "Pilot app icon must declare Default, Dark, and Tinted document fills: \(relativeName)"
            ]
    }

    private static func expectedLayerIssues(
        groupName: String,
        expectedImageNames: [String],
        groups: [[String: Any]],
        relativeName: String
    ) -> [String] {
        guard let group = groups.first(where: { $0["name"] as? String == groupName }),
              let layers = group["layers"] as? [[String: Any]]
        else {
            return ["Pilot app icon package is missing \(groupName) group: \(relativeName)"]
        }
        let imageNames = layers.compactMap { defaultImageName(in: $0) }
        return imageNames == expectedImageNames
            ? []
            : [
                "Pilot app icon \(groupName) layer order is \(imageNames), expected \(expectedImageNames): \(relativeName)"
            ]
    }

    private static func appearanceImageSpecializationIssues(
        defaultImageName expectedDefaultImageName: String,
        darkImageName: String,
        layers: [[String: Any]],
        relativeName: String
    ) -> [String] {
        guard let layer = layers.first(where: {
            defaultImageName(in: $0) == expectedDefaultImageName
        }) else {
            return [
                "Pilot app icon is missing appearance-aware layer for \(expectedDefaultImageName): \(relativeName)"
            ]
        }
        let defaultContract = imageName(in: layer, appearance: nil) == expectedDefaultImageName
        let darkContract = imageName(in: layer, appearance: "dark") == darkImageName
        let tintedContract = imageName(in: layer, appearance: "tinted") == expectedDefaultImageName
        return defaultContract && darkContract && tintedContract
            ? []
            : [
                "Pilot app icon must map Default, Dark, and Tinted sources through flat image-name specializations: \(relativeName)"
            ]
    }

    private static func defaultImageName(in layer: [String: Any]) -> String? {
        if let imageName = layer["image-name"] as? String {
            return imageName
        }
        return imageName(in: layer, appearance: nil)
    }

    private static func imageName(
        in layer: [String: Any],
        appearance: String? = nil
    ) -> String? {
        let specializations = layer["image-name-specializations"] as? [[String: Any]] ?? []
        let matching = specializations.first { specialization in
            specialization["appearance"] as? String == appearance
        }
        return matching?["value"] as? String
    }

    private static func containsLegacySpecializationSlot(in value: Any) -> Bool {
        if let dictionary = value as? [String: Any] {
            if dictionary["slot"] != nil { return true }
            return dictionary.values.contains(where: containsLegacySpecializationSlot(in:))
        }
        if let array = value as? [Any] {
            return array.contains(where: containsLegacySpecializationSlot(in:))
        }
        return false
    }

    private static func layerAssetIssues(
        imageName: String,
        packageURL: URL,
        relativeName: String
    ) -> [String] {
        let imageURL = packageURL.appending(path: "Assets/\(imageName)")
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            return ["Alternate app icon references missing layer \(imageName): \(relativeName)"]
        }
        if imageURL.pathExtension.lowercased() == "svg" {
            guard hasValidSVGCanvas(at: imageURL) else {
                return [
                    "Alternate app icon SVG \(imageName) must be 1024x1024 with viewBox 0 0 1024 1024: \(relativeName)"
                ]
            }
            return []
        }
        guard let dimensions = imageDimensions(at: imageURL) else {
            return ["Alternate app icon layer is unreadable: \(imageName) in \(relativeName)"]
        }
        return dimensions == (1024, 1024)
            ? []
            : [
                "Alternate app icon layer \(imageName) is \(dimensions.0)x\(dimensions.1), expected 1024x1024: \(relativeName)"
            ]
    }

    private static func appearanceNames(in value: Any) -> Set<String> {
        if let dictionary = value as? [String: Any] {
            var appearances: Set<String> = []
            if let appearance = dictionary["appearance"] as? String {
                appearances.insert(appearance)
            }
            for child in dictionary.values {
                appearances.formUnion(appearanceNames(in: child))
            }
            return appearances
        }
        if let array = value as? [Any] {
            return array.reduce(into: Set<String>()) { result, child in
                result.formUnion(appearanceNames(in: child))
            }
        }
        return []
    }

    private static func hasValidSVGCanvas(at url: URL) -> Bool {
        guard let source = try? String(contentsOf: url, encoding: .utf8) else { return false }
        let normalized = source.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        return normalized.contains("width=\"1024\"")
            && normalized.contains("height=\"1024\"")
            && normalized.contains("viewBox=\"0 0 1024 1024\"")
    }

    private static func previewIssues(imageSetURL: URL, previewName: String) -> [String] {
        let contentsURL = imageSetURL.appending(path: "Contents.json")
        guard let data = try? Data(contentsOf: contentsURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let images = object["images"] as? [[String: Any]]
        else {
            return ["App icon preview asset is missing valid Contents.json: \(previewName)"]
        }

        if adaptivePreviewNames.contains(previewName) {
            return adaptivePreviewIssues(
                imageSetURL: imageSetURL,
                previewName: previewName,
                images: images
            )
        }
        guard let filename = images.compactMap({ $0["filename"] as? String }).first else {
            return ["App icon preview asset has no image: \(previewName)"]
        }
        return previewImageIssues(
            imageURL: imageSetURL.appending(path: filename),
            previewName: previewName
        )
    }

    private static func adaptivePreviewIssues(
        imageSetURL: URL,
        previewName: String,
        images: [[String: Any]]
    ) -> [String] {
        let expectedDefault = "\(previewName).png"
        let expectedDark = "\(previewName)Dark.png"
        guard images.count == 2,
              let defaultEntry = images.first(where: { $0["filename"] as? String == expectedDefault }),
              let darkEntry = images.first(where: { $0["filename"] as? String == expectedDark })
        else {
            return ["Pilot app icon preview must provide one Default and one Dark image: \(previewName)"]
        }
        let appearances = darkEntry["appearances"] as? [[String: Any]] ?? []
        let hasDarkAppearance = appearances.contains { appearance in
            appearance["appearance"] as? String == "luminosity"
                && appearance["value"] as? String == "dark"
        }
        var issues: [String] = []
        if defaultEntry["appearances"] != nil || hasDarkAppearance == false {
            issues.append("Pilot app icon preview has an invalid Dark appearance mapping: \(previewName)")
        }
        for entry in [defaultEntry, darkEntry] {
            if entry["idiom"] as? String != "universal" || entry["scale"] as? String != "1x" {
                issues.append("Pilot app icon preview must use universal 1x sources: \(previewName)")
            }
        }
        issues += previewImageIssues(
            imageURL: imageSetURL.appending(path: expectedDefault),
            previewName: previewName
        )
        issues += previewImageIssues(
            imageURL: imageSetURL.appending(path: expectedDark),
            previewName: "\(previewName) Dark"
        )
        return issues
    }

    private static func previewImageIssues(imageURL: URL, previewName: String) -> [String] {
        guard let dimensions = imageDimensions(at: imageURL) else {
            return ["App icon preview image is missing or unreadable: \(previewName)"]
        }
        return dimensions == (512, 512)
            ? []
            : ["App icon preview is \(dimensions.0)x\(dimensions.1), expected 512x512: \(previewName)"]
    }

    private static func projectConfigurationIssues(repositoryRoot: URL) throws -> [String] {
        let projectURL = repositoryRoot.appending(path: "RetroRacing/RetroRacing.xcodeproj/project.pbxproj")
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

    private static func sharedCatalogMappingIssues(repositoryRoot: URL) throws -> [String] {
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

    private static func imageDimensions(at url: URL) -> (Int, Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else { return nil }
        return (width, height)
    }

    private static func imageHasAlpha(at url: URL) -> Bool? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return nil }
        return properties[kCGImagePropertyHasAlpha] as? Bool
    }

    private static let previewNames = [
        "AppIconPreviewClassic",
        "AppIconPreviewPocket",
        "AppIconPreviewLCD",
        "AppIconPreviewCartridge",
        "AppIconPreviewCRT",
        "AppIconPreviewDisc",
        "AppIconPreviewPolygon",
        "AppIconPreviewRetroCartridge",
        "AppIconPreviewRetroVideoGame",
    ]

    private static let adaptivePreviewNames = Set(
        AppIconPilotID.allCases.map(\.previewAssetName)
    )
}

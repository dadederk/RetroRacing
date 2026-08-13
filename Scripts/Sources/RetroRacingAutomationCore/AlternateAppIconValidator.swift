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
        for group in groups {
            guard let layers = group["layers"] as? [[String: Any]], layers.isEmpty == false else {
                issues.append("Alternate app icon package has an empty group: \(relativeName)")
                continue
            }
            for layer in layers {
                guard let imageName = layer["image-name"] as? String else {
                    issues.append("Alternate app icon layer has no image-name: \(relativeName)")
                    continue
                }
                let imageURL = packageURL.appending(path: "Assets/\(imageName)")
                guard FileManager.default.fileExists(atPath: imageURL.path) else {
                    issues.append("Alternate app icon references missing layer \(imageName): \(relativeName)")
                    continue
                }
                if let dimensions = imageDimensions(at: imageURL), dimensions != (1024, 1024) {
                    issues.append(
                        "Alternate app icon layer \(imageName) is \(dimensions.0)x\(dimensions.1), expected 1024x1024: \(relativeName)"
                    )
                }
            }
        }
        return issues
    }

    private static func previewIssues(imageSetURL: URL, previewName: String) -> [String] {
        let contentsURL = imageSetURL.appending(path: "Contents.json")
        guard let data = try? Data(contentsOf: contentsURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let images = object["images"] as? [[String: Any]],
              let filename = images.compactMap({ $0["filename"] as? String }).first
        else {
            return ["App icon preview asset is missing valid Contents.json: \(previewName)"]
        }
        let imageURL = imageSetURL.appending(path: filename)
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
}

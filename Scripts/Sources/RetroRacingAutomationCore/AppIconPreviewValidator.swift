//
//  AppIconPreviewValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 15/08/2026.
//

import Foundation

enum AppIconPreviewValidator {
    static func issues(catalogRoot: URL) -> [String] {
        previewNames.flatMap { previewName in
            if adaptivePreviewNames.contains(previewName) {
                adaptiveImageSetIssues(
                    imageSetURL: catalogRoot.appending(path: "\(previewName).imageset"),
                    previewName: previewName,
                    defaultFilename: "\(previewName).png",
                    darkFilename: "\(previewName)Dark.png"
                )
            } else {
                imageSetIssues(
                    imageSetURL: catalogRoot.appending(path: "\(previewName).imageset"),
                    previewName: previewName,
                    expectedFilename: "\(previewName).png",
                    requiresOpaqueImage: false
                )
            }
        }
    }

    private static func adaptiveImageSetIssues(
        imageSetURL: URL,
        previewName: String,
        defaultFilename: String,
        darkFilename: String
    ) -> [String] {
        let contentsURL = imageSetURL.appending(path: "Contents.json")
        guard let data = try? Data(contentsOf: contentsURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let images = object["images"] as? [[String: Any]],
              images.count == 2,
              let defaultEntry = images.first(where: {
                  $0["filename"] as? String == defaultFilename
              }),
              let darkEntry = images.first(where: {
                  $0["filename"] as? String == darkFilename
              })
        else {
            return ["Adaptive app icon preview must provide Default and Dark images: \(previewName)"]
        }

        let darkAppearances = darkEntry["appearances"] as? [[String: Any]] ?? []
        let hasDarkAppearance = darkAppearances.contains { appearance in
            appearance["appearance"] as? String == "luminosity"
                && appearance["value"] as? String == "dark"
        }
        var issues: [String] = []
        if defaultEntry["appearances"] != nil || hasDarkAppearance == false {
            issues.append("Adaptive app icon preview has invalid Dark metadata: \(previewName)")
        }
        for (entry, filename) in [(defaultEntry, defaultFilename), (darkEntry, darkFilename)] {
            issues += singleScaleIssues(entry: entry, previewName: previewName)
            issues += imageIssues(
                imageURL: imageSetURL.appending(path: filename),
                previewName: filename
            )
            if AppIconValidationSupport.imageHasAlpha(
                at: imageSetURL.appending(path: filename)
            ) != false {
                issues.append("Pilot app icon preview must be an opaque RGB image: \(filename)")
            }
        }
        return issues
    }

    private static func imageSetIssues(
        imageSetURL: URL,
        previewName: String,
        expectedFilename: String,
        requiresOpaqueImage: Bool
    ) -> [String] {
        let contentsURL = imageSetURL.appending(path: "Contents.json")
        guard let data = try? Data(contentsOf: contentsURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let images = object["images"] as? [[String: Any]]
        else {
            return ["App icon preview asset is missing valid Contents.json: \(previewName)"]
        }

        guard images.count == 1,
              let entry = images.first,
              entry["filename"] as? String == expectedFilename
        else {
            return ["App icon preview asset must provide exactly \(expectedFilename): \(previewName)"]
        }
        var issues = singleScaleIssues(entry: entry, previewName: previewName)
        if entry["appearances"] != nil {
            issues.append("Explicit app icon preview must not declare appearance metadata: \(previewName)")
        }
        issues += imageIssues(
            imageURL: imageSetURL.appending(path: expectedFilename),
            previewName: previewName
        )
        if requiresOpaqueImage,
           AppIconValidationSupport.imageHasAlpha(
               at: imageSetURL.appending(path: expectedFilename)
           ) != false {
            issues.append("Pilot app icon preview must be an opaque RGB image: \(expectedFilename)")
        }
        return issues
    }

    private static func singleScaleIssues(
        entry: [String: Any],
        previewName: String
    ) -> [String] {
        guard entry["idiom"] as? String == "universal", entry["scale"] == nil else {
            return ["App icon preview must use a universal single-scale source: \(previewName)"]
        }
        return []
    }

    private static func imageIssues(imageURL: URL, previewName: String) -> [String] {
        guard let dimensions = AppIconValidationSupport.imageDimensions(at: imageURL) else {
            return ["App icon preview image is missing or unreadable: \(previewName)"]
        }
        return dimensions == (512, 512)
            ? []
            : ["App icon preview is \(dimensions.0)x\(dimensions.1), expected 512x512: \(previewName)"]
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
        "AppIconPreviewRetroGameBox",
    ]

    private static let adaptivePreviewNames = Set(
        AppIconPilotID.allCases.map(\.previewAssetName)
    )
}

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
                explicitAppearanceIssues(
                    catalogRoot: catalogRoot,
                    previewName: previewName
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

    private static func explicitAppearanceIssues(
        catalogRoot: URL,
        previewName: String
    ) -> [String] {
        let darkPreviewName = "\(previewName)Dark"
        return imageSetIssues(
            imageSetURL: catalogRoot.appending(path: "\(previewName).imageset"),
            previewName: previewName,
            expectedFilename: "\(previewName).png",
            requiresOpaqueImage: true
        ) + imageSetIssues(
            imageSetURL: catalogRoot.appending(path: "\(darkPreviewName).imageset"),
            previewName: darkPreviewName,
            expectedFilename: "\(darkPreviewName).png",
            requiresOpaqueImage: true
        )
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
    ]

    private static let adaptivePreviewNames = Set(
        AppIconPilotID.allCases.map(\.previewAssetName)
    )
}

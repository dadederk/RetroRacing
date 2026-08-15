//
//  AppIconValidationSupport.swift
//  RetroRacing
//
//  Created by Dani Devesa on 15/08/2026.
//

import Foundation
import ImageIO

enum AppIconValidationSupport {
    static func layerAssetIssues(
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

    static func imageDimensions(at url: URL) -> (Int, Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else { return nil }
        return (width, height)
    }

    static func imageHasAlpha(at url: URL) -> Bool? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return nil }
        return properties[kCGImagePropertyHasAlpha] as? Bool ?? false
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
}

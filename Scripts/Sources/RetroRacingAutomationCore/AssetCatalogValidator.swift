//
//  AssetCatalogValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation
import ImageIO
import ScriptSupport

enum AssetCatalogValidator {
    static func issues(
        repositoryRoot: URL,
        manifest: RuntimeAssetManifest
    ) throws -> [String] {
        let catalog = repositoryRoot.appending(path: "RetroRacing/RetroRacingShared/Assets.xcassets")
        let manifestPaths = Set(manifest.assets.map(\.path))
        var collectedIssues: [String] = []
        let imageSets = try imageSetPaths(in: catalog)

        collectedIssues += imageSets.subtracting(manifestPaths).sorted().map {
            "Add asset manifest rule for \($0)"
        }
        for rule in manifest.assets {
            let imageSet = catalog.appending(path: rule.path)
            guard FileManager.default.fileExists(atPath: imageSet.path) else {
                collectedIssues.append("Manifest asset is missing: \(rule.path)")
                continue
            }
            collectedIssues += try issues(for: rule, imageSet: imageSet)
        }
        return collectedIssues
    }

    static func issues(for rule: RuntimeAssetRule, imageSet: URL) throws -> [String] {
        let contentsURL = imageSet.appending(path: "Contents.json")
        let contents = try JSONDecoder().decode(
            AssetCatalogContents.self,
            from: Data(contentsOf: contentsURL)
        )
        let allowedIdioms = Set(rule.allowedIdioms)
        var issues: [String] = []
        var populatedIdioms = Set<String>()
        var scalesByIdiom: [String: Set<String>] = [:]
        var referencedFiles = Set<String>()

        for image in contents.images {
            guard let filename = image.filename, filename.isEmpty == false else { continue }
            guard referencedFiles.insert(filename).inserted else {
                issues.append("\(rule.path) references \(filename) more than once")
                continue
            }
            guard allowedIdioms.contains(image.idiom) else {
                issues.append("\(rule.path) ships unexpected idiom '\(image.idiom)'")
                continue
            }

            populatedIdioms.insert(image.idiom)
            if let scale = image.scale {
                scalesByIdiom[image.idiom, default: []].insert(scale)
            }
            issues += imageIssues(
                filename: filename,
                idiom: image.idiom,
                rule: rule,
                imageSet: imageSet
            )
        }

        for idiom in Set(rule.requiredIdioms).subtracting(populatedIdioms).sorted() {
            issues.append("\(rule.path) is missing required idiom '\(idiom)'")
        }
        for (idiom, expectedScales) in rule.scalesByIdiom ?? [:] {
            let actual = scalesByIdiom[idiom, default: []]
            let expected = Set(expectedScales)
            if actual != expected {
                issues.append(
                    "\(rule.path) \(idiom) scales \(actual.sorted()) do not match \(expected.sorted())"
                )
            }
        }
        return issues
    }

    private static func imageIssues(
        filename: String,
        idiom: String,
        rule: RuntimeAssetRule,
        imageSet: URL
    ) -> [String] {
        let fileURL = imageSet.appending(path: filename)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return ["\(rule.path) references missing file \(filename)"]
        }
        guard let dimensions = imageDimensions(at: fileURL) else {
            return ["\(rule.path) could not read image metadata for \(filename)"]
        }
        guard let maximum = rule.maximumLongEdge[idiom] else {
            return ["\(rule.path) has no pixel cap for idiom '\(idiom)'"]
        }
        var issues: [String] = []
        let longEdge = max(dimensions.width, dimensions.height)
        if longEdge > maximum {
            issues.append("\(rule.path) \(filename) long edge \(longEdge) exceeds \(maximum) for \(idiom)")
        }
        if let profile = rule.geometryProfile,
           let expected = expectedDimensions(profile: profile, idiom: idiom),
           dimensions != expected {
            issues.append(
                "\(rule.path) \(filename) is \(dimensions.width)x\(dimensions.height); "
                    + "\(profile.rawValue) [\(idiom)] must be \(expected.width)x\(expected.height)"
            )
        }
        return issues
    }

    private static func expectedDimensions(
        profile: RuntimeAssetGeometryProfile,
        idiom: String
    ) -> (width: Int, height: Int)? {
        switch profile {
        case .helmet, .sixteenBitHelmet, .thirtyTwoBitHelmet, .sixtyFourBitHelmet:
            return idiom == "watch" ? (64, 55) : (256, 222)
        case .sixteenBitPlayerCar, .thirtyTwoBitPlayerCar:
            return dimensionsByIdiom(
                idiom,
                iphoneAndIPad: (768, 536),
                mac: (863, 602),
                tv: (512, 357),
                watch: (256, 179)
            )
        case .sixtyFourBitPlayerCar:
            return idiom == "vision"
                ? (768, 600)
                : dimensionsByIdiom(
                    idiom,
                    iphoneAndIPad: (768, 536),
                    mac: (863, 602),
                    tv: (512, 357),
                    watch: (256, 179)
                )
        case .sixteenBitRivalCar, .thirtyTwoBitRivalCar:
            return dimensionsByIdiom(
                idiom,
                iphoneAndIPad: (768, 496),
                mac: (918, 593),
                tv: (512, 331),
                watch: (256, 165)
            )
        case .sixtyFourBitRivalCar:
            return idiom == "vision"
                ? (768, 600)
                : dimensionsByIdiom(
                    idiom,
                    iphoneAndIPad: (768, 496),
                    mac: (918, 593),
                    tv: (512, 331),
                    watch: (256, 165)
                )
        case .sixteenBitCrash, .thirtyTwoBitCrash, .sixtyFourBitCrash:
            return dimensionsByIdiom(
                idiom,
                iphoneAndIPad: (768, 528),
                mac: (960, 660),
                tv: (512, 352),
                watch: (256, 176)
            )
        }
    }

    private static func dimensionsByIdiom(
        _ idiom: String,
        iphoneAndIPad: (Int, Int),
        mac: (Int, Int),
        tv: (Int, Int),
        watch: (Int, Int)
    ) -> (width: Int, height: Int)? {
        switch idiom {
        case "iphone", "ipad": iphoneAndIPad
        case "mac": mac
        case "tv": tv
        case "watch": watch
        default: nil
        }
    }

    private static func imageDimensions(at url: URL) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else { return nil }
        return (width, height)
    }

    private static func imageSetPaths(in catalog: URL) throws -> Set<String> {
        var paths = Set<String>()
        guard let enumerator = FileManager.default.enumerator(
            at: catalog,
            includingPropertiesForKeys: nil
        ) else { return paths }
        for case let url as URL in enumerator where url.pathExtension == "imageset" {
            paths.insert(FileWork.relativePath(for: url, from: catalog))
        }
        return paths
    }
}

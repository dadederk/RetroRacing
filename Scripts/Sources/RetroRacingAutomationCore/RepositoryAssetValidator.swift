//
//  RepositoryAssetValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import CryptoKit
import CoreGraphics
import Foundation
import ImageIO
import ScriptSupport

enum RepositoryAssetValidator {
    static func issues(repositoryRoot: URL) throws -> [String] {
        var issues = try forbiddenShippingResourceIssues(repositoryRoot: repositoryRoot)
        issues += try archiveMembershipIssues(repositoryRoot: repositoryRoot)
        issues += try discardedArchiveIssues(repositoryRoot: repositoryRoot)
        return issues
    }

    private static func forbiddenShippingResourceIssues(repositoryRoot: URL) throws -> [String] {
        let fileManager = FileManager.default
        var issues: [String] = []
        let resourceRoot = repositoryRoot.appending(path: "RetroRacing/RetroRacingShared/Resources")
        let shippingRoots = [
            repositoryRoot.appending(path: "RetroRacing/RetroRacingShared"),
            repositoryRoot.appending(path: "RetroRacing/RetroRacingUniversal"),
            repositoryRoot.appending(path: "RetroRacing/RetroRacingWatchOS"),
            repositoryRoot.appending(path: "RetroRacing/RetroRacingTvOS"),
            repositoryRoot.appending(path: "RetroRacing/RetroRacingVisionOS"),
        ]

        for root in shippingRoots where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: nil) else {
                continue
            }
            for case let url as URL in enumerator where url.lastPathComponent == ".DS_Store" {
                issues.append("Remove metadata file: \(FileWork.relativePath(for: url, from: repositoryRoot))")
            }
        }

        guard fileManager.fileExists(atPath: resourceRoot.path),
              let enumerator = fileManager.enumerator(at: resourceRoot, includingPropertiesForKeys: nil)
        else { return issues }
        let forbiddenExtensions = Set(["png", "jpg", "jpeg", "gif", "heic", "webp"])
        for case let url as URL in enumerator where forbiddenExtensions.contains(url.pathExtension.lowercased()) {
            issues.append(
                "Move standalone shipping raster into an asset catalog: "
                    + FileWork.relativePath(for: url, from: repositoryRoot)
            )
        }
        return issues
    }

    private static func archiveMembershipIssues(repositoryRoot: URL) throws -> [String] {
        let projectURL = repositoryRoot.appending(path: "RetroRacing/RetroRacing.xcodeproj/project.pbxproj")
        let project = try String(contentsOf: projectURL, encoding: .utf8)
        return ["AssetSources", "DiscardedAssets"].compactMap { archiveName in
            project.contains(archiveName)
                ? "Remove non-target archive '\(archiveName)' from the Xcode project"
                : nil
        }
    }

    private static func discardedArchiveIssues(repositoryRoot: URL) throws -> [String] {
        let archive = repositoryRoot.appending(path: "DiscardedAssets")
        guard FileManager.default.fileExists(atPath: archive.path),
              let enumerator = FileManager.default.enumerator(
                at: archive,
                includingPropertiesForKeys: [.fileSizeKey]
              )
        else { return [] }

        var issues: [String] = []
        var filesByDigest: [String: [(path: String, pixelCount: Int)]] = [:]
        for case let url as URL in enumerator {
            if url.lastPathComponent == ".DS_Store" {
                issues.append("Remove metadata file: \(FileWork.relativePath(for: url, from: repositoryRoot))")
                continue
            }
            guard url.pathExtension.lowercased() == "png" else { continue }
            guard let artwork = decodedArtwork(at: url) else {
                issues.append("Could not decode discarded artwork: \(FileWork.relativePath(for: url, from: repositoryRoot))")
                continue
            }
            filesByDigest[artwork.digest, default: []].append((
                path: FileWork.relativePath(for: url, from: repositoryRoot),
                pixelCount: artwork.pixelCount
            ))
        }
        for files in filesByDigest.values where files.count > 1 {
            let canonical = files.max { lhs, rhs in
                if lhs.pixelCount == rhs.pixelCount { return lhs.path > rhs.path }
                return lhs.pixelCount < rhs.pixelCount
            }
            let paths = files.map(\.path).sorted()
            let canonicalPath = canonical?.path ?? "the largest decoded file"
            issues.append(
                "DiscardedAssets contains decoded artwork duplicates (retain \(canonicalPath)): "
                    + paths.joined(separator: ", ")
            )
        }
        return issues
    }

    private static func decodedArtwork(at url: URL) -> (digest: String, pixelCount: Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        let bytesPerPixel = 4
        let bytesPerRow = image.width * bytesPerPixel
        var pixels = Data(count: bytesPerRow * image.height)
        let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        guard rendered else { return nil }

        let bounds = pixels.withUnsafeBytes { buffer -> (minX: Int, minY: Int, maxX: Int, maxY: Int)? in
            guard let bytes = buffer.bindMemory(to: UInt8.self).baseAddress else { return nil }
            var minX = image.width
            var minY = image.height
            var maxX = -1
            var maxY = -1
            for y in 0..<image.height {
                for x in 0..<image.width where bytes[(y * bytesPerRow) + (x * bytesPerPixel) + 3] > 0 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
            guard maxX >= minX, maxY >= minY else { return nil }
            return (minX, minY, maxX, maxY)
        }
        guard let bounds else {
            let transparentDigest = SHA256.hash(data: Data("transparent".utf8))
                .map { String(format: "%02x", $0) }
                .joined()
            return (transparentDigest, image.width * image.height)
        }

        let trimmedWidth = bounds.maxX - bounds.minX + 1
        let trimmedHeight = bounds.maxY - bounds.minY + 1
        var trimmed = Data("\(trimmedWidth)x\(trimmedHeight)|".utf8)
        pixels.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress else { return }
            for y in bounds.minY...bounds.maxY {
                let offset = (y * bytesPerRow) + (bounds.minX * bytesPerPixel)
                trimmed.append(
                    base.advanced(by: offset).assumingMemoryBound(to: UInt8.self),
                    count: trimmedWidth * bytesPerPixel
                )
            }
        }
        let digest = SHA256.hash(data: trimmed)
            .map { String(format: "%02x", $0) }
            .joined()
        return (digest, image.width * image.height)
    }
}

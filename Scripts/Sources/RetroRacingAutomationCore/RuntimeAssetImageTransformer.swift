//
//  RuntimeAssetImageTransformer.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import CoreGraphics
import Foundation
import ImageIO
import ScriptSupport

public protocol RuntimeAssetProcessRunning {
    @discardableResult
    func run(executable: String, arguments: [String]) throws -> String
}

public struct SystemRuntimeAssetProcessRunner: RuntimeAssetProcessRunning {
    public init() {}

    public func run(executable: String, arguments: [String]) throws -> String {
        try ProcessRunner.run(
            ProcessCommand(executable: executable, arguments: arguments),
            captureOutput: true
        )
    }
}

public struct ImageMagickRuntimeAssetTransformer: RuntimeAssetImageTransforming {
    private let processRunner: any RuntimeAssetProcessRunning

    public init(processRunner: any RuntimeAssetProcessRunning) {
        self.processRunner = processRunner
    }

    public func validateEnvironment() throws {
        let output: String
        do {
            output = try processRunner.run(
                executable: "/usr/bin/env",
                arguments: ["magick", "-version"]
            )
        } catch {
            throw RuntimeAssetOptimizationError.unsupportedImageMagick(
                "ImageMagick is unavailable. Install the pinned 7.1.2-3 release before optimizing assets."
            )
        }
        guard output.contains("ImageMagick 7.1.2-3") else {
            throw RuntimeAssetOptimizationError.unsupportedImageMagick(
                "Expected ImageMagick 7.1.2-3, but `magick -version` reported: \(output)"
            )
        }
    }

    public func render(source: URL, destination: URL, maximumLongEdge: Int) throws {
        try createParentDirectory(for: destination)
        let dimensions = try imageDimensions(at: source)
        if max(dimensions.width, dimensions.height) <= maximumLongEdge {
            try replaceItem(at: destination, withCopyOf: source)
            return
        }
        _ = try processRunner.run(
            executable: "/usr/bin/env",
            arguments: [
                "magick", source.path,
                "-auto-orient",
                "-filter", "Lanczos",
                "-resize", "\(maximumLongEdge)x\(maximumLongEdge)>",
                "-depth", "8",
                destination.path,
            ]
        )
    }

    public func convertTo8Bit(source: URL, destination: URL) throws {
        try createParentDirectory(for: destination)
        let temporary = destination.deletingLastPathComponent().appending(
            path: ".\(destination.lastPathComponent).runtime-asset-temp.png"
        )
        defer { try? FileManager.default.removeItem(at: temporary) }
        _ = try processRunner.run(
            executable: "/usr/bin/env",
            arguments: [
                "magick", source.path,
                "-auto-orient",
                "-depth", "8",
                "PNG32:\(temporary.path)",
            ]
        )
        try replaceItem(at: destination, withCopyOf: temporary)
    }

    public func imagesArePixelEquivalent(_ lhs: URL, _ rhs: URL) throws -> Bool {
        guard let lhsPixels = normalizedPixels(at: lhs),
              let rhsPixels = normalizedPixels(at: rhs) else {
            throw RuntimeAssetOptimizationError.missingImageMetadata(lhs.path)
        }
        return lhsPixels == rhsPixels
    }

    public func imageIs8BitRGBA(_ imageURL: URL) throws -> Bool {
        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw RuntimeAssetOptimizationError.missingImageMetadata(imageURL.path)
        }
        let alphaInfo = image.alphaInfo
        let hasAlpha = alphaInfo == .first
            || alphaInfo == .last
            || alphaInfo == .premultipliedFirst
            || alphaInfo == .premultipliedLast
        return image.bitsPerComponent == 8 && image.bitsPerPixel == 32 && hasAlpha
    }

    private func normalizedPixels(at url: URL) -> NormalizedPixels? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        let bytesPerPixel = 4
        let bytesPerRow = image.width * bytesPerPixel
        var data = Data(count: bytesPerRow * image.height)
        let rendered = data.withUnsafeMutableBytes { buffer -> Bool in
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
        return NormalizedPixels(width: image.width, height: image.height, data: data)
    }

    private func imageDimensions(at url: URL) throws -> (width: Int, height: Int) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else { throw RuntimeAssetOptimizationError.missingImageMetadata(url.path) }
        return (width, height)
    }

    private func createParentDirectory(for destination: URL) throws {
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private func replaceItem(at destination: URL, withCopyOf source: URL) throws {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: source, to: destination)
    }
}

private struct NormalizedPixels: Equatable {
    let width: Int
    let height: Int
    let data: Data
}

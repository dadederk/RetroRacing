//
//  AppIconRasterRenderer.swift
//  RetroRacing
//
//  Created by Dani Devesa on 14/08/2026.
//

import AppKit
import Foundation

enum AppIconRasterRenderer {
    static let canvasSize = 1024

    static func themeCar(
        sourceURL: URL,
        destinationRect: NSRect,
        name: String
    ) throws -> Data {
        let image = try loadImage(at: sourceURL)
        return try renderPNG(name: name) {
            NSGraphicsContext.current?.imageInterpolation = .none
            image.draw(
                in: destinationRect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1,
                respectFlipped: true,
                hints: [.interpolation: NSImageInterpolation.none]
            )
        }
    }

    static func preview(
        canvasHex: String,
        layers: [Data],
        name: String
    ) throws -> Data {
        let fullSize = try renderPNG(name: name) {
            color(hex: canvasHex).setFill()
            NSBezierPath(rect: NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)).fill()
            for layer in layers {
                guard let image = NSImage(data: layer) else { continue }
                image.draw(
                    in: NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize),
                    from: .zero,
                    operation: .sourceOver,
                    fraction: 1,
                    respectFlipped: true,
                    hints: [.interpolation: NSImageInterpolation.high]
                )
            }
        }
        return try resizePNG(fullSize, width: 512, height: 512, name: name)
    }

    static func preview(sourceData: Data, name: String) throws -> Data {
        try resizePNG(sourceData, width: 512, height: 512, name: name)
    }

    private static func loadImage(at url: URL) throws -> NSImage {
        guard let image = NSImage(contentsOf: url) else {
            throw AppIconAssetWorkflowError.imageLoadFailed(url.path)
        }
        return image
    }

    private static func renderPNG(
        name: String,
        draw: () throws -> Void
    ) throws -> Data {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: canvasSize,
            pixelsHigh: canvasSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw AppIconAssetWorkflowError.imageRenderFailed(name)
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)).fill()
        try draw()
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw AppIconAssetWorkflowError.imageRenderFailed(name)
        }
        return data
    }

    private static func resizePNG(
        _ data: Data,
        width: Int,
        height: Int,
        name: String
    ) throws -> Data {
        guard let source = NSImage(data: data),
              let bitmap = NSBitmapImageRep(
                  bitmapDataPlanes: nil,
                  pixelsWide: width,
                  pixelsHigh: height,
                  bitsPerSample: 8,
                  samplesPerPixel: 4,
                  hasAlpha: true,
                  isPlanar: false,
                  colorSpaceName: .deviceRGB,
                  bytesPerRow: 0,
                  bitsPerPixel: 0
              ),
              let context = NSGraphicsContext(bitmapImageRep: bitmap)
        else {
            throw AppIconAssetWorkflowError.imageRenderFailed(name)
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        source.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()
        guard let resized = bitmap.representation(using: .png, properties: [:]) else {
            throw AppIconAssetWorkflowError.imageRenderFailed(name)
        }
        return resized
    }

    private static func color(hex: String) -> NSColor {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard let integer = Int(value, radix: 16), value.count == 6 else { return .black }
        return NSColor(
            srgbRed: CGFloat((integer >> 16) & 0xFF) / 255,
            green: CGFloat((integer >> 8) & 0xFF) / 255,
            blue: CGFloat(integer & 0xFF) / 255,
            alpha: 1
        )
    }
}

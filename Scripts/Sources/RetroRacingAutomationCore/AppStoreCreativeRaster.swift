//
//  AppStoreCreativeRaster.swift
//  RetroRacing
//
//  Created by Dani Devesa on 18/10/2026.
//

import AppKit
import Foundation

enum AppStoreCreativeRaster {
    static func bitmap(size: NSSize) throws -> AppStoreRenderedImage {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw AppStoreCreativeError.renderingFailed
        }
        return AppStoreRenderedImage(bitmap: bitmap)
    }

    static func withGraphics(
        _ bitmap: NSBitmapImageRep,
        drawing: () throws -> Void
    ) throws {
        guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw AppStoreCreativeError.renderingFailed
        }
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        try drawing()
        context.flushGraphics()
    }
}

struct AppStoreRenderedImage {
    let bitmap: NSBitmapImageRep

    func png(opaque: Bool = false) throws -> Data {
        let source = try opaque ? flattenedRGB() : bitmap
        guard let data = source.representation(using: .png, properties: [:]) else {
            throw AppStoreCreativeError.renderingFailed
        }
        return data
    }

    func jpeg() throws -> Data {
        guard let data = bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: 0.91]
        ) else {
            throw AppStoreCreativeError.renderingFailed
        }
        return data
    }

    private func flattenedRGB() throws -> NSBitmapImageRep {
        guard let target = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: bitmap.pixelsWide,
            pixelsHigh: bitmap.pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 3,
            hasAlpha: false,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let sourceBytes = bitmap.bitmapData,
           let targetBytes = target.bitmapData else {
            throw AppStoreCreativeError.renderingFailed
        }
        for y in 0..<bitmap.pixelsHigh {
            let sourceRow = sourceBytes.advanced(by: y * bitmap.bytesPerRow)
            let targetRow = targetBytes.advanced(by: y * target.bytesPerRow)
            for x in 0..<bitmap.pixelsWide {
                let sourcePixel = sourceRow.advanced(by: x * 4)
                let targetPixel = targetRow.advanced(by: x * 3)
                targetPixel[0] = sourcePixel[0]
                targetPixel[1] = sourcePixel[1]
                targetPixel[2] = sourcePixel[2]
            }
        }
        return target
    }
}

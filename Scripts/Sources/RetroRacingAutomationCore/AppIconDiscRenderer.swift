//
//  AppIconDiscRenderer.swift
//  RetroRacing
//
//  Created by Dani Devesa on 15/08/2026.
//

import AppKit
import Foundation

enum AppIconDiscRenderer {
    private static let canvasSize = 1024

    static func circuitEnvironment(
        sourceURL: URL,
        geometry: AppIconRoadGeometry
    ) throws -> Data {
        guard let source = NSImage(contentsOf: sourceURL) else {
            throw AppIconAssetWorkflowError.imageLoadFailed(sourceURL.path)
        }
        guard let bitmap = makeBitmap(),
              let context = NSGraphicsContext(bitmapImageRep: bitmap)
        else {
            throw AppIconAssetWorkflowError.imageRenderFailed("RetroRapidDisc circuit environment")
        }

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = context
        source.draw(in: NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
        context.flushGraphics()
        try clearRoadPixels(in: bitmap, geometry: geometry)

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw AppIconAssetWorkflowError.imageRenderFailed("RetroRapidDisc circuit environment")
        }
        return data
    }

    private static func makeBitmap() -> NSBitmapImageRep? {
        NSBitmapImageRep(
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
        )
    }

    private static func clearRoadPixels(
        in bitmap: NSBitmapImageRep,
        geometry: AppIconRoadGeometry
    ) throws {
        guard let bytes = bitmap.bitmapData else {
            throw AppIconAssetWorkflowError.imageRenderFailed("RetroRapidDisc circuit environment")
        }
        let bytesPerPixel = bitmap.bitsPerPixel / 8
        guard bytesPerPixel >= 4 else {
            throw AppIconAssetWorkflowError.imageRenderFailed("RetroRapidDisc circuit environment")
        }

        for y in 0..<canvasSize {
            let sourceY = Double(y)
            let left = geometry.projectedX(topX: geometry.roadTopLeftX, y: sourceY)
            let right = geometry.projectedX(topX: geometry.roadTopRightX, y: sourceY)
            let firstX = max(0, Int(left.rounded(.down)))
            let lastX = min(canvasSize - 1, Int(right.rounded(.up)))
            guard firstX <= lastX else { continue }

            for x in firstX...lastX {
                let offset = (y * bitmap.bytesPerRow) + (x * bytesPerPixel)
                bytes[offset] = 0
                bytes[offset + 1] = 0
                bytes[offset + 2] = 0
                bytes[offset + 3] = 0
            }
        }
    }
}

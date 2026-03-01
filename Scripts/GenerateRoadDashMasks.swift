//
//  GenerateRoadDashMasks.swift
//  RetroRacing
//
//  Created by Dani Devesa on 01/03/2026.
//

import AppKit
import Foundation

struct MaskDescriptor {
    let imagesetName: String
    let universalFilename: String
    let watchFilename: String
    let tvFilename: String
    let bottomCenterX: CGFloat
    let topCenterX: CGFloat
    let bottomWidth: CGFloat
    let topWidth: CGFloat
}

struct RenderSize {
    let width: Int
    let height: Int
}

let spritesDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("RetroRacing/RetroRacingShared/Assets.xcassets/Sprites")

let descriptors: [MaskDescriptor] = [
    MaskDescriptor(
        imagesetName: "laneInnerMask.imageset",
        universalFilename: "laneInnerMask.png",
        watchFilename: "laneInnerMask 1.png",
        tvFilename: "laneInnerMask 2.png",
        bottomCenterX: 0.22,
        topCenterX: 0.28,
        bottomWidth: 0.08,
        topWidth: 0.06
    ),
    MaskDescriptor(
        imagesetName: "laneOuterMask.imageset",
        universalFilename: "laneOuterMask.png",
        watchFilename: "laneOuterMask 1.png",
        tvFilename: "laneOuterMask 2.png",
        bottomCenterX: 0.12,
        topCenterX: 0.24,
        bottomWidth: 0.10,
        topWidth: 0.07
    )
]

let universalSize = RenderSize(width: 600, height: 360)
let watchSize = RenderSize(width: 300, height: 180)
let tvSize = RenderSize(width: 600, height: 360)

func renderMask(_ descriptor: MaskDescriptor, size: RenderSize) -> Data? {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size.width,
        pixelsHigh: size.height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        return nil
    }

    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        return nil
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    let width = CGFloat(size.width)
    let height = CGFloat(size.height)
    NSColor.clear.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

    let bottomY = height * 0.08
    let topY = height * 0.92
    let bottomHalfWidth = (descriptor.bottomWidth * width) / 2
    let topHalfWidth = (descriptor.topWidth * width) / 2
    let bottomCenterX = descriptor.bottomCenterX * width
    let topCenterX = descriptor.topCenterX * width

    let path = NSBezierPath()
    path.move(to: NSPoint(x: bottomCenterX - bottomHalfWidth, y: bottomY))
    path.line(to: NSPoint(x: bottomCenterX + bottomHalfWidth, y: bottomY))
    path.line(to: NSPoint(x: topCenterX + topHalfWidth, y: topY))
    path.line(to: NSPoint(x: topCenterX - topHalfWidth, y: topY))
    path.close()

    NSColor.white.setFill()
    path.fill()

    NSGraphicsContext.restoreGraphicsState()

    return bitmap.representation(using: .png, properties: [:])
}

func write(data: Data, to fileURL: URL) throws {
    try data.write(to: fileURL, options: .atomic)
}

func contentsJSON(universal: String, watch: String, tv: String) -> String {
    """
    {
      "images" : [
        {
          "filename" : "\(universal)",
          "idiom" : "universal"
        },
        {
          "filename" : "\(watch)",
          "idiom" : "watch"
        },
        {
          "filename" : "\(tv)",
          "idiom" : "tv"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
}

do {
    for descriptor in descriptors {
        let imagesetDirectory = spritesDirectory.appendingPathComponent(descriptor.imagesetName)
        try FileManager.default.createDirectory(
            at: imagesetDirectory,
            withIntermediateDirectories: true
        )

        guard let universalImage = renderMask(descriptor, size: universalSize),
              let watchImage = renderMask(descriptor, size: watchSize),
              let tvImage = renderMask(descriptor, size: tvSize) else {
            throw NSError(domain: "GenerateRoadDashMasks", code: 1)
        }

        try write(
            data: universalImage,
            to: imagesetDirectory.appendingPathComponent(descriptor.universalFilename)
        )
        try write(
            data: watchImage,
            to: imagesetDirectory.appendingPathComponent(descriptor.watchFilename)
        )
        try write(
            data: tvImage,
            to: imagesetDirectory.appendingPathComponent(descriptor.tvFilename)
        )

        let json = contentsJSON(
            universal: descriptor.universalFilename,
            watch: descriptor.watchFilename,
            tv: descriptor.tvFilename
        )
        try json.write(
            to: imagesetDirectory.appendingPathComponent("Contents.json"),
            atomically: true,
            encoding: .utf8
        )
    }

    print("Generated road dash mask assets in \(spritesDirectory.path)")
} catch {
    fputs("Failed to generate road dash mask assets: \(error)\n", stderr)
    exit(1)
}

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
    let isLapMask: Bool
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
let fallbackSpritesDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("RetroRacing/RetroRacingShared/Resources/Sprites")

let descriptors: [MaskDescriptor] = [
    MaskDescriptor(
        imagesetName: "laneInnerMask.imageset",
        universalFilename: "laneInnerMask.png",
        watchFilename: "laneInnerMask 1.png",
        tvFilename: "laneInnerMask 2.png",
        isLapMask: false,
        bottomCenterX: 0.24,
        topCenterX: 0.29,
        bottomWidth: 0.08,
        topWidth: 0.06
    ),
    MaskDescriptor(
        imagesetName: "laneOuterMask.imageset",
        universalFilename: "laneOuterMask.png",
        watchFilename: "laneOuterMask 1.png",
        tvFilename: "laneOuterMask 2.png",
        isLapMask: false,
        bottomCenterX: 0.10,
        topCenterX: 0.29,
        bottomWidth: 0.10,
        topWidth: 0.06
    ),
    MaskDescriptor(
        imagesetName: "lapStripMask.imageset",
        universalFilename: "lapStripMask.png",
        watchFilename: "lapStripMask 1.png",
        tvFilename: "lapStripMask 2.png",
        isLapMask: true,
        bottomCenterX: 0,
        topCenterX: 0,
        bottomWidth: 0,
        topWidth: 0
    )
]

let laneUniversalSize = RenderSize(width: 600, height: 360)
let laneWatchSize = RenderSize(width: 300, height: 180)
let laneTVSize = RenderSize(width: 600, height: 360)

// Lap strip is rendered much wider at runtime, so author the mask with a wide aspect ratio
// to reduce perspective distortion from non-uniform scaling.
let lapUniversalSize = RenderSize(width: 1600, height: 240)
let lapWatchSize = RenderSize(width: 800, height: 120)
let lapTVSize = RenderSize(width: 1600, height: 240)

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

    if descriptor.isLapMask {
        let topY = height * 0.95
        let bottomY = height * 0.05
        let leftTopT: CGFloat = 0.06
        let rightTopT: CGFloat = 0.94
        let path = NSBezierPath()
        path.move(to: NSPoint(x: width * 0.0, y: bottomY))
        path.line(to: NSPoint(x: width * 1.0, y: bottomY))
        path.line(to: NSPoint(x: width * rightTopT, y: topY))
        path.line(to: NSPoint(x: width * leftTopT, y: topY))
        path.close()

        func boundaryX(normalizedBoundary: CGFloat, progress: CGFloat) -> CGFloat {
            let distanceFromCenter = abs((normalizedBoundary * 2) - 1)
            let progressiveConvergence = pow(distanceFromCenter, 1.15)
            let topOffset = leftTopT * progressiveConvergence
            let topBoundary = normalizedBoundary + ((normalizedBoundary < 0.5) ? topOffset : -topOffset)
            let clampedTop = min(max(topBoundary, leftTopT), rightTopT)
            let bottomX = width * normalizedBoundary
            let topX = width * clampedTop
            return bottomX + ((topX - bottomX) * progress)
        }

        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        let rows = 2
        let columns = 12
        let heightSpan = topY - bottomY
        let rowProgresses: [CGFloat] = [0.0, 0.58, 1.0]

        for row in 0..<rows {
            let lowerProgress = rowProgresses[row]
            let upperProgress = rowProgresses[row + 1]
            let lowerY = bottomY + (heightSpan * lowerProgress)
            let upperY = bottomY + (heightSpan * upperProgress)
            for column in 0..<columns where ((row + column) % 2 == 0) {
                let leftBoundary = CGFloat(column) / CGFloat(columns)
                let rightBoundary = CGFloat(column + 1) / CGFloat(columns)
                let cellPath = NSBezierPath()
                cellPath.move(to: NSPoint(x: boundaryX(normalizedBoundary: leftBoundary, progress: lowerProgress), y: lowerY))
                cellPath.line(to: NSPoint(x: boundaryX(normalizedBoundary: rightBoundary, progress: lowerProgress), y: lowerY))
                cellPath.line(to: NSPoint(x: boundaryX(normalizedBoundary: rightBoundary, progress: upperProgress), y: upperY))
                cellPath.line(to: NSPoint(x: boundaryX(normalizedBoundary: leftBoundary, progress: upperProgress), y: upperY))
                cellPath.close()
                NSColor.white.setFill()
                cellPath.fill()
            }
        }
        NSGraphicsContext.restoreGraphicsState()

        path.lineWidth = max(2, height * 0.09)
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        NSColor.white.setStroke()
        path.stroke()
    } else {
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
    }

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
    try FileManager.default.createDirectory(
        at: fallbackSpritesDirectory,
        withIntermediateDirectories: true
    )

    for descriptor in descriptors {
        let imagesetDirectory = spritesDirectory.appendingPathComponent(descriptor.imagesetName)
        try FileManager.default.createDirectory(
            at: imagesetDirectory,
            withIntermediateDirectories: true
        )

        let universalSize = descriptor.isLapMask ? lapUniversalSize : laneUniversalSize
        let watchSize = descriptor.isLapMask ? lapWatchSize : laneWatchSize
        let tvSize = descriptor.isLapMask ? lapTVSize : laneTVSize

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
        try write(
            data: universalImage,
            to: fallbackSpritesDirectory.appendingPathComponent(descriptor.universalFilename)
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

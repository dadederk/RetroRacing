//
//  RoadMaskWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import AppKit
import Foundation
import ScriptSupport

public struct RoadMaskDescriptor: Equatable, Sendable {
    public let imagesetName: String
    public let universalFilename: String
    public let watchFilename: String
    public let televisionFilename: String
    public let isLapMask: Bool
    public let bottomCenterX: CGFloat
    public let topCenterX: CGFloat
    public let bottomWidth: CGFloat
    public let topWidth: CGFloat
}

public struct RoadMaskRenderSize: Equatable, Sendable {
    public let width: Int
    public let height: Int
}

public enum RoadMaskMode: Sendable {
    case write
    case check
}

public enum RoadMaskWorkflow {
    public static let descriptors: [RoadMaskDescriptor] = [
        RoadMaskDescriptor(
            imagesetName: "laneInnerMask.imageset",
            universalFilename: "laneInnerMask.png",
            watchFilename: "laneInnerMask 1.png",
            televisionFilename: "laneInnerMask 2.png",
            isLapMask: false,
            bottomCenterX: 0.24,
            topCenterX: 0.29,
            bottomWidth: 0.08,
            topWidth: 0.06
        ),
        RoadMaskDescriptor(
            imagesetName: "laneOuterMask.imageset",
            universalFilename: "laneOuterMask.png",
            watchFilename: "laneOuterMask 1.png",
            televisionFilename: "laneOuterMask 2.png",
            isLapMask: false,
            bottomCenterX: 0.10,
            topCenterX: 0.29,
            bottomWidth: 0.10,
            topWidth: 0.06
        ),
        RoadMaskDescriptor(
            imagesetName: "lapStripMask.imageset",
            universalFilename: "lapStripMask.png",
            watchFilename: "lapStripMask 1.png",
            televisionFilename: "lapStripMask 2.png",
            isLapMask: true,
            bottomCenterX: 0,
            topCenterX: 0,
            bottomWidth: 0,
            topWidth: 0
        ),
    ]

    public static func run(repositoryRoot: URL, mode: RoadMaskMode) throws {
        let files = try generatedFiles(repositoryRoot: repositoryRoot)

        switch mode {
        case .write:
            try FileWork.writeAtomically(files)
            print("Generated road dash mask assets.")
        case .check:
            let staleFiles = FileWork.staleFiles(
                among: files,
                relativeTo: repositoryRoot
            )
            guard staleFiles.isEmpty else {
                throw RoadMaskError.generatedAssetsOutOfDate(staleFiles)
            }
            print("Road dash mask assets are current.")
        }
    }

    public static func generatedFiles(repositoryRoot: URL) throws -> [GeneratedFile] {
        let spritesDirectory = repositoryRoot.appending(
            path: "RetroRacing/RetroRacingShared/Assets.xcassets/Sprites"
        )
        let fallbackDirectory = repositoryRoot.appending(
            path: "RetroRacing/RetroRacingShared/Resources/Sprites"
        )

        return try descriptors.flatMap { descriptor in
            let imagesetDirectory = spritesDirectory.appending(
                path: descriptor.imagesetName
            )
            let sizes = renderSizes(for: descriptor)
            let universalImage = try renderMask(descriptor, size: sizes.universal)
            let watchImage = try renderMask(descriptor, size: sizes.watch)
            let televisionImage = try renderMask(
                descriptor,
                size: sizes.television
            )

            return [
                GeneratedFile(
                    url: imagesetDirectory.appending(
                        path: descriptor.universalFilename
                    ),
                    data: universalImage
                ),
                GeneratedFile(
                    url: imagesetDirectory.appending(
                        path: descriptor.watchFilename
                    ),
                    data: watchImage
                ),
                GeneratedFile(
                    url: imagesetDirectory.appending(
                        path: descriptor.televisionFilename
                    ),
                    data: televisionImage
                ),
                GeneratedFile(
                    url: fallbackDirectory.appending(
                        path: descriptor.universalFilename
                    ),
                    data: universalImage
                ),
                GeneratedFile(
                    url: imagesetDirectory.appending(path: "Contents.json"),
                    data: contentsJSON(for: descriptor)
                ),
            ]
        }
    }

    public static func renderSizes(
        for descriptor: RoadMaskDescriptor
    ) -> (
        universal: RoadMaskRenderSize,
        watch: RoadMaskRenderSize,
        television: RoadMaskRenderSize
    ) {
        if descriptor.isLapMask {
            return (
                RoadMaskRenderSize(width: 1600, height: 240),
                RoadMaskRenderSize(width: 800, height: 120),
                RoadMaskRenderSize(width: 1600, height: 240)
            )
        }
        return (
            RoadMaskRenderSize(width: 600, height: 360),
            RoadMaskRenderSize(width: 300, height: 180),
            RoadMaskRenderSize(width: 600, height: 360)
        )
    }

    private static func renderMask(
        _ descriptor: RoadMaskDescriptor,
        size: RoadMaskRenderSize
    ) throws -> Data {
        guard
            let bitmap = makeBitmap(size: size),
            let context = NSGraphicsContext(bitmapImageRep: bitmap)
        else {
            throw RoadMaskError.renderFailed(descriptor.imagesetName)
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        clearCanvas(size: size)

        if descriptor.isLapMask {
            drawLapMask(size: size)
        } else {
            drawLaneMask(descriptor, size: size)
        }

        NSGraphicsContext.restoreGraphicsState()
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw RoadMaskError.renderFailed(descriptor.imagesetName)
        }
        return data
    }

    private static func makeBitmap(
        size: RoadMaskRenderSize
    ) -> NSBitmapImageRep? {
        NSBitmapImageRep(
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
        )
    }

    private static func clearCanvas(size: RoadMaskRenderSize) {
        NSColor.clear.setFill()
        NSBezierPath(
            rect: NSRect(
                x: 0,
                y: 0,
                width: CGFloat(size.width),
                height: CGFloat(size.height)
            )
        ).fill()
    }

    private static func drawLaneMask(
        _ descriptor: RoadMaskDescriptor,
        size: RoadMaskRenderSize
    ) {
        let width = CGFloat(size.width)
        let height = CGFloat(size.height)
        let bottomY = height * 0.08
        let topY = height * 0.92
        let bottomHalfWidth = descriptor.bottomWidth * width / 2
        let topHalfWidth = descriptor.topWidth * width / 2
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

    private static func drawLapMask(size: RoadMaskRenderSize) {
        let width = CGFloat(size.width)
        let height = CGFloat(size.height)
        let topY = height * 0.93
        let bottomY = height * 0.07
        let leftBottom: CGFloat = 0.012
        let rightBottom: CGFloat = 0.988
        let leftTop: CGFloat = 0.045
        let rightTop: CGFloat = 0.955
        let path = lapBoundary(
            width: width,
            bottomY: bottomY,
            topY: topY,
            leftBottom: leftBottom,
            rightBottom: rightBottom,
            leftTop: leftTop,
            rightTop: rightTop
        )

        drawCheckers(
            clippedTo: path,
            width: width,
            bottomY: bottomY,
            topY: topY,
            leftTop: leftTop,
            rightTop: rightTop
        )
        path.lineWidth = max(2, height * 0.062)
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        NSColor.white.setStroke()
        path.stroke()
    }

    private static func lapBoundary(
        width: CGFloat,
        bottomY: CGFloat,
        topY: CGFloat,
        leftBottom: CGFloat,
        rightBottom: CGFloat,
        leftTop: CGFloat,
        rightTop: CGFloat
    ) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: width * leftBottom, y: bottomY))
        path.line(to: NSPoint(x: width * rightBottom, y: bottomY))
        path.line(to: NSPoint(x: width * rightTop, y: topY))
        path.line(to: NSPoint(x: width * leftTop, y: topY))
        path.close()
        return path
    }

    private static func drawCheckers(
        clippedTo path: NSBezierPath,
        width: CGFloat,
        bottomY: CGFloat,
        topY: CGFloat,
        leftTop: CGFloat,
        rightTop: CGFloat
    ) {
        NSGraphicsContext.saveGraphicsState()
        path.addClip()

        let rowProgresses: [CGFloat] = [0, 0.58, 1]
        let heightSpan = topY - bottomY

        for row in 0..<2 {
            let lowerProgress = rowProgresses[row]
            let upperProgress = rowProgresses[row + 1]
            let lowerY = bottomY + heightSpan * lowerProgress
            let upperY = bottomY + heightSpan * upperProgress

            for column in 0..<12 where (row + column).isMultiple(of: 2) {
                drawChecker(
                    column: column,
                    width: width,
                    lowerProgress: lowerProgress,
                    upperProgress: upperProgress,
                    lowerY: lowerY,
                    upperY: upperY,
                    leftTop: leftTop,
                    rightTop: rightTop
                )
            }
        }
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func drawChecker(
        column: Int,
        width: CGFloat,
        lowerProgress: CGFloat,
        upperProgress: CGFloat,
        lowerY: CGFloat,
        upperY: CGFloat,
        leftTop: CGFloat,
        rightTop: CGFloat
    ) {
        let leftBoundary = CGFloat(column) / 12
        let rightBoundary = CGFloat(column + 1) / 12
        let path = NSBezierPath()
        path.move(
            to: NSPoint(
                x: checkerBoundaryX(
                    leftBoundary,
                    width: width,
                    progress: lowerProgress,
                    leftTop: leftTop,
                    rightTop: rightTop
                ),
                y: lowerY
            )
        )
        path.line(
            to: NSPoint(
                x: checkerBoundaryX(
                    rightBoundary,
                    width: width,
                    progress: lowerProgress,
                    leftTop: leftTop,
                    rightTop: rightTop
                ),
                y: lowerY
            )
        )
        path.line(
            to: NSPoint(
                x: checkerBoundaryX(
                    rightBoundary,
                    width: width,
                    progress: upperProgress,
                    leftTop: leftTop,
                    rightTop: rightTop
                ),
                y: upperY
            )
        )
        path.line(
            to: NSPoint(
                x: checkerBoundaryX(
                    leftBoundary,
                    width: width,
                    progress: upperProgress,
                    leftTop: leftTop,
                    rightTop: rightTop
                ),
                y: upperY
            )
        )
        path.close()
        NSColor.white.setFill()
        path.fill()
    }

    private static func checkerBoundaryX(
        _ normalizedBoundary: CGFloat,
        width: CGFloat,
        progress: CGFloat,
        leftTop: CGFloat,
        rightTop: CGFloat
    ) -> CGFloat {
        let distanceFromCenter = abs(normalizedBoundary * 2 - 1)
        let progressiveConvergence = pow(distanceFromCenter, 1.15)
        let topOffset = leftTop * progressiveConvergence
        let topBoundary = normalizedBoundary
            + (normalizedBoundary < 0.5 ? topOffset : -topOffset)
        let clampedTop = min(max(topBoundary, leftTop), rightTop)
        let bottomX = width * normalizedBoundary
        let topX = width * clampedTop
        return bottomX + (topX - bottomX) * progress
    }

    private static func contentsJSON(for descriptor: RoadMaskDescriptor) -> Data {
        Data(
            """
            {
              "images" : [
                {
                  "filename" : "\(descriptor.universalFilename)",
                  "idiom" : "universal"
                },
                {
                  "filename" : "\(descriptor.watchFilename)",
                  "idiom" : "watch"
                },
                {
                  "filename" : "\(descriptor.televisionFilename)",
                  "idiom" : "tv"
                }
              ],
              "info" : {
                "author" : "xcode",
                "version" : 1
              }
            }
            """.utf8
        )
    }
}

public enum RoadMaskError: LocalizedError {
    case renderFailed(String)
    case generatedAssetsOutOfDate([String])

    public var errorDescription: String? {
        switch self {
        case let .renderFailed(name):
            "Failed to render \(name)."
        case let .generatedAssetsOutOfDate(paths):
            "Generated road mask assets are out of date:\n"
                + paths.joined(separator: "\n")
        }
    }
}

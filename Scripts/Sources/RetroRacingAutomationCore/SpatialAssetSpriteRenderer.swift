//
//  SpatialAssetSpriteRenderer.swift
//  RetroRacing
//
//  Created by Dani Devesa on 06/08/2026.
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum SpatialAssetSpriteRenderer {
    private struct Vertex {
        let x: Double
        let y: Double
        let depth: Double
    }

    static func render(
        source: String,
        camera: SpatialAssetConfiguration.Camera,
        destination: URL
    ) throws {
        let meshes = try SpatialAssetUSDParser.meshes(in: source)
        let pixelScale = camera.nearestNeighbor ? 4 : 1
        guard camera.pixelWidth.isMultiple(of: pixelScale),
              camera.pixelHeight.isMultiple(of: pixelScale) else {
            throw SpatialAssetError.invalidConfiguration(
                "Nearest-neighbor sprite dimensions must be divisible by \(pixelScale)."
            )
        }
        let width = camera.pixelWidth / pixelScale
        let height = camera.pixelHeight / pixelScale
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        var depths = [Double](repeating: .infinity, count: width * height)
        let basis = try cameraBasis(camera)

        for mesh in meshes {
            draw(
                mesh: mesh,
                basis: basis,
                orthographicScale: camera.orthographicScale,
                width: width,
                height: height,
                pixels: &pixels,
                depths: &depths
            )
        }
        let enlarged = nearestNeighborPixels(
            pixels,
            width: width,
            height: height,
            scale: pixelScale
        )
        try writePNG(
            enlarged,
            width: camera.pixelWidth,
            height: camera.pixelHeight,
            destination: destination
        )
    }

    private struct CameraBasis {
        let position: SIMD3<Double>
        let target: SIMD3<Double>
        let right: SIMD3<Double>
        let up: SIMD3<Double>
        let forward: SIMD3<Double>
    }

    private static func cameraBasis(
        _ camera: SpatialAssetConfiguration.Camera
    ) throws -> CameraBasis {
        let position = SIMD3(camera.position[0], camera.position[1], camera.position[2])
        let target = SIMD3(camera.target[0], camera.target[1], camera.target[2])
        let forward = normalized(target - position)
        let worldUp = SIMD3<Double>(0, 1, 0)
        let right = normalized(cross(forward, worldUp))
        let up = normalized(cross(right, forward))
        guard forward.allFinite, right.allFinite, up.allFinite else {
            throw SpatialAssetError.invalidConfiguration("Camera position and target overlap.")
        }
        return CameraBasis(
            position: position,
            target: target,
            right: right,
            up: up,
            forward: forward
        )
    }

    private static func draw(
        mesh: SpatialAssetMesh,
        basis: CameraBasis,
        orthographicScale: Double,
        width: Int,
        height: Int,
        pixels: inout [UInt8],
        depths: inout [Double]
    ) {
        var offset = 0
        for count in mesh.faceVertexCounts {
            let end = offset + count
            guard count >= 3, end <= mesh.faceVertexIndices.count else {
                offset = end
                continue
            }
            let face = Array(mesh.faceVertexIndices[offset..<end])
            for index in 1..<(face.count - 1) {
                let indices = [face[0], face[index], face[index + 1]]
                guard indices.allSatisfy(mesh.points.indices.contains) else { continue }
                let points = indices.map { mesh.points[$0] }
                let projected = points.map {
                    project(
                        $0,
                        basis: basis,
                        orthographicScale: orthographicScale,
                        width: width,
                        height: height
                    )
                }
                let color = shadedColor(mesh.color, points: points, basis: basis)
                rasterize(
                    projected,
                    color: color,
                    width: width,
                    height: height,
                    pixels: &pixels,
                    depths: &depths
                )
            }
            offset = end
        }
    }

    private static func project(
        _ point: SIMD3<Double>,
        basis: CameraBasis,
        orthographicScale: Double,
        width: Int,
        height: Int
    ) -> Vertex {
        let centered = point - basis.target
        let verticalScale = orthographicScale
        let horizontalScale = verticalScale * Double(width) / Double(height)
        return Vertex(
            x: (dot(centered, basis.right) / horizontalScale + 0.5) * Double(width),
            y: (0.5 - dot(centered, basis.up) / verticalScale) * Double(height),
            depth: dot(point - basis.position, basis.forward)
        )
    }

    private static func shadedColor(
        _ color: SIMD3<Double>,
        points: [SIMD3<Double>],
        basis: CameraBasis
    ) -> SIMD3<UInt8> {
        let normal = normalized(cross(points[1] - points[0], points[2] - points[0]))
        let cameraLight = abs(dot(normal, -basis.forward))
        let overheadLight = max(dot(normal, normalized(SIMD3(-0.35, 0.80, 0.48))), 0)
        let intensity = min(0.54 + cameraLight * 0.34 + overheadLight * 0.20, 1.10)
        return SIMD3(
            channel(color.x * intensity),
            channel(color.y * intensity),
            channel(color.z * intensity)
        )
    }

    private static func rasterize(
        _ vertices: [Vertex],
        color: SIMD3<UInt8>,
        width: Int,
        height: Int,
        pixels: inout [UInt8],
        depths: inout [Double]
    ) {
        let area = edge(vertices[0], vertices[1], vertices[2].x, vertices[2].y)
        guard abs(area) > 0.000_001 else { return }
        let minimumX = max(Int(floor(vertices.map(\.x).min() ?? 0)), 0)
        let maximumX = min(Int(ceil(vertices.map(\.x).max() ?? 0)), width - 1)
        let minimumY = max(Int(floor(vertices.map(\.y).min() ?? 0)), 0)
        let maximumY = min(Int(ceil(vertices.map(\.y).max() ?? 0)), height - 1)
        guard minimumX <= maximumX, minimumY <= maximumY else { return }

        for y in minimumY...maximumY {
            for x in minimumX...maximumX {
                let sampleX = Double(x) + 0.5
                let sampleY = Double(y) + 0.5
                let weights = SIMD3(
                    edge(vertices[1], vertices[2], sampleX, sampleY) / area,
                    edge(vertices[2], vertices[0], sampleX, sampleY) / area,
                    edge(vertices[0], vertices[1], sampleX, sampleY) / area
                )
                guard weights.x >= -0.000_001,
                      weights.y >= -0.000_001,
                      weights.z >= -0.000_001 else { continue }
                let depth = weights.x * vertices[0].depth
                    + weights.y * vertices[1].depth
                    + weights.z * vertices[2].depth
                let pixelIndex = y * width + x
                guard depth < depths[pixelIndex] else { continue }
                depths[pixelIndex] = depth
                let byteIndex = pixelIndex * 4
                pixels[byteIndex] = color.x
                pixels[byteIndex + 1] = color.y
                pixels[byteIndex + 2] = color.z
                pixels[byteIndex + 3] = 255
            }
        }
    }

    private static func nearestNeighborPixels(
        _ source: [UInt8],
        width: Int,
        height: Int,
        scale: Int
    ) -> [UInt8] {
        guard scale > 1 else { return source }
        let destinationWidth = width * scale
        let destinationHeight = height * scale
        var destination = [UInt8](repeating: 0, count: destinationWidth * destinationHeight * 4)
        for y in 0..<destinationHeight {
            for x in 0..<destinationWidth {
                let sourceIndex = ((y / scale) * width + x / scale) * 4
                let destinationIndex = (y * destinationWidth + x) * 4
                destination[destinationIndex..<(destinationIndex + 4)] = source[sourceIndex..<(sourceIndex + 4)]
            }
        }
        return destination
    }

    private static func writePNG(
        _ pixels: [UInt8],
        width: Int,
        height: Int,
        destination: URL
    ) throws {
        let data = Data(pixels)
        guard let provider = CGDataProvider(data: data as CFData),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ), let output = CGImageDestinationCreateWithURL(
                destination as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
              ) else {
            throw SpatialAssetError.invalidOutput(["Could not create the model-derived PNG."])
        }
        CGImageDestinationAddImage(output, image, nil)
        guard CGImageDestinationFinalize(output) else {
            throw SpatialAssetError.invalidOutput(["Could not write the model-derived PNG."])
        }
    }

    private static func edge(_ a: Vertex, _ b: Vertex, _ x: Double, _ y: Double) -> Double {
        (x - a.x) * (b.y - a.y) - (y - a.y) * (b.x - a.x)
    }

    private static func channel(_ value: Double) -> UInt8 {
        UInt8(clamping: Int((min(max(value, 0), 1) * 255).rounded()))
    }

    private static func dot(_ lhs: SIMD3<Double>, _ rhs: SIMD3<Double>) -> Double {
        lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
    }

    private static func cross(_ lhs: SIMD3<Double>, _ rhs: SIMD3<Double>) -> SIMD3<Double> {
        SIMD3(
            lhs.y * rhs.z - lhs.z * rhs.y,
            lhs.z * rhs.x - lhs.x * rhs.z,
            lhs.x * rhs.y - lhs.y * rhs.x
        )
    }

    private static func normalized(_ value: SIMD3<Double>) -> SIMD3<Double> {
        let length = sqrt(dot(value, value))
        guard length > 0 else { return SIMD3(repeating: .nan) }
        return value / length
    }
}

private extension SIMD3 where Scalar == Double {
    var allFinite: Bool { x.isFinite && y.isFinite && z.isFinite }
}

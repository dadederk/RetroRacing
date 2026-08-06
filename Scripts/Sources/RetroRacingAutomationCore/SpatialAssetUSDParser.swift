//
//  SpatialAssetUSDParser.swift
//  RetroRacing
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation

struct SpatialAssetMesh: Sendable {
    let name: String
    let points: [SIMD3<Double>]
    let faceVertexCounts: [Int]
    let faceVertexIndices: [Int]
    let color: SIMD3<Double>
}

enum SpatialAssetUSDParser {
    static func meshes(in source: String) throws -> [SpatialAssetMesh] {
        let materialPairs: [(String, SIMD3<Double>)] = namedBlocks("Material", in: source).compactMap {
            guard let color = vector(
                pattern: #"inputs:diffuseColor\s*=\s*\(([^\)]+)\)"#,
                in: $0.body
            ) else { return nil }
            return ($0.name, color)
        }
        let materials = Dictionary(uniqueKeysWithValues: materialPairs)

        let meshes = namedBlocks("Mesh", in: source).compactMap { block -> SpatialAssetMesh? in
            guard let countsText = capture(
                pattern: #"faceVertexCounts\s*=\s*\[([^\]]+)\]"#,
                in: block.body
            ), let indicesText = capture(
                pattern: #"faceVertexIndices\s*=\s*\[([^\]]+)\]"#,
                in: block.body
            ), let pointsText = capture(
                pattern: #"point3f\[\]\s+points\s*=\s*\[([^\]]+)\]"#,
                in: block.body
            ) else { return nil }

            let values = doubles(in: pointsText)
            guard values.count.isMultiple(of: 3) else { return nil }
            let points = stride(from: 0, to: values.count, by: 3).map {
                SIMD3(values[$0], values[$0 + 1], values[$0 + 2])
            }
            let materialName = capture(
                pattern: #"rel material:binding\s*=\s*<[^>]+/Looks/([^>]+)>"#,
                in: block.body
            )
            let displayColor = vector(
                pattern: #"primvars:displayColor\s*=\s*\[\(([^\)]+)\)\]"#,
                in: block.body
            )
            guard let color = materialName.flatMap({ materials[$0] }) ?? displayColor else {
                return nil
            }
            return SpatialAssetMesh(
                name: block.name,
                points: points,
                faceVertexCounts: integers(in: countsText),
                faceVertexIndices: integers(in: indicesText),
                color: color
            )
        }
        guard meshes.isEmpty == false else {
            throw SpatialAssetError.invalidSource(["Composed USDA contains no renderable meshes."])
        }
        return meshes
    }

    private static func namedBlocks(
        _ definition: String,
        in source: String
    ) -> [(name: String, body: String)] {
        let pattern = #"def\s+"# + NSRegularExpression.escapedPattern(for: definition)
            + #"\s+\"([^\"]+)\""#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(source.startIndex..., in: source)
        return expression.matches(in: source, range: range).compactMap { match in
            guard let nameRange = Range(match.range(at: 1), in: source),
                  let matchRange = Range(match.range, in: source),
                  let openingBrace = source[matchRange.upperBound...].firstIndex(of: "{") else {
                return nil
            }
            var depth = 0
            var cursor = openingBrace
            while cursor < source.endIndex {
                switch source[cursor] {
                case "{": depth += 1
                case "}":
                    depth -= 1
                    if depth == 0 {
                        return (
                            String(source[nameRange]),
                            String(source[openingBrace...cursor])
                        )
                    }
                default: break
                }
                cursor = source.index(after: cursor)
            }
            return nil
        }
    }

    private static func vector(pattern: String, in source: String) -> SIMD3<Double>? {
        guard let text = capture(pattern: pattern, in: source) else { return nil }
        let values = doubles(in: text)
        guard values.count == 3 else { return nil }
        return SIMD3(values[0], values[1], values[2])
    }

    private static func capture(pattern: String, in source: String) -> String? {
        guard let expression = try? NSRegularExpression(
            pattern: pattern,
            options: [.dotMatchesLineSeparators]
        ) else { return nil }
        let range = NSRange(source.startIndex..., in: source)
        guard let match = expression.firstMatch(in: source, range: range),
              let captureRange = Range(match.range(at: 1), in: source) else { return nil }
        return String(source[captureRange])
    }

    private static func integers(in value: String) -> [Int] {
        value.split(separator: ",").compactMap {
            Int($0.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private static func doubles(in value: String) -> [Double] {
        guard let expression = try? NSRegularExpression(pattern: #"-?\d+(?:\.\d+)?"#) else {
            return []
        }
        let range = NSRange(value.startIndex..., in: value)
        return expression.matches(in: value, range: range).compactMap { match in
            guard let range = Range(match.range, in: value) else { return nil }
            return Double(value[range])
        }
    }
}

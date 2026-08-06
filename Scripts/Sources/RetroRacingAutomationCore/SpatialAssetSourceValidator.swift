//
//  SpatialAssetSourceValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation

enum SpatialAssetSourceValidator {
    struct Metrics: Equatable, Sendable {
        let triangles: Int
        let minimumBounds: [Double]
        let maximumBounds: [Double]
    }

    static func validate(
        source: String,
        validation: SpatialAssetConfiguration.ModelValidation
    ) throws -> Metrics {
        var issues = [String]()
        if source.contains("defaultPrim = \"\(validation.rootNode)\"") == false {
            issues.append("Missing default root node \(validation.rootNode).")
        }
        for node in validation.requiredNodes where source.contains("\"\(node)\"") == false {
            issues.append("Missing required node \(node).")
        }
        for node in validation.forbiddenNodes where source.contains("\"\(node)\"") {
            issues.append("Forbidden node \(node) is active in the composed model.")
        }
        for material in validation.requiredMaterials
        where source.contains("def Material \"\(material)\"") == false {
            issues.append("Missing required material \(material).")
        }

        let triangles = triangleCount(in: source)
        if triangles > validation.maximumTriangles {
            issues.append("Triangulated face count \(triangles) exceeds \(validation.maximumTriangles).")
        }
        let bounds = pointBounds(in: source)
        if bounds.minimum != validation.minimumBounds || bounds.maximum != validation.maximumBounds {
            issues.append("Source bounds changed from the approved production manifest.")
        }
        guard issues.isEmpty else { throw SpatialAssetError.invalidSource(issues) }
        return Metrics(
            triangles: triangles,
            minimumBounds: bounds.minimum,
            maximumBounds: bounds.maximum
        )
    }

    private static func triangleCount(in source: String) -> Int {
        matches(pattern: #"faceVertexCounts\s*=\s*\[([^\]]+)\]"#, in: source)
            .flatMap(integers(in:))
            .reduce(0) { $0 + max($1 - 2, 0) }
    }

    private static func pointBounds(in source: String) -> (minimum: [Double], maximum: [Double]) {
        let values = matches(pattern: #"point3f\[\]\s+points\s*=\s*\[([^\]]+)\]"#, in: source)
            .flatMap(doubles(in:))
        var minimum = [Double](repeating: .infinity, count: 3)
        var maximum = [Double](repeating: -.infinity, count: 3)
        for (index, value) in values.enumerated() {
            let axis = index % 3
            minimum[axis] = min(minimum[axis], value)
            maximum[axis] = max(maximum[axis], value)
        }
        return (minimum, maximum)
    }

    private static func matches(pattern: String, in source: String) -> [String] {
        guard let expression = try? NSRegularExpression(
            pattern: pattern,
            options: [.dotMatchesLineSeparators]
        ) else { return [] }
        let range = NSRange(source.startIndex..., in: source)
        return expression.matches(in: source, range: range).compactMap { match in
            guard let range = Range(match.range(at: 1), in: source) else { return nil }
            return String(source[range])
        }
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

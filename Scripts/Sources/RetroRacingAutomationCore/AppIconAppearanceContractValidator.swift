//
//  AppIconAppearanceContractValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 15/08/2026.
//

import Foundation

enum AppIconAppearanceContractValidator {
    static func documentFillIssues(
        object: [String: Any],
        relativeName: String
    ) -> [String] {
        let specializations = object["fill-specializations"] as? [[String: Any]] ?? []
        let hasDefault = specializations.contains { $0["appearance"] == nil }
        let hasDark = specializations.contains { $0["appearance"] as? String == "dark" }
        let hasTinted = specializations.contains { $0["appearance"] as? String == "tinted" }
        return hasDefault && hasDark && hasTinted
            ? []
            : ["Pilot app icon must declare Default, Dark, and Tinted document fills: \(relativeName)"]
    }

    static func expectedLayerIssues(
        groupName: String,
        expectedImageNames: [String],
        groups: [[String: Any]],
        relativeName: String
    ) -> [String] {
        guard let group = groups.first(where: { $0["name"] as? String == groupName }),
              let layers = group["layers"] as? [[String: Any]]
        else {
            return ["Pilot app icon package is missing \(groupName) group: \(relativeName)"]
        }
        let imageNames = layers.compactMap { defaultImageName(in: $0) }
        return imageNames == expectedImageNames
            ? []
            : [
                "Pilot app icon \(groupName) layer order is \(imageNames), expected \(expectedImageNames): \(relativeName)"
            ]
    }

    static func imageSpecializationIssues(
        defaultImageName expectedDefaultImageName: String,
        darkImageName: String,
        layers: [[String: Any]],
        relativeName: String
    ) -> [String] {
        guard let layer = layers.first(where: {
            defaultImageName(in: $0) == expectedDefaultImageName
        }) else {
            return [
                "Pilot app icon is missing appearance-aware layer for \(expectedDefaultImageName): \(relativeName)"
            ]
        }
        let defaultContract = imageName(in: layer, appearance: nil) == expectedDefaultImageName
        let darkContract = imageName(in: layer, appearance: "dark") == darkImageName
        let tintedContract = imageName(in: layer, appearance: "tinted") == expectedDefaultImageName
        return defaultContract && darkContract && tintedContract
            ? []
            : [
                "Pilot app icon must map Default, Dark, and Tinted sources through flat image-name specializations: \(relativeName)"
            ]
    }

    static func opacitySpecializationIssues(
        defaultImageName expectedDefaultImageName: String,
        layers: [[String: Any]],
        relativeName: String
    ) -> [String] {
        guard let layer = layers.first(where: {
            defaultImageName(in: $0) == expectedDefaultImageName
        }) else {
            return [
                "Pilot app icon is missing appearance-aware opacity for \(expectedDefaultImageName): \(relativeName)"
            ]
        }
        let specializations = layer["opacity-specializations"] as? [[String: Any]] ?? []
        let tintedOpacity = opacity(in: specializations, appearance: "tinted")
        let isValid = opacity(in: specializations, appearance: nil) == 1
            && opacity(in: specializations, appearance: "dark") == 1
            && tintedOpacity.map { (0...1).contains($0) } == true
        return isValid
            ? []
            : [
                "Pilot app icon must map Default/Dark opacity 1 and a valid Mono opacity for \(expectedDefaultImageName): \(relativeName)"
            ]
    }

    static func opacityHierarchyIssues(
        foregroundImageName: String,
        backgroundImageName: String,
        layers: [[String: Any]],
        relativeName: String
    ) -> [String] {
        let foregroundOpacity = tintedOpacity(
            imageName: foregroundImageName,
            layers: layers
        )
        let backgroundOpacity = tintedOpacity(
            imageName: backgroundImageName,
            layers: layers
        )
        guard let foregroundOpacity,
              let backgroundOpacity,
              foregroundOpacity > backgroundOpacity
        else {
            return [
                "Pilot app icon Mono hierarchy must keep \(foregroundImageName) stronger than \(backgroundImageName): \(relativeName)"
            ]
        }
        return []
    }

    static func defaultImageName(in layer: [String: Any]) -> String? {
        if let imageName = layer["image-name"] as? String {
            return imageName
        }
        return imageName(in: layer, appearance: nil)
    }

    static func appearanceNames(in value: Any) -> Set<String> {
        if let dictionary = value as? [String: Any] {
            var appearances: Set<String> = []
            if let appearance = dictionary["appearance"] as? String {
                appearances.insert(appearance)
            }
            for child in dictionary.values {
                appearances.formUnion(appearanceNames(in: child))
            }
            return appearances
        }
        if let array = value as? [Any] {
            return array.reduce(into: Set<String>()) { result, child in
                result.formUnion(appearanceNames(in: child))
            }
        }
        return []
    }

    static func containsLegacySpecializationSlot(in value: Any) -> Bool {
        if let dictionary = value as? [String: Any] {
            if dictionary["slot"] != nil { return true }
            return dictionary.values.contains(where: containsLegacySpecializationSlot(in:))
        }
        if let array = value as? [Any] {
            return array.contains(where: containsLegacySpecializationSlot(in:))
        }
        return false
    }

    private static func imageName(
        in layer: [String: Any],
        appearance: String?
    ) -> String? {
        let specializations = layer["image-name-specializations"] as? [[String: Any]] ?? []
        return specializations.first {
            $0["appearance"] as? String == appearance
        }?["value"] as? String
    }

    private static func opacity(
        in specializations: [[String: Any]],
        appearance: String?
    ) -> Double? {
        let matching = specializations.first {
            $0["appearance"] as? String == appearance
        }
        return (matching?["value"] as? NSNumber)?.doubleValue
    }

    private static func tintedOpacity(
        imageName: String,
        layers: [[String: Any]]
    ) -> Double? {
        guard let layer = layers.first(where: { defaultImageName(in: $0) == imageName }) else {
            return nil
        }
        let specializations = layer["opacity-specializations"] as? [[String: Any]] ?? []
        return opacity(in: specializations, appearance: "tinted")
    }
}

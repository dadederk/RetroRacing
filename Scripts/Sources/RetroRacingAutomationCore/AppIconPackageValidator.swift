//
//  AppIconPackageValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 15/08/2026.
//

import Foundation

enum AppIconPackageValidator {
    static func issues(packageURL: URL, expectedName: String) -> [String] {
        let relativeName = "\(expectedName).icon"
        let iconJSONURL = packageURL.appending(path: "icon.json")
        guard let data = try? Data(contentsOf: iconJSONURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return ["Alternate app icon package is missing valid JSON: \(relativeName)"]
        }

        guard let groups = object["groups"] as? [[String: Any]], groups.isEmpty == false else {
            return ["Alternate app icon package has no groups: \(relativeName)"]
        }

        var issues: [String] = []
        if groups.count > 4 {
            issues.append("Alternate app icon package exceeds four groups: \(relativeName)")
        }
        if let pilotID = AppIconPilotID(rawValue: expectedName) {
            issues += AppIconPilotPackageValidator.issues(
                packageURL: packageURL,
                relativeName: relativeName,
                object: object,
                groups: groups,
                pilotID: pilotID
            )
        }
        issues += layerIssues(
            groups: groups,
            packageURL: packageURL,
            relativeName: relativeName
        )
        return issues
    }

    private static func layerIssues(
        groups: [[String: Any]],
        packageURL: URL,
        relativeName: String
    ) -> [String] {
        var issues: [String] = []
        for group in groups {
            guard let layers = group["layers"] as? [[String: Any]], layers.isEmpty == false else {
                issues.append("Alternate app icon package has an empty group: \(relativeName)")
                continue
            }
            for layer in layers {
                let imageName = layer["image-name"] as? String
                let specializedNames = (layer["image-name-specializations"] as? [[String: Any]])?
                    .compactMap { $0["value"] as? String } ?? []
                guard imageName != nil || specializedNames.isEmpty == false else {
                    issues.append("Alternate app icon layer has no image-name: \(relativeName)")
                    continue
                }
                for imageName in Set([imageName].compactMap { $0 } + specializedNames) {
                    issues += AppIconValidationSupport.layerAssetIssues(
                        imageName: imageName,
                        packageURL: packageURL,
                        relativeName: relativeName
                    )
                }
            }
        }
        return issues
    }
}

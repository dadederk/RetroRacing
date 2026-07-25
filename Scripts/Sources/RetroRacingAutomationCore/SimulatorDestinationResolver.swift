//
//  SimulatorDestinationResolver.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import ScriptSupport

public enum SimulatorDestinationResolver {
    public struct Candidate: Equatable, Sendable {
        public let name: String
        public let osVersion: String
        public let udid: String
        public let platformFamily: PlatformFamily

        public enum PlatformFamily: Equatable, Sendable {
            case iOS
            case watchOS
        }

        public var destination: String {
            switch platformFamily {
            case .iOS:
                return "platform=iOS Simulator,id=\(udid)"
            case .watchOS:
                return "platform=watchOS Simulator,id=\(udid)"
            }
        }
    }

    public static func normalizeDestinationIfNeeded(
        _ destination: String,
        platform: String,
        devicesJSON: Data
    ) throws -> String {
        if SimulatorStatusBarWorkflow.simulatorUDID(from: destination) != nil {
            return destination
        }
        guard let simulatorName = SimulatorStatusBarWorkflow.simulatorName(from: destination) else {
            return destination
        }
        let osVersion = SimulatorStatusBarWorkflow.simulatorOSVersion(from: destination)
        guard let resolved = try resolveSimulator(
            named: simulatorName,
            osVersion: osVersion,
            platformFamily: platformFamily(for: platform),
            devicesJSON: devicesJSON
        ) else {
            return destination
        }
        return resolved.destination
    }

    public static func resolveSimulator(
        named simulatorName: String,
        osVersion requestedOSVersion: String? = nil,
        platformFamily: Candidate.PlatformFamily = .iOS,
        devicesJSON: Data
    ) throws -> Candidate? {
        let payload = try JSONDecoder().decode(SimctlDevicesResponse.self, from: devicesJSON)
        var candidates: [Candidate] = []

        for (runtimeIdentifier, devices) in payload.devices {
            guard runtimeMatches(platformFamily, runtimeIdentifier: runtimeIdentifier) else {
                continue
            }
            guard let runtimeOSVersion = osVersion(fromRuntimeIdentifier: runtimeIdentifier) else {
                continue
            }
            if let requestedOSVersion, runtimeOSVersion != requestedOSVersion {
                continue
            }
            for device in devices where device.isAvailable != false && device.name == simulatorName {
                candidates.append(
                    Candidate(
                        name: device.name,
                        osVersion: runtimeOSVersion,
                        udid: device.udid,
                        platformFamily: platformFamily
                    )
                )
            }
        }

        guard candidates.isEmpty == false else { return nil }

        return candidates.sorted { lhs, rhs in
            compareOSVersions(lhs.osVersion, rhs.osVersion) == .orderedDescending
        }.first
    }

    public static func preferredSimulatorNames(for platform: String) -> [String] {
        switch AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform) {
        case "ipad":
            return [
                "iPad Pro 13-inch (M5)",
                "iPad Pro 13-inch (M4)",
                "iPad Pro 11-inch (M5)",
            ]
        case "appleWatch":
            return ["Apple Watch Ultra 3 (49mm)"]
        default:
            return ["iPhone 17 Pro Max"]
        }
    }

    public static func platformFamily(for platform: String) -> Candidate.PlatformFamily {
        switch AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform) {
        case "appleWatch":
            return .watchOS
        default:
            return .iOS
        }
    }

    public static func resolveDefaultDestination(
        for platform: String,
        devicesJSON: Data
    ) throws -> String {
        let preferredNames = preferredSimulatorNames(for: platform)
        let family = platformFamily(for: platform)
        guard let candidate = try resolveBestCandidate(
            preferredNames: preferredNames,
            platformFamily: family,
            devicesJSON: devicesJSON
        ) else {
            throw AppStoreScreenshotCaptureError.simulatorNotFound(
                preferredNames.joined(separator: ", ")
            )
        }
        return candidate.destination
    }

    public static func resolveBestCandidate(
        preferredNames: [String],
        platformFamily: Candidate.PlatformFamily = .iOS,
        devicesJSON: Data
    ) throws -> Candidate? {
        let payload = try JSONDecoder().decode(SimctlDevicesResponse.self, from: devicesJSON)
        var candidates: [Candidate] = []

        for (runtimeIdentifier, devices) in payload.devices {
            guard runtimeMatches(platformFamily, runtimeIdentifier: runtimeIdentifier) else {
                continue
            }
            guard let osVersion = osVersion(fromRuntimeIdentifier: runtimeIdentifier) else {
                continue
            }
            for device in devices where device.isAvailable != false {
                guard preferredNames.contains(device.name) else { continue }
                candidates.append(
                    Candidate(
                        name: device.name,
                        osVersion: osVersion,
                        udid: device.udid,
                        platformFamily: platformFamily
                    )
                )
            }
        }

        guard candidates.isEmpty == false else { return nil }

        return candidates.sorted { lhs, rhs in
            if lhs.name != rhs.name {
                let lhsIndex = preferredNames.firstIndex(of: lhs.name) ?? preferredNames.count
                let rhsIndex = preferredNames.firstIndex(of: rhs.name) ?? preferredNames.count
                if lhsIndex != rhsIndex {
                    return lhsIndex < rhsIndex
                }
                return lhs.name < rhs.name
            }
            return compareOSVersions(lhs.osVersion, rhs.osVersion) == .orderedDescending
        }.first
    }

    public static func loadAvailableDevicesJSON(
        run: (ProcessCommand) throws -> String = { try ProcessRunner.run($0, captureOutput: true) }
    ) throws -> Data {
        let output = try run(
            ProcessCommand(
                executable: "/usr/bin/xcrun",
                arguments: ["simctl", "list", "devices", "available", "-j"]
            )
        )
        guard let data = output.data(using: .utf8) else {
            throw AppStoreScreenshotCaptureError.simulatorLookupFailed(
                "simctl list output was not UTF-8."
            )
        }
        return data
    }

    static func runtimeMatches(
        _ platformFamily: Candidate.PlatformFamily,
        runtimeIdentifier: String
    ) -> Bool {
        switch platformFamily {
        case .iOS:
            return runtimeIdentifier.contains("SimRuntime.iOS")
        case .watchOS:
            return runtimeIdentifier.contains("SimRuntime.watchOS")
        }
    }

    static func osVersion(fromRuntimeIdentifier identifier: String) -> String? {
        guard let suffix = identifier.split(separator: ".").last else { return nil }
        let components = suffix.split(separator: "-")
        guard components.count >= 3,
              let major = Int(components[components.count - 2]),
              let minor = Int(components[components.count - 1]) else {
            return nil
        }
        return "\(major).\(minor)"
    }

    static func compareOSVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsParts = lhs.split(separator: ".").compactMap { Int($0) }
        let rhsParts = rhs.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(lhsParts.count, rhsParts.count)
        for index in 0..<maxCount {
            let left = index < lhsParts.count ? lhsParts[index] : 0
            let right = index < rhsParts.count ? rhsParts[index] : 0
            if left < right { return .orderedAscending }
            if left > right { return .orderedDescending }
        }
        return .orderedSame
    }
}

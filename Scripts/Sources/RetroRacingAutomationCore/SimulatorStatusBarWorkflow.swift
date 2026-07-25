//
//  SimulatorStatusBarWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import ScriptSupport

public enum SimulatorStatusBarWorkflow {
    public static let marketingClockTime = "9:41"
    /// Calendar date shown on iPad status bar captures. 27 January 2027 is a Wednesday.
    public static let marketingStatusBarYear = 2027
    public static let marketingStatusBarMonth = 1
    public static let marketingStatusBarDay = 27
    public static let marketingStatusBarHour = 9
    public static let marketingStatusBarMinute = 41

    /// ISO datetime for `simctl status_bar override --time`.
    /// simctl requires fractional seconds and a timezone offset (plain `2027-01-27T09:41:00` is rejected).
    /// The offset must match the marketing calendar date (27 January 2027), not the capture host's current
    /// DST offset. simctl applies the date's seasonal offset when rendering; e.g. sending `+02:00` while
    /// the date is in January displays `08:41` on iPad instead of `09:41`.
    public static var marketingStatusBarDateTime: String {
        marketingStatusBarDateTime(for: .current)
    }

    public static func marketingStatusBarDateTime(
        for timeZone: TimeZone
    ) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let marketingDate = calendar.date(
            from: DateComponents(
                year: marketingStatusBarYear,
                month: marketingStatusBarMonth,
                day: marketingStatusBarDay,
                hour: marketingStatusBarHour,
                minute: marketingStatusBarMinute
            )
        ) ?? Date()
        let offset = iso8601OffsetSuffix(for: timeZone, referenceDate: marketingDate)
        return String(
            format: "%04d-%02d-%02dT%02d:%02d:00.000%@",
            marketingStatusBarYear,
            marketingStatusBarMonth,
            marketingStatusBarDay,
            marketingStatusBarHour,
            marketingStatusBarMinute,
            offset
        )
    }

    static func iso8601OffsetSuffix(for timeZone: TimeZone, referenceDate: Date) -> String {
        let offsetSeconds = timeZone.secondsFromGMT(for: referenceDate)
        let hours = offsetSeconds / 3600
        let minutes = (abs(offsetSeconds) % 3600) / 60
        let sign = offsetSeconds >= 0 ? "+" : "-"
        return String(format: "%@%02d:%02d", sign, abs(hours), minutes)
    }

    public static func shouldApplyOverride(platform: String, enabled: Bool) -> Bool {
        let normalized = AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform)
        return enabled && normalized != "mac" && normalized != "appleWatch"
    }

    public static func simulatorName(from destination: String) -> String? {
        for component in destination.split(separator: ",") {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("name=") {
                let name = String(trimmed.dropFirst("name=".count))
                return name.isEmpty ? nil : name
            }
        }
        return nil
    }

    public static func simulatorUDID(from destination: String) -> String? {
        for component in destination.split(separator: ",") {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("id=") {
                let udid = String(trimmed.dropFirst("id=".count))
                return udid.isEmpty ? nil : udid
            }
        }
        return nil
    }

    public static func usesWatchSimulatorDestination(_ destination: String) -> Bool {
        destination.localizedCaseInsensitiveContains("watchOS Simulator")
            || destination.localizedCaseInsensitiveContains("watchsimulator")
    }

    public static func simulatorOSVersion(from destination: String) -> String? {
        for component in destination.split(separator: ",") {
            let trimmed = component.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("OS=") {
                let version = String(trimmed.dropFirst("OS=".count))
                return version.isEmpty ? nil : version
            }
        }
        return nil
    }

    public static func usesIOSSimulatorDestination(_ destination: String) -> Bool {
        destination.localizedCaseInsensitiveContains("iOS Simulator")
            || destination.localizedCaseInsensitiveContains("iphonesimulator")
    }

    public static func marketingOverrideCommand(simulatorReference: String) -> ProcessCommand {
        ProcessCommand(
            executable: "/usr/bin/xcrun",
            arguments: [
                "simctl", "status_bar", simulatorReference, "override",
                "--time", marketingStatusBarDateTime,
                "--batteryState", "charged",
                "--batteryLevel", "100",
                "--cellularMode", "active",
                "--cellularBars", "4",
                "--wifiMode", "active",
                "--wifiBars", "3",
            ]
        )
    }

    public static func clearOverrideCommand(simulatorReference: String) -> ProcessCommand {
        ProcessCommand(
            executable: "/usr/bin/xcrun",
            arguments: ["simctl", "status_bar", simulatorReference, "clear"]
        )
    }

    public static func applyMarketingOverride(
        destination: String,
        dryRun: Bool,
        run: (ProcessCommand) throws -> Void = { try ProcessRunner.run($0) }
    ) throws {
        guard usesIOSSimulatorDestination(destination) else { return }
        let simulatorReference = try resolveSimulatorReference(from: destination, dryRun: dryRun, run: run)
        let command = marketingOverrideCommand(simulatorReference: simulatorReference)
        if dryRun {
            print("Would apply App Store marketing status bar on \(simulatorReference):")
            print(command.rendered)
        } else {
            print("Applying App Store marketing status bar (\(marketingClockTime), \(marketingStatusBarDateTime)) on \(simulatorReference)…")
            try run(command)
        }
    }

    public static func clearMarketingOverride(
        destination: String,
        dryRun: Bool,
        run: (ProcessCommand) throws -> Void = { try ProcessRunner.run($0) }
    ) throws {
        guard usesIOSSimulatorDestination(destination) else { return }
        let simulatorReference = try resolveSimulatorReference(from: destination, dryRun: dryRun, run: run)
        let command = clearOverrideCommand(simulatorReference: simulatorReference)
        if dryRun {
            print("Would clear status bar overrides on \(simulatorReference):")
            print(command.rendered)
        } else {
            print("Clearing simulator status bar overrides on \(simulatorReference)…")
            try run(command)
        }
    }

    public struct ResolvedSimulator: Sendable {
        public let udid: String
        public let isBooted: Bool
    }

    public static func resolveSimulator(
        udid: String,
        devicesJSON: Data
    ) throws -> ResolvedSimulator {
        let payload = try JSONDecoder().decode(SimctlDevicesResponse.self, from: devicesJSON)
        for devices in payload.devices.values {
            for device in devices where device.isAvailable != false && device.udid == udid {
                let isBooted = device.state?.localizedCaseInsensitiveCompare("Booted") == .orderedSame
                return ResolvedSimulator(udid: device.udid, isBooted: isBooted)
            }
        }
        throw AppStoreScreenshotCaptureError.simulatorNotFound(udid)
    }

    public static func resolveSimulator(
        named simulatorName: String,
        osVersion: String? = nil,
        devicesJSON: Data
    ) throws -> ResolvedSimulator {
        let payload = try JSONDecoder().decode(SimctlDevicesResponse.self, from: devicesJSON)
        var matches: [(device: SimctlDevice, osVersion: String)] = []

        for (runtimeIdentifier, devices) in payload.devices {
            guard let runtimeOSVersion = SimulatorDestinationResolver.osVersion(fromRuntimeIdentifier: runtimeIdentifier) else {
                continue
            }
            if let osVersion, runtimeOSVersion != osVersion {
                continue
            }
            for device in devices where device.isAvailable != false && device.name == simulatorName {
                matches.append((device: device, osVersion: runtimeOSVersion))
            }
        }

        guard matches.isEmpty == false else {
            throw AppStoreScreenshotCaptureError.simulatorNotFound(simulatorName)
        }

        if let booted = matches.first(where: { $0.device.state?.localizedCaseInsensitiveCompare("Booted") == .orderedSame }) {
            return ResolvedSimulator(udid: booted.device.udid, isBooted: true)
        }

        let match = matches[0]
        return ResolvedSimulator(
            udid: match.device.udid,
            isBooted: match.device.state?.localizedCaseInsensitiveCompare("Booted") == .orderedSame
        )
    }

    public static func resolveSimulatorUDID(
        named simulatorName: String,
        osVersion: String? = nil,
        devicesJSON: Data
    ) throws -> String {
        try resolveSimulator(named: simulatorName, osVersion: osVersion, devicesJSON: devicesJSON).udid
    }

    public static func resolveSimulatorReference(
        from destination: String,
        dryRun: Bool,
        run: (ProcessCommand) throws -> Void = { try ProcessRunner.run($0) }
    ) throws -> String {
        if let udid = simulatorUDID(from: destination) {
            if dryRun {
                return udid
            }

            let listOutput = try ProcessRunner.run(
                ProcessCommand(
                    executable: "/usr/bin/xcrun",
                    arguments: ["simctl", "list", "devices", "available", "-j"]
                ),
                captureOutput: true
            )
            guard let data = listOutput.data(using: .utf8) else {
                throw AppStoreScreenshotCaptureError.simulatorLookupFailed("simctl list output was not UTF-8.")
            }

            let simulator = try resolveSimulator(udid: udid, devicesJSON: data)
            try ensureSimulatorIsBooted(udid: simulator.udid, alreadyBooted: simulator.isBooted, run: run)
            return simulator.udid
        }

        guard let simulatorName = simulatorName(from: destination) else {
            throw AppStoreScreenshotCaptureError.missingSimulatorName(destination)
        }
        if dryRun {
            return simulatorName
        }

        let listOutput = try ProcessRunner.run(
            ProcessCommand(
                executable: "/usr/bin/xcrun",
                arguments: ["simctl", "list", "devices", "available", "-j"]
            ),
            captureOutput: true
        )
        guard let data = listOutput.data(using: .utf8) else {
            throw AppStoreScreenshotCaptureError.simulatorLookupFailed("simctl list output was not UTF-8.")
        }

        let osVersion = simulatorOSVersion(from: destination)
        let simulator = try resolveSimulator(
            named: simulatorName,
            osVersion: osVersion,
            devicesJSON: data
        )
        try ensureSimulatorIsBooted(udid: simulator.udid, alreadyBooted: simulator.isBooted, run: run)
        return simulator.udid
    }

    private static func ensureSimulatorIsBooted(
        udid: String,
        alreadyBooted: Bool,
        run: (ProcessCommand) throws -> Void
    ) throws {
        if alreadyBooted == false {
            try run(
                ProcessCommand(
                    executable: "/usr/bin/xcrun",
                    arguments: ["simctl", "boot", udid]
                )
            )
        }
        try run(
            ProcessCommand(
                executable: "/usr/bin/xcrun",
                arguments: ["simctl", "bootstatus", udid, "-b"]
            )
        )
    }
}

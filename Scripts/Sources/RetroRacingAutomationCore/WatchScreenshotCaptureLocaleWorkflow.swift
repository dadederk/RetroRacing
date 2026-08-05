//
//  WatchScreenshotCaptureLocaleWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation
import ScriptSupport

/// Best-effort simulator locale setup for iPhone, iPad, and Apple Watch screenshot capture.
/// In-app strings follow launch-argument locale via `GameLocalizedStrings` and SwiftUI
/// `.environment(\.locale)`; `simctl` defaults supplement system chrome on simulators.
public enum WatchScreenshotCaptureLocaleWorkflow {
    public static let defaultAppStoreLocale = "en-US"

    struct SimulatorPairLookup: Decodable {
        struct Device: Decodable {
            let udid: String
        }

        struct Pair: Decodable {
            let watch: Device
            let phone: Device
        }

        let pairs: [String: Pair]
    }

    public static func applyCaptureLocale(
        appStoreLocale: String,
        destination: String,
        platform: String? = nil,
        dryRun: Bool,
        run: (ProcessCommand) throws -> Void = { try ProcessRunner.run($0) }
    ) throws {
        let simulatorUDIDs = try resolveSimulatorUDIDs(
            destination: destination,
            platform: platform,
            dryRun: dryRun,
            run: run
        )
        let language = inAppLanguageIdentifier(for: appStoreLocale)
        let locale = appleLocaleArgument(for: appStoreLocale)

        for udid in simulatorUDIDs {
            if dryRun {
                print(
                    "Would boot simulator \(udid) if needed, then set locale to \(appStoreLocale) " +
                    "(AppleLanguages=(\(language)), AppleLocale=\(locale))"
                )
                continue
            }

            try ensureSimulatorIsBooted(udid: udid, run: run)
            try run(
                ProcessCommand(
                    executable: "/usr/bin/xcrun",
                    arguments: [
                        "simctl", "spawn", udid, "defaults", "write", "-g",
                        "AppleLanguages", "-array", language,
                    ]
                )
            )
            try run(
                ProcessCommand(
                    executable: "/usr/bin/xcrun",
                    arguments: [
                        "simctl", "spawn", udid, "defaults", "write", "-g",
                        "AppleLocale", locale,
                    ]
                )
            )
        }

        if dryRun == false {
            print("Applied capture locale \(appStoreLocale) on simulator(s): \(simulatorUDIDs.joined(separator: ", "))")
        }
    }

    public static func restoreDefaultLocale(
        destination: String,
        platform: String? = nil,
        dryRun: Bool,
        run: (ProcessCommand) throws -> Void = { try ProcessRunner.run($0) }
    ) throws {
        try applyCaptureLocale(
            appStoreLocale: defaultAppStoreLocale,
            destination: destination,
            platform: platform,
            dryRun: dryRun,
            run: run
        )
    }

    public static func pairedPhoneUDID(
        forWatchUDID watchUDID: String,
        pairsJSON: Data
    ) throws -> String? {
        let payload = try JSONDecoder().decode(SimulatorPairLookup.self, from: pairsJSON)
        return payload.pairs.values.first { $0.watch.udid == watchUDID }?.phone.udid
    }

    static func inAppLanguageIdentifier(for appStoreLocale: String) -> String {
        switch appStoreLocale {
        case "de-DE": return "de"
        case "nl-NL": return "nl"
        case "fr-FR": return "fr"
        case "es-ES": return "es"
        case "es-MX": return "es-MX"
        case "ca": return "ca"
        case "en-US": return "en"
        case "en-GB": return "en-GB"
        case "en-AU": return "en-AU"
        case "en-CA": return "en-CA"
        default: return appStoreLocale
        }
    }

    static func appleLocaleArgument(for appStoreLocale: String) -> String {
        appStoreLocale.replacingOccurrences(of: "-", with: "_")
    }

    static func resolveSimulatorUDIDs(
        destination: String,
        platform: String?,
        dryRun: Bool,
        run: (ProcessCommand) throws -> Void
    ) throws -> [String] {
        let udid = try resolveSimulatorUDID(from: destination, dryRun: dryRun, run: run)
        if let platform,
           AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform) == "appleWatch",
           let pairedPhoneUDID = try pairedPhoneUDID(forWatchUDID: udid) {
            return [pairedPhoneUDID, udid]
        }
        return [udid]
    }

    private static func resolveSimulatorUDID(
        from destination: String,
        dryRun: Bool,
        run: (ProcessCommand) throws -> Void
    ) throws -> String {
        if let udid = SimulatorStatusBarWorkflow.simulatorUDID(from: destination) {
            return udid
        }
        return try SimulatorStatusBarWorkflow.resolveSimulatorReference(
            from: destination,
            dryRun: dryRun,
            run: run
        )
    }

    private static func pairedPhoneUDID(forWatchUDID watchUDID: String) throws -> String? {
        let output = try ProcessRunner.run(
            ProcessCommand(
                executable: "/usr/bin/xcrun",
                arguments: ["simctl", "list", "pairs", "-j"]
            ),
            captureOutput: true
        )
        guard let data = output.data(using: .utf8) else { return nil }
        return try pairedPhoneUDID(forWatchUDID: watchUDID, pairsJSON: data)
    }

    private static func ensureSimulatorIsBooted(
        udid: String,
        run: (ProcessCommand) throws -> Void
    ) throws {
        // `simctl boot` exits non-zero when already booted; ignore that and wait for readiness.
        try? run(
            ProcessCommand(
                executable: "/usr/bin/xcrun",
                arguments: ["simctl", "boot", udid]
            )
        )
        try run(
            ProcessCommand(
                executable: "/usr/bin/xcrun",
                arguments: ["simctl", "bootstatus", udid, "-b"]
            )
        )
    }
}

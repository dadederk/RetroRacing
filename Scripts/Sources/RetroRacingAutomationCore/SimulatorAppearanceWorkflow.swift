//
//  SimulatorAppearanceWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation
import ScriptSupport

/// Sets iPhone/iPad simulator system appearance via `simctl ui` to match capture chrome.
public enum SimulatorAppearanceWorkflow {
    public static func shouldApply(platform: String) -> Bool {
        switch AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform) {
        case "iphone", "ipad":
            return true
        default:
            return false
        }
    }

    public static func apply(
        appearance: AppStoreScreenshotAppearance,
        destination: String,
        dryRun: Bool,
        run: (ProcessCommand) throws -> Void = { try ProcessRunner.run($0) }
    ) throws {
        let simulatorReference = try SimulatorStatusBarWorkflow.resolveSimulatorReference(
            from: destination,
            dryRun: dryRun,
            run: run
        )
        if dryRun {
            print("Would set simulator appearance to \(appearance.rawValue) on \(simulatorReference)")
            return
        }
        try run(
            ProcessCommand(
                executable: "/usr/bin/xcrun",
                arguments: [
                    "simctl", "ui", simulatorReference, "appearance", appearance.rawValue,
                ]
            )
        )
        print("Applied simulator appearance \(appearance.rawValue) on \(simulatorReference)")
    }
}

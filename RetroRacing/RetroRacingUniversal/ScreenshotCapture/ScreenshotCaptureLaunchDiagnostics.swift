//
//  ScreenshotCaptureLaunchDiagnostics.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 23/07/2026.
//

#if os(macOS)
import Foundation
import RetroRacingShared

enum ScreenshotCaptureLaunchDiagnostics {
    static func writeAppLaunchSnapshot(stagingDirectory: URL?) {
        writeSnapshot(phase: "app-init", slideIndex: ScreenshotCaptureConfiguration.current?.slideIndex, to: stagingDirectory)
    }

    static func writeCaptureModeSnapshot(to stagingDirectory: URL?, slideIndex: Int) {
        writeSnapshot(phase: "screenshot-root-appear", slideIndex: slideIndex, to: stagingDirectory)
    }

    private static func writeSnapshot(phase: String, slideIndex: Int?, to stagingDirectory: URL?) {
        let payload = [
            "phase": phase,
            "slideIndex": slideIndex.map(String.init) ?? "missing",
            "args": ProcessInfo.processInfo.arguments.joined(separator: " | "),
            "captureEnv": ProcessInfo.processInfo.environment[ScreenshotCaptureIdentifiers.captureEnabledKey] ?? "missing",
            "slideEnv": ProcessInfo.processInfo.environment[ScreenshotCaptureIdentifiers.slideIndexKey] ?? "missing",
            "isEnabled": String(ScreenshotCaptureConfiguration.isCaptureModeEnabled),
            "current": String(ScreenshotCaptureConfiguration.current != nil),
        ].map { "\($0.key)=\($0.value)" }.joined(separator: "\n")

        fputs("RetroRapid capture diagnostics\n\(payload)\n", stderr)
        let diagnosticURL = URL(fileURLWithPath: "/tmp/retrorapid-capture-diagnostics.txt")
        try? payload.write(to: diagnosticURL, atomically: true, encoding: .utf8)
        guard let stagingDirectory else { return }
        let fileName = "capture-diagnostics-\(slideIndex.map(String.init) ?? "unknown").txt"
        let url = stagingDirectory.appending(path: fileName)
        try? payload.write(to: url, atomically: true, encoding: .utf8)
    }
}
#endif

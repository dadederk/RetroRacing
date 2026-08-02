//
//  MacScreenshotCaptureAppDelegate.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 24/07/2026.
//

#if os(macOS)
import AppKit
import RetroRacingShared

final class MacScreenshotCaptureAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard shouldPrepareForAutomation else { return }
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        ScreenshotCaptureLaunchDiagnostics.writeAppLaunchSnapshot(
            stagingDirectory: ScreenshotCaptureConfiguration.current?.stagingDirectory
        )
        DispatchQueue.main.async {
            self.openInitialWindowIfNeeded()
            ScreenshotCaptureMacWindowLayout.applyLandscapeCaptureSize()
        }
    }

    private func openInitialWindowIfNeeded() {
        guard NSApplication.shared.windows.contains(where: \.isVisible) == false else { return }
        NSApp.sendAction(#selector(NSDocumentController.newDocument(_:)), to: nil, from: nil)
        if NSApplication.shared.windows.contains(where: \.isVisible) == false {
            NSApp.sendAction(#selector(NSApplication.newWindowForTab(_:)), to: nil, from: nil)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        guard ScreenshotCaptureConfiguration.current != nil else { return }
        ScreenshotCaptureMacWindowLayout.applyLandscapeCaptureSize()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard shouldPrepareForAutomation, flag == false else { return true }
        openInitialWindowIfNeeded()
        ScreenshotCaptureMacWindowLayout.applyLandscapeCaptureSize()
        return true
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        ScreenshotCaptureConfiguration.isCaptureModeEnabled
    }

    private var shouldPrepareForAutomation: Bool {
        if ScreenshotCaptureConfiguration.isCaptureModeEnabled {
            return true
        }
        return ProcessInfo.processInfo.environment["UITesting"] == "1"
    }
}
#endif

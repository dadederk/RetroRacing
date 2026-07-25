//
//  ScreenshotCaptureMacWindowLayout.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 23/07/2026.
//

#if os(macOS)
import AppKit
import RetroRacingShared

enum ScreenshotCaptureMacWindowLayout {
    static func applyLandscapeCaptureSize() {
        guard ScreenshotCaptureConfiguration.current != nil else { return }

        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        applyLandscapeCaptureSizeIfPossible()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            applyLandscapeCaptureSizeIfPossible()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            applyLandscapeCaptureSizeIfPossible()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            applyLandscapeCaptureSizeIfPossible()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            applyLandscapeCaptureSizeIfPossible()
        }
    }

    private static func applyLandscapeCaptureSizeIfPossible() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let windows = NSApplication.shared.windows.filter(\.isVisible)
        guard let window = windows.first ?? NSApplication.shared.windows.first else { return }

        let contentSize = ScreenshotCaptureWindowConfiguration.macLandscapeContentSize
        window.setContentSize(contentSize)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}
#endif

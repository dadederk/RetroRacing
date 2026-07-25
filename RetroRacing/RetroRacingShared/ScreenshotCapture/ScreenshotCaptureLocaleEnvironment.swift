//
//  ScreenshotCaptureLocaleEnvironment.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 25/07/2026.
//

import SwiftUI

public extension View {
    /// Forces SwiftUI string-catalog localization during App Store screenshot capture.
    @ViewBuilder
    func screenshotCaptureLocaleEnvironment() -> some View {
        if let locale = ScreenshotCaptureLocaleCatalog.resolvedCaptureLocale {
            environment(\.locale, locale)
        } else {
            self
        }
    }
}

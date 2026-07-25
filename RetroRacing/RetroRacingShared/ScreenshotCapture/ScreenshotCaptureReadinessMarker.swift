//
//  ScreenshotCaptureReadinessMarker.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import SwiftUI

public struct ScreenshotCaptureReadinessMarker: View {
    let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }

    public var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: 24, height: 24)
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityIdentifier(identifier)
            .accessibilityLabel(String(localized: "Screenshot capture ready"))
    }
}

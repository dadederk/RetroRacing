//
//  ControlsHelpContentView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 19/02/2026.
//

import SwiftUI

/// Reusable controls explanation block used in Settings and in-game help.
public struct ControlsHelpContentView: View {
    public let controlsDescriptionKey: String
    /// When false, only the description text is shown (e.g. when a parent provides a section header).
    public let showTitle: Bool
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    public init(controlsDescriptionKey: String, showTitle: Bool = true) {
        self.controlsDescriptionKey = controlsDescriptionKey
        self.showTitle = showTitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showTitle {
                Text(GameLocalizedStrings.string("settings_controls"))
                    .font(fontPreferenceStore?.font(textStyle: .headline) ?? .headline)
            }

            Text(GameLocalizedStrings.string(controlsDescriptionKey))
                .font(fontPreferenceStore?.font(textStyle: .body) ?? .body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

//
//  SettingsGalleryUnlockSection.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import SwiftUI

/// Shared Unlimited Plays prompt used by selectable Settings galleries.
struct SettingsGalleryUnlockSection: View {
    let message: String
    let onUnlockRequest: () -> Void

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(message)
                    .appFont(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onUnlockRequest) {
                    Label(
                        GameLocalizedStrings.string("settings_learn_premium"),
                        systemImage: "star.circle.fill"
                    )
                    .appFont(.body)
                    .foregroundStyle(.tint)
                }
            }
        }
    }
}

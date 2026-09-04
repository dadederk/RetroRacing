//
//  SettingsGalleryOptionState.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/09/2026.
//

import SwiftUI

enum SettingsGalleryOptionState: Equatable {
    case available
    case selected
    case checkingAccess
    case locked

    var accessibilityValue: String {
        GameLocalizedStrings.string(accessibilityValueKey)
    }

    fileprivate var systemImageName: String? {
        switch self {
        case .available:
            nil
        case .selected:
            "checkmark.circle.fill"
        case .checkingAccess:
            "hourglass"
        case .locked:
            "lock.fill"
        }
    }

    private var accessibilityValueKey: String {
        switch self {
        case .available:
            "settings_gallery_state_available"
        case .selected:
            "settings_gallery_state_selected"
        case .checkingAccess:
            "settings_gallery_state_checking_access"
        case .locked:
            "settings_gallery_state_requires_unlimited_plays"
        }
    }
}

struct SettingsGalleryStateIndicator: View {
    let state: SettingsGalleryOptionState
    let size: CGFloat
    var reservesSpaceWhenAvailable = false

    @ViewBuilder
    var body: some View {
        if let systemImageName = state.systemImageName {
            Image(systemName: systemImageName)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.pink)
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        } else if reservesSpaceWhenAvailable {
            Color.clear
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
    }
}

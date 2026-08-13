//
//  AppIconSelectionPolicy.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import Foundation

public enum AppIconSelectionAction: Equatable, Sendable {
    case none
    case selectIcon
    case waitForEntitlement
    case presentPaywall
}

/// Pure entitlement and current-selection policy for app icon changes.
public enum AppIconSelectionPolicy {
    public static func action(
        option: AppIconOption,
        currentIconID: AppIconID?,
        hasUnlimitedAccessForGating: Bool,
        hasResolvedInitialEntitlements: Bool
    ) -> AppIconSelectionAction {
        guard option.id != currentIconID else {
            return .none
        }
        guard option.id != .classic else {
            return .selectIcon
        }
        if hasUnlimitedAccessForGating {
            return .selectIcon
        }
        guard hasResolvedInitialEntitlements else {
            return .waitForEntitlement
        }
        return .presentPaywall
    }
}

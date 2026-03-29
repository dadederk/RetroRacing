//
//  DirectTouchSetting.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 28/03/2026.
//

import Foundation

/// Conditional-default wrapper value for Direct Touch accessibility preference.
public struct DirectTouchSetting: Codable, Equatable, Sendable {
    public static let conditionalDefaultStorageKey = "directTouch_conditionalDefault"

    public let isEnabled: Bool

    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}

extension DirectTouchSetting: ConditionalDefaultValue {
    public static var systemDefault: DirectTouchSetting {
        DirectTouchSetting(isEnabled: true)
    }
}

public enum DirectTouchPreference {
    public static func currentSelection(from userDefaults: UserDefaults) -> Bool {
        let conditionalDefault = ConditionalDefault<DirectTouchSetting>.load(
            from: userDefaults,
            key: DirectTouchSetting.conditionalDefaultStorageKey
        )
        return conditionalDefault.effectiveValue.isEnabled
    }

    public static func setUserOverride(_ isEnabled: Bool, in userDefaults: UserDefaults) {
        var conditionalDefault = ConditionalDefault<DirectTouchSetting>.load(
            from: userDefaults,
            key: DirectTouchSetting.conditionalDefaultStorageKey
        )
        conditionalDefault.setUserOverride(DirectTouchSetting(isEnabled: isEnabled))
        conditionalDefault.save(
            to: userDefaults,
            key: DirectTouchSetting.conditionalDefaultStorageKey
        )
    }
}

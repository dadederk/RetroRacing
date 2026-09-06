//
//  AppIconFeatureFlag.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

/// Availability boundary for the alternate-app-icon rollout.
@MainActor
public protocol AppIconFeatureFlagging: AnyObject {
    var isEnabled: Bool { get }

    func refresh()
    func setEnabled(_ isEnabled: Bool)
}

/// Deterministic rollout used by unsupported platforms, previews, and tests.
@MainActor
public final class FixedAppIconFeatureFlag: AppIconFeatureFlagging {
    public private(set) var isEnabled: Bool
    private let allowsChanges: Bool

    public init(isEnabled: Bool, allowsChanges: Bool = false) {
        self.isEnabled = isEnabled
        self.allowsChanges = allowsChanges
    }

    public func refresh() {}

    public func setEnabled(_ isEnabled: Bool) {
        guard allowsChanges else { return }
        self.isEnabled = isEnabled
    }
}

/// Bridges the existing icon service to the shared release policy.
@MainActor
public final class ReleaseAppIconFeatureFlag: AppIconFeatureFlagging {
    private let features: any ReleaseFeatureProviding
    public var isEnabled: Bool { features.isEnabled(.alternateIcons) }

    public init(features: any ReleaseFeatureProviding) { self.features = features }
    public func refresh() {}
    public func setEnabled(_ isEnabled: Bool) {
        features.setOverride(isEnabled ? .enabled : .disabled, for: .alternateIcons)
    }
}

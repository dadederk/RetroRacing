//
//  ReleaseFeatures.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 06/09/2026.
//

import Foundation
import Observation

public enum ReleaseFeature: String, CaseIterable, Sendable {
    case retroThemes, alternateIcons, discTheme, polygonTheme, sharePlay

    public var storageKey: String { "releasePreview.\(rawValue)" }
    public var titleKey: String { "debug_release_\(rawValue)" }
}

public enum ReleaseFeatureOverride: String, CaseIterable, Sendable {
    case releaseDefault, enabled, disabled

    public var titleKey: String { "debug_release_override_\(rawValue)" }
}

/// Committed shipping policy. Change these defaults when promoting the next release.
public enum ReleaseFeatureDefaults {
    public static let retroThemes = false
    public static let alternateIcons = false
    public static let macSharePlay = true

    public static func isEnabled(_ feature: ReleaseFeature, platform: ThemeCatalogPlatform) -> Bool {
        switch feature {
        case .retroThemes: retroThemes || platform == .tvOS || platform == .visionOS
        case .alternateIcons: alternateIcons && (platform == .iPhone || platform == .iPad)
        case .discTheme: platform.alwaysIncludes(.thirtyTwoBit)
        case .polygonTheme: platform.alwaysIncludes(.sixtyFourBit)
        case .sharePlay: platform == .macOS ? macSharePlay : platform != .watchOS && platform != .custom
        }
    }
}

@MainActor
public protocol ReleaseFeatureProviding: AnyObject {
    var platform: ThemeCatalogPlatform { get }
    var allowsOverrides: Bool { get }
    func isEnabled(_ feature: ReleaseFeature) -> Bool
    func override(for feature: ReleaseFeature) -> ReleaseFeatureOverride
    func setOverride(_ override: ReleaseFeatureOverride, for feature: ReleaseFeature)
    func resetOverrides()
}

@MainActor
@Observable
public final class ReleaseFeatureStore: ReleaseFeatureProviding {
    public let platform: ThemeCatalogPlatform
    public let allowsOverrides: Bool
    private let userDefaults: UserDefaults
    private var overrides: [ReleaseFeature: ReleaseFeatureOverride]

    public init(platform: ThemeCatalogPlatform, userDefaults: UserDefaults, allowsOverrides: Bool) {
        self.platform = platform
        self.userDefaults = userDefaults
        self.allowsOverrides = allowsOverrides
        overrides = Dictionary(uniqueKeysWithValues: ReleaseFeature.allCases.map { feature in
            let value = userDefaults.string(forKey: feature.storageKey)
                .flatMap(ReleaseFeatureOverride.init(rawValue:)) ?? .releaseDefault
            return (feature, allowsOverrides ? value : .releaseDefault)
        })
    }

    public func override(for feature: ReleaseFeature) -> ReleaseFeatureOverride {
        overrides[feature] ?? .releaseDefault
    }

    public func isEnabled(_ feature: ReleaseFeature) -> Bool {
        switch override(for: feature) {
        case .enabled: true
        case .disabled: false
        case .releaseDefault: ReleaseFeatureDefaults.isEnabled(feature, platform: platform)
        }
    }

    public func setOverride(_ override: ReleaseFeatureOverride, for feature: ReleaseFeature) {
        guard allowsOverrides else { return }
        overrides[feature] = override
        if override == .releaseDefault {
            userDefaults.removeObject(forKey: feature.storageKey)
        } else {
            userDefaults.set(override.rawValue, forKey: feature.storageKey)
        }
    }

    public func resetOverrides() {
        for feature in ReleaseFeature.allCases { setOverride(.releaseDefault, for: feature) }
    }
}

public extension ReleaseFeatureProviding {
    var themeConfiguration: ThemePlatformConfig {
        .configuration(
            for: platform,
            experimentalThemes: ExperimentalThemeConfiguration(
                isThirtyTwoBitEnabled: isEnabled(.discTheme),
                isSixtyFourBitEnabled: isEnabled(.polygonTheme)
            ),
            includesRetroThemes: isEnabled(.retroThemes)
        )
    }
}

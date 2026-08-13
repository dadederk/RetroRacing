//
//  AppIconChanging.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import Foundation

/// Main-actor boundary around a platform's persistent alternate-icon API.
@MainActor
public protocol AppIconChanging: AnyObject {
    var supportsAlternateIcons: Bool { get }
    var alternateIconName: String? { get }

    func setAlternateIconName(_ alternateIconName: String?) async throws
}

/// Explicit adapter for platforms where persistent alternate icons are unsupported.
@MainActor
public final class UnsupportedAppIconChanger: AppIconChanging {
    public let supportsAlternateIcons = false
    public let alternateIconName: String? = nil

    public init() {}

    public func setAlternateIconName(_ alternateIconName: String?) async throws {
        throw AppIconServiceError.unsupported
    }
}

/// Deterministic Classic adapter for previews, tests, and screenshot capture.
@MainActor
public final class PreviewAppIconChanger: AppIconChanging {
    public let supportsAlternateIcons: Bool
    public private(set) var alternateIconName: String?

    public init(supportsAlternateIcons: Bool, alternateIconName: String? = nil) {
        self.supportsAlternateIcons = supportsAlternateIcons
        self.alternateIconName = alternateIconName
    }

    public func setAlternateIconName(_ alternateIconName: String?) async throws {
        guard supportsAlternateIcons else {
            throw AppIconServiceError.unsupported
        }
        self.alternateIconName = alternateIconName
    }
}

//
//  AppIconService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import Foundation
import Observation

public enum AppIconServiceError: Error, Equatable, Sendable {
    case featureDisabled
    case unsupported
    case unknownIcon
    case changeInProgress
}

/// Observable app-icon state backed exclusively by the operating system.
@MainActor
@Observable
public final class AppIconService {
    public private(set) var isFeatureEnabled: Bool
    public let isGalleryPlatformEnabled: Bool
    public private(set) var supportsAlternateIcons: Bool
    public private(set) var currentIconID: AppIconID?
    public private(set) var changingIconID: AppIconID?

    private let changer: any AppIconChanging
    private let featureFlag: any AppIconFeatureFlagging

    public var isGalleryAvailable: Bool {
        isGalleryPlatformEnabled && isFeatureEnabled
    }

    public var currentOption: AppIconOption? {
        currentIconID.flatMap(AppIconCatalog.option(for:))
    }

    public init(
        changer: any AppIconChanging,
        featureFlag: any AppIconFeatureFlagging,
        isGalleryPlatformEnabled: Bool
    ) {
        self.changer = changer
        self.featureFlag = featureFlag
        self.isGalleryPlatformEnabled = isGalleryPlatformEnabled
        isFeatureEnabled = featureFlag.isEnabled
        supportsAlternateIcons = changer.supportsAlternateIcons
        currentIconID = AppIconCatalog.option(forSystemIconName: changer.alternateIconName)?.id
    }

    public func setFeatureEnabled(_ isEnabled: Bool) {
        featureFlag.setEnabled(isEnabled)
        self.isFeatureEnabled = featureFlag.isEnabled
        logAvailability(event: "APP_ICON_ROLLOUT_CHANGED")
    }

    public func refreshFeatureFlag() {
        featureFlag.refresh()
        isFeatureEnabled = featureFlag.isEnabled
    }

    public func refreshCurrentIcon() {
        currentIconID = AppIconCatalog.option(forSystemIconName: changer.alternateIconName)?.id
    }

    /// Refreshes UIKit-owned capability and selection after the application becomes active.
    public func refreshSystemState() {
        supportsAlternateIcons = changer.supportsAlternateIcons
        refreshCurrentIcon()
        logAvailability(event: "APP_ICON_AVAILABILITY")
    }

    public func changeIcon(to id: AppIconID) async throws {
        guard isFeatureEnabled else {
            throw AppIconServiceError.featureDisabled
        }
        guard isGalleryPlatformEnabled else {
            throw AppIconServiceError.unsupported
        }

        // UIKit can report its capability as the application moves between lifecycle states.
        // Read it at the point of use instead of trusting an earlier Settings refresh.
        supportsAlternateIcons = changer.supportsAlternateIcons
        guard supportsAlternateIcons else {
            AppLog.error(
                AppLog.assets + AppLog.lifecycle,
                "APP_ICON_CHANGE",
                outcome: .blocked,
                fields: [
                    .reason("system_unsupported"),
                    .string("requestedIcon", id.rawValue),
                ]
            )
            throw AppIconServiceError.unsupported
        }
        guard changingIconID == nil else {
            throw AppIconServiceError.changeInProgress
        }
        guard let option = AppIconCatalog.option(for: id) else {
            throw AppIconServiceError.unknownIcon
        }
        guard currentIconID != id else { return }

        changingIconID = id
        defer { changingIconID = nil }

        do {
            try await changer.setAlternateIconName(option.systemIconName)
            refreshCurrentIcon()
            AppLog.info(
                AppLog.assets + AppLog.lifecycle,
                "APP_ICON_CHANGE",
                outcome: .succeeded,
                fields: [
                    .string("requestedIcon", option.systemIconName ?? AppIconID.classic.rawValue),
                    .string("currentIcon", currentIconID?.rawValue ?? AppIconID.classic.rawValue),
                ]
            )
        } catch {
            refreshCurrentIcon()
            AppLog.error(
                AppLog.assets + AppLog.lifecycle,
                "APP_ICON_CHANGE",
                outcome: .failed,
                fields: [
                    .string("requestedIcon", option.systemIconName ?? AppIconID.classic.rawValue),
                    .string("currentIcon", currentIconID?.rawValue ?? AppIconID.classic.rawValue),
                ] + AppLog.Field.error(error)
            )
            throw error
        }
    }

    private func logAvailability(event: String) {
        let reason: String
        if isGalleryPlatformEnabled == false {
            reason = "platform_disabled"
        } else if isFeatureEnabled == false {
            reason = "rollout_disabled"
        } else if supportsAlternateIcons == false {
            reason = "gallery_available_system_unsupported"
        } else {
            reason = "available"
        }

        AppLog.info(
            AppLog.assets + AppLog.lifecycle,
            event,
            outcome: isGalleryAvailable ? .succeeded : .blocked,
            fields: [
                .reason(reason),
                .bool("featureEnabled", isFeatureEnabled),
                .bool("systemSupported", supportsAlternateIcons),
                .string("currentIcon", currentIconID?.rawValue ?? AppIconID.classic.rawValue),
            ]
        )
    }
}

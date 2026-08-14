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
        logRolloutChange()
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
        logAvailability()
    }

    public func changeIcon(to id: AppIconID) async throws {
        supportsAlternateIcons = changer.supportsAlternateIcons
        AppLog.info(
            AppLog.assets + AppLog.lifecycle,
            "APP_ICON_CHANGE",
            outcome: .requested,
            fields: changeFields(requestedID: id)
        )

        guard isFeatureEnabled else {
            logBlockedChange(requestedID: id, reason: "feature_disabled")
            throw AppIconServiceError.featureDisabled
        }
        guard isGalleryPlatformEnabled else {
            logBlockedChange(requestedID: id, reason: "platform_disabled")
            throw AppIconServiceError.unsupported
        }
        guard changingIconID == nil else {
            logBlockedChange(requestedID: id, reason: "change_in_progress")
            throw AppIconServiceError.changeInProgress
        }
        guard let option = AppIconCatalog.option(for: id) else {
            logBlockedChange(requestedID: id, reason: "unknown_icon")
            throw AppIconServiceError.unknownIcon
        }
        guard currentIconID != id else {
            AppLog.info(
                AppLog.assets + AppLog.lifecycle,
                "APP_ICON_CHANGE",
                outcome: .ignored,
                fields: [.reason("already_selected")] + changeFields(requestedID: id)
            )
            return
        }

        do {
            try await performSystemChange(to: option, requestedID: id)
            refreshCurrentIcon()
            AppLog.info(
                AppLog.assets + AppLog.lifecycle,
                "APP_ICON_CHANGE",
                outcome: .succeeded,
                fields: changeFields(requestedID: id)
            )
        } catch {
            refreshCurrentIcon()
            AppLog.error(
                AppLog.assets + AppLog.lifecycle,
                "APP_ICON_CHANGE",
                outcome: .failed,
                fields: [.reason("system_request_failed")]
                    + changeFields(requestedID: id)
                    + AppLog.Field.error(error)
            )
            throw error
        }
    }

    private func performSystemChange(
        to option: AppIconOption,
        requestedID: AppIconID
    ) async throws {
        changingIconID = requestedID
        defer { changingIconID = nil }
        try await changer.setAlternateIconName(option.systemIconName)
    }

    private func logBlockedChange(requestedID: AppIconID, reason: String) {
        AppLog.info(
            AppLog.assets + AppLog.lifecycle,
            "APP_ICON_CHANGE",
            outcome: .blocked,
            fields: [.reason(reason)] + changeFields(requestedID: requestedID)
        )
    }

    private func changeFields(requestedID: AppIconID) -> [AppLog.Field] {
        [
            .string("requestedIconID", requestedID.rawValue),
            .string("currentIconID", currentIconID?.rawValue ?? AppIconID.classic.rawValue),
            .bool("featureEnabled", isFeatureEnabled),
            .bool("platformEnabled", isGalleryPlatformEnabled),
            .bool("systemSupported", supportsAlternateIcons),
        ]
    }

    private func logAvailability() {
        let payload = availabilityLogPayload()
        AppLog.info(
            AppLog.assets + AppLog.lifecycle,
            "APP_ICON_AVAILABILITY",
            outcome: payload.outcome,
            fields: payload.fields
        )
    }

    private func logRolloutChange() {
        let payload = availabilityLogPayload()
        AppLog.info(
            AppLog.assets + AppLog.lifecycle,
            "APP_ICON_ROLLOUT_CHANGED",
            outcome: payload.outcome,
            fields: payload.fields
        )
    }

    private func availabilityLogPayload() -> (outcome: AppLog.Outcome, fields: [AppLog.Field]) {
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

        return (
            isGalleryAvailable ? .succeeded : .blocked,
            [
                .reason(reason),
                .bool("featureEnabled", isFeatureEnabled),
                .bool("systemSupported", supportsAlternateIcons),
                .string("currentIconID", currentIconID?.rawValue ?? AppIconID.classic.rawValue),
            ]
        )
    }
}

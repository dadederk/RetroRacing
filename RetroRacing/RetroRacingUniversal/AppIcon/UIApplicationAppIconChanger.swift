//
//  UIApplicationAppIconChanger.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 13/08/2026.
//

#if os(iOS)
import RetroRacingShared
import UIKit

/// UIKit implementation of RetroRapid's persistent alternate-icon boundary.
@MainActor
final class UIApplicationAppIconChanger: AppIconChanging {
    private let application: UIApplication

    var supportsAlternateIcons: Bool {
        application.supportsAlternateIcons
    }

    var alternateIconName: String? {
        application.alternateIconName
    }

    init(application: UIApplication) {
        self.application = application
    }

    func setAlternateIconName(_ alternateIconName: String?) async throws {
        let requestedIcon = alternateIconName ?? AppIconID.classic.rawValue
        AppLog.info(
            AppLog.assets + AppLog.lifecycle,
            "APP_ICON_SYSTEM_REQUEST",
            outcome: .requested,
            fields: systemFields(requestedIcon: requestedIcon)
        )

        do {
            try await application.setAlternateIconName(alternateIconName)
            AppLog.info(
                AppLog.assets + AppLog.lifecycle,
                "APP_ICON_SYSTEM_REQUEST",
                outcome: .succeeded,
                fields: systemFields(requestedIcon: requestedIcon)
            )
        } catch {
            AppLog.error(
                AppLog.assets + AppLog.lifecycle,
                "APP_ICON_SYSTEM_REQUEST",
                outcome: .failed,
                fields: [.reason("uikit_request_failed")]
                    + systemFields(requestedIcon: requestedIcon)
                    + AppLog.Field.error(error)
            )
            throw error
        }
    }

    private func systemFields(requestedIcon: String) -> [AppLog.Field] {
        [
            .string("requestedSystemIcon", requestedIcon),
            .string("reportedSystemIcon", application.alternateIconName ?? AppIconID.classic.rawValue),
            .bool("systemSupported", application.supportsAlternateIcons),
            .int("applicationState", application.applicationState.rawValue),
        ]
    }
}
#endif

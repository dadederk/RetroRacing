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
        try await application.setAlternateIconName(alternateIconName)
    }
}
#endif

//
//  ViewStyles.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI

public struct MenuViewStyle {
    public let titleFontSize: CGFloat
    public let titleBottomPadding: CGFloat
    public let menuSpacing: CGFloat
    public let buttonSpacing: CGFloat
    public let buttonFontSize: CGFloat
    public let contentPadding: CGFloat?
    public let allowsDynamicType: Bool

    public init(
        titleFontSize: CGFloat,
        titleBottomPadding: CGFloat,
        menuSpacing: CGFloat,
        buttonSpacing: CGFloat,
        buttonFontSize: CGFloat,
        contentPadding: CGFloat?,
        allowsDynamicType: Bool
    ) {
        self.titleFontSize = titleFontSize
        self.titleBottomPadding = titleBottomPadding
        self.menuSpacing = menuSpacing
        self.buttonSpacing = buttonSpacing
        self.buttonFontSize = buttonFontSize
        self.contentPadding = contentPadding
        self.allowsDynamicType = allowsDynamicType
    }

    public static let universal = MenuViewStyle(
        titleFontSize: 27,
        titleBottomPadding: 40,
        menuSpacing: 24,
        buttonSpacing: 24,
        buttonFontSize: 18,
        contentPadding: 16,
        allowsDynamicType: true
    )

    public static let tvOS = MenuViewStyle(
        titleFontSize: 42,
        titleBottomPadding: 60,
        menuSpacing: 40,
        buttonSpacing: 40,
        buttonFontSize: 24,
        contentPadding: nil,
        allowsDynamicType: false
    )
}

public struct SettingsViewStyle {
    public let labelFontSize: CGFloat

    public init(labelFontSize: CGFloat) {
        self.labelFontSize = labelFontSize
    }

    public static let universal = SettingsViewStyle(labelFontSize: 14)
    public static let tvOS = SettingsViewStyle(labelFontSize: 18)
}

public struct GameViewStyle {
    public let hudFontSize: CGFloat
    public let pauseButtonFontSize: CGFloat
    public let lifeIconSize: CGFloat
    public let headerPadding: CGFloat

    public init(hudFontSize: CGFloat, pauseButtonFontSize: CGFloat, lifeIconSize: CGFloat, headerPadding: CGFloat) {
        self.hudFontSize = hudFontSize
        self.pauseButtonFontSize = pauseButtonFontSize
        self.lifeIconSize = lifeIconSize
        self.headerPadding = headerPadding
    }

    public static let universal = GameViewStyle(hudFontSize: 14, pauseButtonFontSize: 16, lifeIconSize: 20, headerPadding: 16)
    public static let tvOS = GameViewStyle(hudFontSize: 28, pauseButtonFontSize: 22, lifeIconSize: 28, headerPadding: 60)
}

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
    public let compactHeightTitleTopPadding: CGFloat?
    public let menuSpacing: CGFloat
    public let buttonSpacing: CGFloat
    public let buttonFontSize: CGFloat
    public let contentPadding: CGFloat?
    public let allowsDynamicType: Bool

    public init(
        titleFontSize: CGFloat,
        titleBottomPadding: CGFloat,
        compactHeightTitleTopPadding: CGFloat? = nil,
        menuSpacing: CGFloat,
        buttonSpacing: CGFloat,
        buttonFontSize: CGFloat,
        contentPadding: CGFloat?,
        allowsDynamicType: Bool
    ) {
        self.titleFontSize = titleFontSize
        self.titleBottomPadding = titleBottomPadding
        self.compactHeightTitleTopPadding = compactHeightTitleTopPadding
        self.menuSpacing = menuSpacing
        self.buttonSpacing = buttonSpacing
        self.buttonFontSize = buttonFontSize
        self.contentPadding = contentPadding
        self.allowsDynamicType = allowsDynamicType
    }

    public static let universal = MenuViewStyle(
        titleFontSize: 27,
        titleBottomPadding: 40,
        compactHeightTitleTopPadding: 0,
        menuSpacing: 24,
        buttonSpacing: 24,
        buttonFontSize: 18,
        contentPadding: 16,
        allowsDynamicType: true
    )

    /// Top padding for the title, matching the total gap between title and buttons (titleBottomPadding + menuSpacing).
    public var titleTopPadding: CGFloat { titleBottomPadding + menuSpacing }

    public func titleTopPadding(verticalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        guard verticalSizeClass == .compact, let compactHeightTitleTopPadding else {
            return titleTopPadding
        }

        return compactHeightTitleTopPadding
    }

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
    public let hudTextStyle: Font.TextStyle
    public let friendHUDTextStyle: Font.TextStyle
    public let pauseButtonFontSize: CGFloat
    public let lifeIconSize: CGFloat
    public let friendLifeIconSize: CGFloat
    public let headerPadding: CGFloat

    public init(
        hudFontSize: CGFloat,
        hudTextStyle: Font.TextStyle,
        friendHUDTextStyle: Font.TextStyle,
        pauseButtonFontSize: CGFloat,
        lifeIconSize: CGFloat,
        friendLifeIconSize: CGFloat,
        headerPadding: CGFloat
    ) {
        self.hudFontSize = hudFontSize
        self.hudTextStyle = hudTextStyle
        self.friendHUDTextStyle = friendHUDTextStyle
        self.pauseButtonFontSize = pauseButtonFontSize
        self.lifeIconSize = lifeIconSize
        self.friendLifeIconSize = friendLifeIconSize
        self.headerPadding = headerPadding
    }

    public static let universal = GameViewStyle(
        hudFontSize: 28,
        hudTextStyle: .title,
        friendHUDTextStyle: .title2,
        pauseButtonFontSize: 16,
        lifeIconSize: 28,
        friendLifeIconSize: 22,
        headerPadding: 16
    )
    public static let tvOS = GameViewStyle(
        hudFontSize: 28,
        hudTextStyle: .title,
        friendHUDTextStyle: .title2,
        pauseButtonFontSize: 22,
        lifeIconSize: 28,
        friendLifeIconSize: 22,
        headerPadding: 60
    )
}

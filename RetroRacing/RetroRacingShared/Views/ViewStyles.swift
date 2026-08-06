//
//  ViewStyles.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI

public enum MenuUtilityActionPlacement: Equatable {
    case toolbar
    case content
}

public enum MenuDestinationPresentation: Equatable {
    case sheet
    case navigation
}

public struct MenuViewStyle {
    public let titleFontSize: CGFloat
    public let titleBottomPadding: CGFloat
    public let compactHeightTitleTopPadding: CGFloat?
    public let menuSpacing: CGFloat
    public let buttonSpacing: CGFloat
    public let buttonFontSize: CGFloat
    public let contentPadding: CGFloat?
    public let allowsDynamicType: Bool
    public let showsHelpAction: Bool
    public let utilityActionPlacement: MenuUtilityActionPlacement
    public let destinationPresentation: MenuDestinationPresentation
    public let utilityActionFontSize: CGFloat
    public let utilityActionPadding: CGFloat

    public init(
        titleFontSize: CGFloat,
        titleBottomPadding: CGFloat,
        compactHeightTitleTopPadding: CGFloat? = nil,
        menuSpacing: CGFloat,
        buttonSpacing: CGFloat,
        buttonFontSize: CGFloat,
        contentPadding: CGFloat?,
        allowsDynamicType: Bool,
        showsHelpAction: Bool,
        utilityActionPlacement: MenuUtilityActionPlacement = .toolbar,
        destinationPresentation: MenuDestinationPresentation = .sheet,
        utilityActionFontSize: CGFloat = 18,
        utilityActionPadding: CGFloat = 16
    ) {
        self.titleFontSize = titleFontSize
        self.titleBottomPadding = titleBottomPadding
        self.compactHeightTitleTopPadding = compactHeightTitleTopPadding
        self.menuSpacing = menuSpacing
        self.buttonSpacing = buttonSpacing
        self.buttonFontSize = buttonFontSize
        self.contentPadding = contentPadding
        self.allowsDynamicType = allowsDynamicType
        self.showsHelpAction = showsHelpAction
        self.utilityActionPlacement = utilityActionPlacement
        self.destinationPresentation = destinationPresentation
        self.utilityActionFontSize = utilityActionFontSize
        self.utilityActionPadding = utilityActionPadding
    }

    public static let universal = MenuViewStyle(
        titleFontSize: 27,
        titleBottomPadding: 40,
        compactHeightTitleTopPadding: 0,
        menuSpacing: 24,
        buttonSpacing: 24,
        buttonFontSize: 18,
        contentPadding: 16,
        allowsDynamicType: true,
        showsHelpAction: false
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
        allowsDynamicType: false,
        showsHelpAction: true,
        utilityActionPlacement: .content,
        destinationPresentation: .navigation,
        utilityActionFontSize: 22,
        utilityActionPadding: 48
    )
}

public enum SettingsViewLayout: Equatable {
    case sections
    case categories
}

public struct SettingsViewStyle {
    public let labelFontSize: CGFloat
    public let layout: SettingsViewLayout
    public let presentation: NavigationSurfacePresentation
    public let showsDirectTouch: Bool

    public init(
        labelFontSize: CGFloat,
        layout: SettingsViewLayout = .sections,
        presentation: NavigationSurfacePresentation = .modal,
        showsDirectTouch: Bool = true
    ) {
        self.labelFontSize = labelFontSize
        self.layout = layout
        self.presentation = presentation
        self.showsDirectTouch = showsDirectTouch
    }

    public static let universal = SettingsViewStyle(labelFontSize: 14)
    public static let tvOS = SettingsViewStyle(
        labelFontSize: 18,
        layout: .categories,
        presentation: .navigationDestination,
        showsDirectTouch: false
    )
}

public struct GameViewStyle {
    public let hudFontSize: CGFloat
    public let hudTextStyle: Font.TextStyle
    public let friendHUDTextStyle: Font.TextStyle
    public let pauseButtonFontSize: CGFloat
    public let lifeIconSize: CGFloat
    public let friendLifeIconSize: CGFloat
    public let headerPadding: CGFloat
    public let compactSideRailWidth: CGFloat
    public let showsGameplayToolbarControls: Bool
    public let usesFixedHUDMetrics: Bool
    public let preservesVerticalSafeAreaMargins: Bool

    public init(
        hudFontSize: CGFloat,
        hudTextStyle: Font.TextStyle,
        friendHUDTextStyle: Font.TextStyle,
        pauseButtonFontSize: CGFloat,
        lifeIconSize: CGFloat,
        friendLifeIconSize: CGFloat,
        headerPadding: CGFloat,
        compactSideRailWidth: CGFloat,
        showsGameplayToolbarControls: Bool,
        usesFixedHUDMetrics: Bool,
        preservesVerticalSafeAreaMargins: Bool = false
    ) {
        self.hudFontSize = hudFontSize
        self.hudTextStyle = hudTextStyle
        self.friendHUDTextStyle = friendHUDTextStyle
        self.pauseButtonFontSize = pauseButtonFontSize
        self.lifeIconSize = lifeIconSize
        self.friendLifeIconSize = friendLifeIconSize
        self.headerPadding = headerPadding
        self.compactSideRailWidth = compactSideRailWidth
        self.showsGameplayToolbarControls = showsGameplayToolbarControls
        self.usesFixedHUDMetrics = usesFixedHUDMetrics
        self.preservesVerticalSafeAreaMargins = preservesVerticalSafeAreaMargins
    }

    public static let universal = GameViewStyle(
        hudFontSize: 28,
        hudTextStyle: .title,
        friendHUDTextStyle: .title2,
        pauseButtonFontSize: 16,
        lifeIconSize: 28,
        friendLifeIconSize: 22,
        headerPadding: 16,
        compactSideRailWidth: 160,
        showsGameplayToolbarControls: true,
        usesFixedHUDMetrics: false
    )
    public static let tvOS = GameViewStyle(
        hudFontSize: 44,
        hudTextStyle: .largeTitle,
        friendHUDTextStyle: .largeTitle,
        pauseButtonFontSize: 22,
        lifeIconSize: 56,
        friendLifeIconSize: 44,
        headerPadding: 60,
        compactSideRailWidth: 300,
        showsGameplayToolbarControls: false,
        usesFixedHUDMetrics: true,
        preservesVerticalSafeAreaMargins: true
    )
}

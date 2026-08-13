//
//  ViewStyles.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI

enum MenuLayoutPolicy {
    static let isScrollingEnabled = true
    static let titleTextStyle: Font.TextStyle = .title

    static func usesVerticalUtilityActions(for dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }
}

public enum MenuUtilityActionPlacement: Equatable {
    case toolbar
    case content
}

public enum MenuDestinationPresentation: Equatable {
    case sheet
    case navigation
}

public struct MenuViewStyle {
    public let titleBottomPadding: CGFloat
    public let compactHeightTitleTopPadding: CGFloat?
    public let menuSpacing: CGFloat
    public let buttonSpacing: CGFloat
    public let contentPadding: CGFloat?
    public let showsHelpAction: Bool
    public let utilityActionPlacement: MenuUtilityActionPlacement
    public let destinationPresentation: MenuDestinationPresentation
    public let utilityActionPadding: CGFloat

    public init(
        titleBottomPadding: CGFloat,
        compactHeightTitleTopPadding: CGFloat? = nil,
        menuSpacing: CGFloat,
        buttonSpacing: CGFloat,
        contentPadding: CGFloat?,
        showsHelpAction: Bool,
        utilityActionPlacement: MenuUtilityActionPlacement = .toolbar,
        destinationPresentation: MenuDestinationPresentation = .sheet,
        utilityActionPadding: CGFloat = 16
    ) {
        self.titleBottomPadding = titleBottomPadding
        self.compactHeightTitleTopPadding = compactHeightTitleTopPadding
        self.menuSpacing = menuSpacing
        self.buttonSpacing = buttonSpacing
        self.contentPadding = contentPadding
        self.showsHelpAction = showsHelpAction
        self.utilityActionPlacement = utilityActionPlacement
        self.destinationPresentation = destinationPresentation
        self.utilityActionPadding = utilityActionPadding
    }

    public static let universal = MenuViewStyle(
        titleBottomPadding: 40,
        compactHeightTitleTopPadding: 0,
        menuSpacing: 24,
        buttonSpacing: 24,
        contentPadding: 16,
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
        titleBottomPadding: 60,
        menuSpacing: 40,
        buttonSpacing: 40,
        contentPadding: nil,
        showsHelpAction: true,
        utilityActionPlacement: .content,
        destinationPresentation: .navigation,
        utilityActionPadding: 48
    )
}

public enum SettingsViewLayout: Equatable {
    case sections
    case categories
}

public struct SettingsViewStyle {
    public let layout: SettingsViewLayout
    public let presentation: NavigationSurfacePresentation
    public let showsDirectTouch: Bool

    public init(
        layout: SettingsViewLayout = .sections,
        presentation: NavigationSurfacePresentation = .modal,
        showsDirectTouch: Bool = true
    ) {
        self.layout = layout
        self.presentation = presentation
        self.showsDirectTouch = showsDirectTouch
    }

    public static let universal = SettingsViewStyle()
    public static let tvOS = SettingsViewStyle(
        layout: .categories,
        presentation: .navigationDestination,
        showsDirectTouch: false
    )
}

public struct GameViewStyle {
    public let hudTextStyle: Font.TextStyle
    public let friendHUDTextStyle: Font.TextStyle
    public let lifeIconSize: CGFloat
    public let friendLifeIconSize: CGFloat
    public let headerPadding: CGFloat
    public let compactSideRailWidth: CGFloat
    public let showsGameplayToolbarControls: Bool
    public let preservesVerticalSafeAreaMargins: Bool

    public init(
        hudTextStyle: Font.TextStyle,
        friendHUDTextStyle: Font.TextStyle,
        lifeIconSize: CGFloat,
        friendLifeIconSize: CGFloat,
        headerPadding: CGFloat,
        compactSideRailWidth: CGFloat,
        showsGameplayToolbarControls: Bool,
        preservesVerticalSafeAreaMargins: Bool = false
    ) {
        self.hudTextStyle = hudTextStyle
        self.friendHUDTextStyle = friendHUDTextStyle
        self.lifeIconSize = lifeIconSize
        self.friendLifeIconSize = friendLifeIconSize
        self.headerPadding = headerPadding
        self.compactSideRailWidth = compactSideRailWidth
        self.showsGameplayToolbarControls = showsGameplayToolbarControls
        self.preservesVerticalSafeAreaMargins = preservesVerticalSafeAreaMargins
    }

    public static let universal = GameViewStyle(
        hudTextStyle: .title,
        friendHUDTextStyle: .title2,
        lifeIconSize: 28,
        friendLifeIconSize: 22,
        headerPadding: 16,
        compactSideRailWidth: 160,
        showsGameplayToolbarControls: true
    )
    public static let tvOS = GameViewStyle(
        hudTextStyle: .title,
        friendHUDTextStyle: .title2,
        lifeIconSize: 56,
        friendLifeIconSize: 44,
        headerPadding: 60,
        compactSideRailWidth: 300,
        showsGameplayToolbarControls: false,
        preservesVerticalSafeAreaMargins: true
    )
}

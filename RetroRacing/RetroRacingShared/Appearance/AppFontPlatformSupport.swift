//
//  AppFontPlatformSupport.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import SwiftUI

#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum AppFontPlatformSupport {
    static func defaultPointSize(for textStyle: Font.TextStyle) -> CGFloat {
        #if canImport(UIKit) && !os(watchOS)
        let baselineTraits = UITraitCollection(preferredContentSizeCategory: .large)
        return UIFont.preferredFont(
            forTextStyle: uiTextStyle(for: textStyle),
            compatibleWith: baselineTraits
        ).pointSize
        #elseif canImport(AppKit)
        return NSFont.preferredFont(forTextStyle: nsTextStyle(for: textStyle), options: [:]).pointSize
        #else
        return fallbackPointSize(for: textStyle)
        #endif
    }

    #if canImport(UIKit) && !os(watchOS)
    private static func uiTextStyle(for textStyle: Font.TextStyle) -> UIFont.TextStyle {
        switch textStyle {
        #if os(tvOS)
        case .extraLargeTitle, .extraLargeTitle2, .largeTitle: .title1
        #else
        case .extraLargeTitle: .extraLargeTitle
        case .extraLargeTitle2: .extraLargeTitle2
        case .largeTitle: .largeTitle
        #endif
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        @unknown default: .body
        }
    }
    #endif

    #if canImport(AppKit)
    private static func nsTextStyle(for textStyle: Font.TextStyle) -> NSFont.TextStyle {
        switch textStyle {
        case .extraLargeTitle, .extraLargeTitle2, .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        @unknown default: .body
        }
    }
    #endif

    private static func fallbackPointSize(for textStyle: Font.TextStyle) -> CGFloat {
        switch textStyle {
        case .extraLargeTitle: 44
        case .extraLargeTitle2: 36
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .subheadline: 15
        case .callout: 16
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }
}

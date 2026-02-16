//
//  InfoLinkRow.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 10/02/2026.
//

import SwiftUI

/// Reusable row used for informational links in the About screen.
///
/// The row:
/// - Shows an optional leading icon
/// - Displays a title and optional subtitle
/// - Adapts its layout for accessibility Dynamic Type sizes
/// - Presents as a link to assistive technologies
public struct InfoLinkRow: View {
    private let iconSystemName: String?
    private let iconImageName: String?
    private let title: String
    private let subtitle: String?
    private let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    /// Creates a new information row.
    /// - Parameters:
    ///   - iconSystemName: Optional SF Symbol name for the leading icon.
    ///   - iconImageName: Optional asset name for a custom leading icon.
    ///   - title: Primary text.
    ///   - subtitle: Optional secondary text shown below the title.
    ///   - action: Action invoked when the row is activated.
    public init(
        iconSystemName: String? = nil,
        iconImageName: String? = nil,
        title: String,
        subtitle: String? = nil,
        action: @escaping () -> Void
    ) {
        self.iconSystemName = iconSystemName
        self.iconImageName = iconImageName
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            AdaptiveStack {
                iconView

                VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? 0 : 2) {
                    Text(title)
                        .font(fontPreferenceStore?.font(textStyle: .body) ?? .body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(fontPreferenceStore?.font(textStyle: .caption) ?? .caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 6 : 2)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "link")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isLink)
        .accessibilityRemoveTraits(.isButton)
    }

    @ViewBuilder
    private var iconView: some View {
        if let systemName = iconSystemName {
            Image(systemName: systemName)
                .imageScale(.large)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
        } else if let imageName = iconImageName {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        List {
            InfoLinkRow(
                iconSystemName: "globe",
                title: "RetroRacing!",
                subtitle: "App information, tips, and help"
            ) {}

            InfoLinkRow(
                iconSystemName: "star.bubble.fill",
                title: "Rate RetroRacing!",
                subtitle: "Opens the rating dialog to rate the app"
            ) {}
        }
    }
}

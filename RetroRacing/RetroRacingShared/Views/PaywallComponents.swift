//
//  PaywallComponents.swift
//  RetroRacingShared
//
//  Lightweight, reusable paywall UI components inspired by Xarra.
//

import SwiftUI

// MARK: - Header

struct PaywallHeaderView: View {
    let icon: String
    let title: String
    let caption: String
    
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(title)
                .font(fontPreferenceStore?.titleFont ?? .title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(caption)
                .font(fontPreferenceStore?.captionFont ?? .caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
}

// MARK: - Card link label

/// Shared label for card links (e.g. Learn More).
struct PaywallCardLinkLabel: View {
    let title: String
    
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    var body: some View {
        HStack {
            Text(title)
            Image(systemName: "arrow.up.right")
                .font(fontPreferenceStore?.captionFont ?? .caption)
        }
        .font(fontPreferenceStore?.subheadlineFont ?? .subheadline)
    }
}

// MARK: - Info card

struct PaywallInfoCard<BodyContent: View, ActionContent: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let bodyContent: () -> BodyContent
    @ViewBuilder let actionContent: () -> ActionContent
    
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .accessibilityHidden(true)
                Text(title)
            }
            .font(fontPreferenceStore?.headlineFont ?? .headline)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            bodyContent()
                .font(fontPreferenceStore?.subheadlineFont ?? .subheadline)
                .foregroundStyle(.primary)

            actionContent()
                .padding(.top, 2)
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Error state

struct PaywallErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore

    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .font(fontPreferenceStore?.bodyFont ?? .body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Button(action: retryAction) {
                Label(GameLocalizedStrings.string("error_retry"), systemImage: "arrow.clockwise")
                    .font(fontPreferenceStore?.subheadlineFont ?? .subheadline)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .accessibilityShowsLargeContentViewer()
        }
        .padding()
    }
}

// MARK: - Rounded border

extension View {
    /// Clips to a rounded rectangle and strokes the edge with a semantic color.
    func roundedBorder<S: ShapeStyle>(_ content: S, lineWidth: CGFloat = 1, cornerRadius: CGFloat = 12) -> some View {
        clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(content, lineWidth: lineWidth))
    }
}


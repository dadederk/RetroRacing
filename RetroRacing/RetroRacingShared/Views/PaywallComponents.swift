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
    var caption: String? = nil
    var profileImageName: String? = nil
    var profileImageAccessibilityLabel: String? = nil

    @ScaledMetric(relativeTo: .largeTitle) private var profileImageSize: CGFloat = 80

    private let sharedBundle = Bundle(for: GameScene.self)

    private var profileImageBundle: Bundle {
        #if os(visionOS)
        .main
        #else
        sharedBundle
        #endif
    }

    var body: some View {
        VStack(spacing: 12) {
            headerIcon

            Text(title)
                .appFont(.title, weightTier: .bold)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            if let caption {
                Text(caption)
                    .appFont(.caption)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private var headerIcon: some View {
        if let profileImageName {
            Image(profileImageName, bundle: profileImageBundle)
                .resizable()
                .scaledToFit()
                .frame(width: profileImageSize, height: profileImageSize)
                .clipShape(Circle())
                .accessibilityLabel(profileImageAccessibilityLabel.map(Text.init) ?? Text(verbatim: ""))
                .accessibilityHidden(profileImageAccessibilityLabel == nil)
        } else {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Card link label

/// Shared label for card links (e.g. Learn More).
struct PaywallCardLinkLabel: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
            Image(systemName: "arrow.up.right")
                .appFont(.caption)
        }
        .appFont(.subheadline)
    }
}

// MARK: - Info card

struct PaywallInfoCard<BodyContent: View, ActionContent: View>: View {
    let title: String
    let icon: String
    var treatsTitleAsAccessibilityHeader: Bool = true
    @ViewBuilder let bodyContent: () -> BodyContent
    @ViewBuilder let actionContent: () -> ActionContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .accessibilityHidden(true)
                Text(title)
            }
            .appFont(.headline)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(treatsTitleAsAccessibilityHeader ? .isHeader : [])

            bodyContent()
                .appFont(.subheadline)
                .foregroundStyle(.primary)

            actionContent()
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Error state

struct PaywallErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .appFont(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Button(action: retryAction) {
                Label(GameLocalizedStrings.string("error_retry"), systemImage: "arrow.clockwise")
                    .appFont(.subheadline)
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

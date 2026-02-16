//
//  AboutView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 10/02/2026.
//

import SwiftUI

// MARK: - URLs

private enum AboutViewURLs {
    static let app = URL(string: "https://accessibilityupto11.com/apps/retroracing/")
    static let blog = URL(string: "https://accessibilityupto11.com/")
    static let twitter = URL(string: "https://twitter.com/dadederk")
    static let mastodon = URL(string: "https://iosdev.space/@dadederk")
    static let bluesky = URL(string: "https://bsky.app/profile/dadederk.bsky.social")
    static let linkedin = URL(string: "https://www.linkedin.com/in/danieldevesa/")
    static let ammec = URL(string: "https://www.ammec.es/")
    static let swiftForSwifts = URL(string: "https://www.swiftforswifts.org")
    static let pressStartFont = URL(string: "https://fonts.google.com/specimen/Press+Start+2P")
    static let helm = URL(string: "https://helm-app.com")
}

// MARK: - URL wrapper for sheet presentation
private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// About screen: app info, rate, social links, giving back, credits, and footer.
public struct AboutView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore
    #if os(iOS)
    @State private var safariURL: IdentifiableURL?
    #endif

    public var body: some View {
        List {
            appSection
            rateSection
            connectSection
            givingBackSection
            alsoSupportingSection
            creditsSection
            footerSection
        }
        .navigationTitle(GameLocalizedStrings.string("about_title"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $safariURL) { item in
            SafariView(url: item.url)
        }
        #endif
    }

    private var appSection: some View {
        Section {
            if let url = AboutViewURLs.app {
                linkRow(
                    icon: "globe",
                    title: GameLocalizedStrings.string("about_app_title"),
                    subtitle: GameLocalizedStrings.string("about_app_subtitle"),
                    url: url
                )
            }
        }
    }

    private var rateSection: some View {
        Section {
            Button {
                openAppStoreReviewPage()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "star.bubble.fill")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text(GameLocalizedStrings.string("about_rate_title"))
                        .font(fontPreferenceStore?.font(textStyle: .body) ?? .body)
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(GameLocalizedStrings.string("about_rate_hint"))
        }
    }

    private var connectSection: some View {
        Section {
            if let url = AboutViewURLs.blog {
                linkRow(icon: "globe", title: GameLocalizedStrings.string("about_link_blog"), url: url)
            }
            if let url = AboutViewURLs.twitter {
                linkRow(icon: "x.circle.fill", title: GameLocalizedStrings.string("about_link_twitter"), url: url)
            }
            if let url = AboutViewURLs.mastodon {
                linkRow(icon: "magnifyingglass", title: GameLocalizedStrings.string("about_link_mastodon"), url: url)
            }
            if let url = AboutViewURLs.bluesky {
                linkRow(icon: "cloud.fill", title: GameLocalizedStrings.string("about_link_bluesky"), url: url)
            }
            if let url = AboutViewURLs.linkedin {
                linkRow(icon: "person.2.fill", title: GameLocalizedStrings.string("about_link_linkedin"), url: url)
            }
        } header: {
            Text(GameLocalizedStrings.string("about_connect_header"))
                .font(fontPreferenceStore?.font(textStyle: .headline) ?? .headline)
        }
    }

    private var givingBackSection: some View {
        Section {
            if let url = AboutViewURLs.ammec {
                linkRow(icon: "heart.circle.fill", title: GameLocalizedStrings.string("about_ammec_title"), url: url)
            }
        } header: {
            Text(GameLocalizedStrings.string("about_giving_back_header"))
                .font(fontPreferenceStore?.font(textStyle: .headline) ?? .headline)
        } footer: {
            Text(GameLocalizedStrings.string("about_ammec_footer"))
                .font(fontPreferenceStore?.font(textStyle: .subheadline) ?? .subheadline)
        }
    }

    private var alsoSupportingSection: some View {
        Section {
            if let url = AboutViewURLs.swiftForSwifts {
                linkRow(icon: "bird.fill", title: GameLocalizedStrings.string("about_swift_for_swifts_title"), url: url)
            }
        } header: {
            Text(GameLocalizedStrings.string("about_also_supporting_header"))
                .font(fontPreferenceStore?.font(textStyle: .headline) ?? .headline)
        }
    }

    private var creditsSection: some View {
        Section {
            if let url = AboutViewURLs.pressStartFont {
                linkRow(
                    icon: "textformat",
                    title: GameLocalizedStrings.string("about_font_press_start"),
                    subtitle: GameLocalizedStrings.string("about_font_license"),
                    url: url
                )
            }
            if let url = AboutViewURLs.helm {
                linkRow(
                    icon: "helm",
                    title: GameLocalizedStrings.string("about_helm_title"),
                    subtitle: GameLocalizedStrings.string("about_helm_subtitle"),
                    url: url
                )
            }
        } header: {
            Text(GameLocalizedStrings.string("about_credits_header"))
                .font(fontPreferenceStore?.font(textStyle: .headline) ?? .headline)
        }
    }

    private var footerSection: some View {
        Section {
            VStack(spacing: 4) {
                Text(GameLocalizedStrings.string("about_footer_love"))
                Text(GameLocalizedStrings.string("about_footer_location"))
                Text(GameLocalizedStrings.string("about_footer_thanks"))
            }
            .frame(maxWidth: .infinity)
            .font(fontPreferenceStore?.font(textStyle: .caption) ?? .caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        }
    }

    private func linkRow(icon: String, title: String, subtitle: String? = nil, url: URL) -> some View {
        InfoLinkRow(iconSystemName: icon, title: title, subtitle: subtitle) {
            openLink(url)
        }
    }

    private func openLink(_ url: URL) {
        #if os(iOS)
        safariURL = IdentifiableURL(url: url)
        #else
        openURL(url)
        #endif
    }

    private func openAppStoreReviewPage() {
        guard let reviewURL = AppStoreReviewURL.writeReview else { return }
        openURL(reviewURL)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}

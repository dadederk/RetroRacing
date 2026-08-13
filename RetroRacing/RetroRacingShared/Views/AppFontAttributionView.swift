//
//  AppFontAttributionView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import SwiftUI

struct AppFontAttributionView: View {
    let attribution: AppFontAttribution

    @Environment(\.appTypography) private var currentTypography

    var body: some View {
        List {
            Section(GameLocalizedStrings.string("font_attribution_sample_header")) {
                Text(GameLocalizedStrings.string("font_attribution_sample_text"))
                    .appFont(.body)
                    .appTypography(previewTypography)
            }

            Section(GameLocalizedStrings.string("font_attribution_useful_for_header")) {
                Text(attribution.description)
                    .appFont(.body)
                    .foregroundStyle(.secondary)
            }

            Section(GameLocalizedStrings.string("font_attribution_sources_header")) {
                if let url = attribution.officialWebsiteURL {
                    Link(destination: url) {
                        Label(
                            GameLocalizedStrings.string("font_attribution_official_website"),
                            systemImage: "globe"
                        )
                        .appFont(.body)
                    }
                }
                if let url = attribution.licenseSourceURL {
                    Link(destination: url) {
                        Label(
                            GameLocalizedStrings.string("font_attribution_license_source"),
                            systemImage: "doc.text"
                        )
                        .appFont(.body)
                    }
                }
            }

            Section(GameLocalizedStrings.string("font_attribution_license_header")) {
                Text(GameLocalizedStrings.string("about_font_license"))
                    .appFont(.body)
                Text(attribution.copyrightNotice)
                    .appFont(.caption)
                    .foregroundStyle(.secondary)
                NavigationLink(GameLocalizedStrings.string("font_attribution_view_full_license")) {
                    AppFontLicenseTextView(attribution: attribution)
                }
                .appFont(.body)
            }
        }
        .navigationTitle(attribution.title)
    }

    private var previewTypography: AppTypography {
        AppTypography(
            selectedStyle: attribution.style,
            availability: currentTypography.availability
        )
    }
}

private struct AppFontLicenseTextView: View {
    let attribution: AppFontAttribution

    var body: some View {
        Group {
            #if os(watchOS) || os(tvOS)
            licenseContent
            #else
            licenseContent.textSelection(.enabled)
            #endif
        }
        .navigationTitle(GameLocalizedStrings.string("font_attribution_license_title"))
    }

    private var licenseContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(GameLocalizedStrings.string("about_font_license"))
                    .appFont(.body)
                Text(attribution.copyrightNotice)
                    .appFont(.footnote)
                    .foregroundStyle(.secondary)
                Text(AppFontLicenseTextProvider.silOpenFontLicenseText)
                    .appFont(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

//
//  AppFontAttribution.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import Foundation

struct AppFontAttribution: Identifiable, Equatable {
    let style: AppFontStyle
    let descriptionKey: String
    let officialWebsiteURL: URL?
    let licenseSourceURL: URL?
    let copyrightNotice: String

    var id: String { style.rawValue }
    var title: String { style.localizedName }
    var description: String { GameLocalizedStrings.string(descriptionKey) }

    static let all: [AppFontAttribution] = [
        AppFontAttribution(
            style: .custom,
            descriptionKey: "font_attribution_press_start_description",
            officialWebsiteURL: ExternalLinks.pressStart2P,
            licenseSourceURL: ExternalLinks.pressStart2PLicense,
            copyrightNotice: "Copyright 2012 The Press Start 2P Project Authors (cody@zone38.net), with Reserved Font Name \"Press Start 2P\"."
        ),
        AppFontAttribution(
            style: .openDyslexic,
            descriptionKey: "font_attribution_open_dyslexic_description",
            officialWebsiteURL: ExternalLinks.openDyslexic,
            licenseSourceURL: ExternalLinks.openDyslexicLicense,
            copyrightNotice: "Copyright (c) 2019-07-29, Abbie Gonzalez (https://abbiecod.es|support@abbiecod.es), with Reserved Font Name OpenDyslexic. Copyright (c) 12/2012 - 2019."
        ),
        AppFontAttribution(
            style: .atkinsonHyperlegible,
            descriptionKey: "font_attribution_atkinson_description",
            officialWebsiteURL: ExternalLinks.atkinsonHyperlegible,
            licenseSourceURL: ExternalLinks.atkinsonHyperlegibleLicense,
            copyrightNotice: "Copyright 2020-2024 The Atkinson Hyperlegible Next Project Authors."
        ),
        AppFontAttribution(
            style: .lexend,
            descriptionKey: "font_attribution_lexend_description",
            officialWebsiteURL: ExternalLinks.lexend,
            licenseSourceURL: ExternalLinks.lexendLicense,
            copyrightNotice: "Copyright 2018 The Lexend Project Authors, with Reserved Font Name \"RevReading Lexend\"."
        )
    ]
}

enum AppFontLicenseTextProvider {
    static let silOpenFontLicenseText: String = licenseBody(from: loadLicenseText())

    static func licenseBody(from text: String) -> String {
        if let headingRange = text.range(of: "SIL OPEN FONT LICENSE") {
            return String(text[headingRange.lowerBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func loadLicenseText() -> String {
        let bundles = [Bundle(for: GameScene.self), Bundle.main] + Bundle.allFrameworks
        for bundle in bundles {
            if let text = loadText(in: bundle) {
                return text
            }
        }

        AppLog.warning(
            AppLog.font,
            "FONT_LICENSE_RESOURCE",
            outcome: .failed,
            fields: [.reason("file_unreachable"), .string("file", "OFL-1.1.txt")]
        )
        return GameLocalizedStrings.string("font_license_unavailable")
    }

    private static func loadText(in bundle: Bundle) -> String? {
        let candidates = [
            bundle.url(forResource: "OFL-1.1", withExtension: "txt"),
            bundle.url(forResource: "OFL-1.1", withExtension: "txt", subdirectory: "Licenses"),
            bundle.url(
                forResource: "OFL-1.1",
                withExtension: "txt",
                subdirectory: "Resources/Licenses"
            )
        ]

        for url in candidates.compactMap({ $0 }) {
            if let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty {
                return text
            }
        }
        return nil
    }
}

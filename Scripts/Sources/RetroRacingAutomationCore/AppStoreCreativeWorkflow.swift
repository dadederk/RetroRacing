//
//  AppStoreCreativeWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 18/10/2026.
//

import AppKit
import Foundation
import ScriptSupport

public enum AppStoreCreativeMode: Sendable {
    case write
    case check
    case dryRun
}

public struct AppStoreCreativeHeadlineLayout: Equatable, Sendable {
    public let lines: [String]
    public let fontSize: Int

    public static func plan(
        text: String,
        locale: String,
        initialSize: Int = 270,
        maxWidth: CGFloat = 2_050,
        maxLines: Int = 3
    ) throws -> Self {
        for size in stride(from: initialSize, through: 220, by: -2) {
            let font = AppStoreCreativeTypography.font(locale: locale, size: size)
            let lines = balancedLines(text, font: font, maxWidth: maxWidth)
            if lines.count <= maxLines {
                return Self(lines: lines, fontSize: size)
            }
        }
        throw AppStoreCreativeError.copyDoesNotFit(text)
    }

    private static func balancedLines(
        _ text: String,
        font: NSFont,
        maxWidth: CGFloat
    ) -> [String] {
        func width(_ value: String) -> CGFloat {
            (value as NSString).size(withAttributes: [.font: font]).width
        }

        if width(text) <= maxWidth {
            return [text]
        }

        let splitCandidates: [(String, String)]
        if text.contains(" ") {
            let words = text.split(separator: " ").map(String.init)
            splitCandidates = words.indices.dropFirst().map { index in
                (
                    words[..<index].joined(separator: " "),
                    words[index...].joined(separator: " ")
                )
            }
        } else {
            splitCandidates = text.indices.dropFirst().compactMap { index in
                guard !"。、，！？」".contains(text[index]) else { return nil }
                return (String(text[..<index]), String(text[index...]))
            }
        }

        let fitting = splitCandidates.compactMap { first, second -> (CGFloat, [String])? in
            let firstWidth = width(first)
            let secondWidth = width(second)
            guard firstWidth <= maxWidth, secondWidth <= maxWidth else { return nil }
            return (abs(firstWidth - secondWidth), [first, second])
        }
        if let best = fitting.min(by: { $0.0 < $1.0 }) {
            return best.1
        }

        let units = text.contains(" ")
            ? text.split(separator: " ").map(String.init)
            : text.map(String.init)
        let separator = text.contains(" ") ? " " : ""
        var lines: [String] = []
        var line = ""
        for unit in units {
            let candidate = line.isEmpty ? unit : line + separator + unit
            if !line.isEmpty, width(candidate) > maxWidth {
                lines.append(line)
                line = unit
            } else {
                line = candidate
            }
        }
        if !line.isEmpty {
            lines.append(line)
        }
        return lines
    }
}

public struct HelmCreativeAssetManifest: Codable, Equatable, Sendable {
    public struct Asset: Codable, Equatable, Sendable {
        public let locale: String
        public let kind: String
        public let path: String
        public let localizationStatus: String
    }

    public let schemaVersion: Int
    public let copySource: String
    public let headerLocalization: String
    public let assets: [Asset]
}

public enum AppStoreCreativeError: LocalizedError {
    case missingImage(String)
    case invalidSource(String)
    case copyDoesNotFit(String)
    case renderingFailed
    case stale([String])

    public var errorDescription: String? {
        switch self {
        case .missingImage(let path):
            "Missing App Store creative source image: \(path)"
        case .invalidSource(let message):
            message
        case .copyDoesNotFit(let copy):
            "Localized search creative copy does not fit: \(copy)"
        case .renderingFailed:
            "Could not render an App Store creative asset."
        case .stale(let paths):
            "App Store creative assets are missing or stale: \(paths.joined(separator: ", "))"
        }
    }
}

public enum AppStoreCreativeWorkflow {
    public static let headerRelativePath =
        "AppStore/creative-assets/product-page-header-coastal.png"
    public static let manifestRelativePath =
        "AppStore/creative-assets/helm-creative-assets.json"
    public static let contactSheetRelativePath =
        "AppStore/creative-assets/review/search-results-localizations-contact.jpg"

    private static let designCanvas = NSSize(width: 3_840, height: 2_560)
    private static let outputCanvas = NSSize(width: 1_920, height: 1_280)
    private static let outputScale: CGFloat = 0.5
    private static let cream = NSColor(
        calibratedRed: 1, green: 242 / 255, blue: 210 / 255, alpha: 1
    )
    private static let outline = NSColor(
        calibratedRed: 22 / 255, green: 11 / 255, blue: 60 / 255, alpha: 1
    )

    public static func run(repositoryRoot: URL, mode: AppStoreCreativeMode) throws {
        let files = try generatedFiles(repositoryRoot: repositoryRoot)
        switch mode {
        case .write:
            try FileWork.writeAtomically(files)
            print("Generated localized App Store creative for \(ScreenshotStudioWorkflow.locales.count) locales.")
        case .check:
            let stale = FileWork.staleFiles(among: files, relativeTo: repositoryRoot)
            guard stale.isEmpty else {
                throw AppStoreCreativeError.stale(stale)
            }
            print("Localized App Store creative and Helm manifest are current.")
        case .dryRun:
            print("Would generate \(files.count) App Store creative files:")
            for file in files {
                print("  \(FileWork.relativePath(for: file.url, from: repositoryRoot))")
            }
        }
    }

    public static func uploadManifest(
        repositoryRoot: URL
    ) throws -> HelmCreativeAssetManifest {
        let reviewManifest = try LocalizationReviewManifest.load(
            from: repositoryRoot.appending(path: LocalizationReviewCollector.manifestRelativePath)
        )
        guard Set(reviewManifest.locales.keys) == Set(ScreenshotStudioWorkflow.locales) else {
            throw AppStoreCreativeError.invalidSource(
                "Creative locales must exactly match the localisation review manifest."
            )
        }
        let assets = try ScreenshotStudioWorkflow.locales.flatMap { locale in
            guard let review = reviewManifest.locales[locale] else {
                throw AppStoreCreativeError.invalidSource(
                    "Missing localisation review status for \(locale)."
                )
            }
            let status = review.status.rawValue
            return [
                HelmCreativeAssetManifest.Asset(
                    locale: locale,
                    kind: "header",
                    path: headerRelativePath,
                    localizationStatus: status
                ),
                HelmCreativeAssetManifest.Asset(
                    locale: locale,
                    kind: "search-results",
                    path: searchResultRelativePath(locale: locale),
                    localizationStatus: status
                ),
            ]
        }
        return HelmCreativeAssetManifest(
            schemaVersion: 1,
            copySource: "ScreenshotStudioWorkflow.slide[0].title",
            headerLocalization: "Universal artwork; only the RetroRapid! brand mark appears.",
            assets: assets
        )
    }

    public static func searchResultRelativePath(locale: String) -> String {
        "AppStore/creative-assets/localizations/\(locale)/search-results.png"
    }

    private static func generatedFiles(repositoryRoot: URL) throws -> [GeneratedFile] {
        let background = try image(
            at: repositoryRoot.appending(
                path: "AppStore/creative-assets/sources/search-results-controller-background-v1.png"
            )
        )
        let wordmark = try image(
            at: repositoryRoot.appending(
                path: "AppStore/product-page-header-concepts/sources/retrorapid-title-cartridge.png"
            )
        )
        let entries = try ScreenshotStudioWorkflow.localizationEntries(
            slideIndex: 0,
            watchSequenceOnly: false
        )
        let localizedTitles = Dictionary(
            uniqueKeysWithValues: try entries.map { entry in
                guard let locale = entry["language"], let title = entry["title"] else {
                    throw AppStoreCreativeError.invalidSource(
                        "Screenshot Studio opening copy is incomplete."
                    )
                }
                return (locale, title)
            }
        )
        guard Set(localizedTitles.keys) == Set(ScreenshotStudioWorkflow.locales) else {
            throw AppStoreCreativeError.invalidSource(
                "Screenshot Studio opening copy must cover every creative locale."
            )
        }

        var searchFiles: [GeneratedFile] = []
        for locale in ScreenshotStudioWorkflow.locales {
            guard let title = localizedTitles[locale] else {
                throw AppStoreCreativeError.invalidSource("Missing creative title for \(locale).")
            }
            let capture = try image(
                at: repositoryRoot.appending(
                    path: "AppStore/RetroRapid.screenshotstudio/iphone/images/\(locale)_5.jpeg"
                )
            )
            let rendered = try renderSearchResult(
                background: background,
                wordmark: wordmark,
                capture: capture,
                locale: locale,
                title: title
            )
            searchFiles.append(
                GeneratedFile(
                    url: repositoryRoot.appending(path: searchResultRelativePath(locale: locale)),
                    data: try rendered.png(opaque: true)
                )
            )
        }

        let manifest = try uploadManifest(repositoryRoot: repositoryRoot)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var manifestData = try encoder.encode(manifest)
        manifestData.append(contentsOf: Data("\n".utf8))
        let contactSheet = try renderContactSheet(files: searchFiles)
        return searchFiles + [
            GeneratedFile(
                url: repositoryRoot.appending(path: manifestRelativePath),
                data: manifestData
            ),
            GeneratedFile(
                url: repositoryRoot.appending(path: contactSheetRelativePath),
                data: try contactSheet.jpeg()
            ),
        ]
    }

    private static func renderSearchResult(
        background: NSImage,
        wordmark: NSImage,
        capture: NSImage,
        locale: String,
        title: String
    ) throws -> AppStoreRenderedImage {
        let rendered = try AppStoreCreativeRaster.bitmap(size: outputCanvas)
        try AppStoreCreativeRaster.withGraphics(rendered.bitmap) {
            let scale = NSAffineTransform()
            scale.scale(by: outputScale)
            scale.concat()
            background.draw(
                in: NSRect(origin: .zero, size: designCanvas),
                from: .zero,
                operation: .copy,
                fraction: 1
            )
            drawLeftVeil()
            drawPhone(capture: capture)

            let wordmarkWidth: CGFloat = 1_800
            let wordmarkSize = NSSize(
                width: wordmarkWidth,
                height: wordmark.size.height * wordmarkWidth / wordmark.size.width
            )
            wordmark.draw(in: rectFromTop(
                x: 180,
                top: 140,
                width: wordmarkSize.width,
                height: wordmarkSize.height
            ))

            let layout = try AppStoreCreativeHeadlineLayout.plan(
                text: title,
                locale: locale
            )
            try drawHeadline(layout: layout, locale: locale, x: 285, top: 790)
        }
        return rendered
    }

    private static func drawLeftVeil() {
        guard let gradient = NSGradient(
            starting: NSColor(
                calibratedRed: 23 / 255,
                green: 7 / 255,
                blue: 79 / 255,
                alpha: 0.93
            ),
            ending: NSColor(
                calibratedRed: 23 / 255,
                green: 7 / 255,
                blue: 79 / 255,
                alpha: 0
            )
        ) else {
            return
        }
        gradient.draw(in: NSRect(origin: .zero, size: designCanvas), angle: 0)
    }

    private static func drawPhone(capture: NSImage) {
        let outer = rectFromTop(x: 2_610, top: 180, width: 1_050, height: 2_200)
        outline.setFill()
        NSBezierPath(roundedRect: outer, xRadius: 138, yRadius: 138).fill()

        let screen = rectFromTop(x: 2_632, top: 202, width: 1_006, height: 2_156)
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: screen, xRadius: 116, yRadius: 116).addClip()
        let sourceHeight = min(capture.size.height, capture.size.width * screen.height / screen.width)
        capture.draw(
            in: screen,
            from: NSRect(
                x: 0,
                y: capture.size.height - sourceHeight,
                width: capture.size.width,
                height: sourceHeight
            ),
            operation: .copy,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()

        NSColor(
            calibratedRed: 5 / 255,
            green: 6 / 255,
            blue: 11 / 255,
            alpha: 1
        ).setFill()
        NSBezierPath(
            roundedRect: rectFromTop(x: 2_985, top: 225, width: 300, height: 80),
            xRadius: 40,
            yRadius: 40
        ).fill()
    }

    private static func drawHeadline(
        layout: AppStoreCreativeHeadlineLayout,
        locale: String,
        x: CGFloat,
        top: CGFloat
    ) throws {
        let font = AppStoreCreativeTypography.font(locale: locale, size: layout.fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: cream,
            .strokeColor: outline,
            .strokeWidth: -3,
        ]
        let advance = CGFloat(round(Double(layout.fontSize) * 1.04)) + 10
        for (index, line) in layout.lines.enumerated() {
            let lineSize = (line as NSString).size(withAttributes: attributes)
            (line as NSString).draw(
                at: NSPoint(
                    x: x,
                    y: designCanvas.height - top - CGFloat(index) * advance - lineSize.height
                ),
                withAttributes: attributes
            )
        }
    }

    private static func renderContactSheet(
        files: [GeneratedFile]
    ) throws -> AppStoreRenderedImage {
        let sheetSize = NSSize(width: 1_920, height: 1_160)
        let rendered = try AppStoreCreativeRaster.bitmap(size: sheetSize)
        try AppStoreCreativeRaster.withGraphics(rendered.bitmap) {
            NSColor(calibratedWhite: 0.95, alpha: 1).setFill()
            NSRect(origin: .zero, size: sheetSize).fill()
            let labelFont = NSFont.systemFont(ofSize: 18, weight: .semibold)
            for (index, locale) in ScreenshotStudioWorkflow.locales.enumerated() {
                let row = index / 5
                let column = index % 5
                let x = CGFloat(20 + column * 380)
                let top = CGFloat(18 + row * 285)
                (locale as NSString).draw(
                    at: NSPoint(x: x, y: sheetSize.height - top - 22),
                    withAttributes: [.font: labelFont, .foregroundColor: outline]
                )
                let expectedURLSuffix = searchResultRelativePath(locale: locale)
                guard let data = files.first(where: { $0.url.path.hasSuffix(expectedURLSuffix) })?.data,
                      let image = NSImage(data: data) else {
                    throw AppStoreCreativeError.missingImage(expectedURLSuffix)
                }
                image.draw(
                    in: NSRect(
                        x: x,
                        y: sheetSize.height - top - 258,
                        width: 360,
                        height: 240
                    )
                )
            }
        }
        return rendered
    }

    private static func rectFromTop(
        x: CGFloat,
        top: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) -> NSRect {
        NSRect(x: x, y: designCanvas.height - top - height, width: width, height: height)
    }

    private static func image(at url: URL) throws -> NSImage {
        guard let image = NSImage(contentsOf: url) else {
            throw AppStoreCreativeError.missingImage(url.path)
        }
        return image
    }
}

enum AppStoreCreativeTypography {
    static func font(locale: String, size: Int) -> NSFont {
        let preferredName: String
        switch locale {
        case "ja": preferredName = "HiraginoSans-W6"
        case "ko": preferredName = "AppleSDGothicNeo-Bold"
        case "zh-Hant": preferredName = "PingFangTC-Semibold"
        case "zh-Hans": preferredName = "PingFangSC-Semibold"
        default: preferredName = "SFProDisplay-Bold"
        }
        return NSFont(name: preferredName, size: CGFloat(size))
            ?? NSFont.systemFont(ofSize: CGFloat(size), weight: .bold)
    }
}

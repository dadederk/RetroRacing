//
//  ScreenshotStudioWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import ScriptSupport

public enum ScreenshotStudioMode: Sendable {
    case write
    case check
}

public enum ScreenshotStudioWorkflow {
    public static let locales = [
        "en-US", "en-GB", "en-AU", "en-CA", "es-ES", "es-MX", "ca",
    ]
    public static let slideCount = 7

    private static let englishLocales = ["en-US", "en-GB", "en-AU", "en-CA"]
    private static let platforms = ["iphone", "ipad", "mac"]
    private static let imageExtensions = [
        "iphone": ".jpeg",
        "ipad": ".jpeg",
        "mac": ".png",
        "appleWatch": ".jpeg",
    ]

    public static func run(
        repositoryRoot: URL,
        mode: ScreenshotStudioMode
    ) throws {
        let studioRoot = repositoryRoot.appending(
            path: "AppStore/RetroRapid.screenshotstudio"
        )
        guard FileManager.default.fileExists(atPath: studioRoot.path) else {
            throw ScreenshotStudioError.projectNotFound
        }

        let artifacts = try expectedArtifacts(studioRoot: studioRoot)
        switch mode {
        case .write:
            try write(artifacts)
            print("Screenshot Studio localizations synced.")
        case .check:
            let stalePaths = try stalePaths(
                artifacts,
                repositoryRoot: repositoryRoot
            )
            guard stalePaths.isEmpty else {
                throw ScreenshotStudioError.projectOutOfDate(stalePaths)
            }
            print("Screenshot Studio localizations and images are current.")
        }
    }

    public static func localizationEntries(
        slideIndex: Int,
        watchSequenceOnly: Bool
    ) -> [[String: String]] {
        locales.map { locale in
            if watchSequenceOnly, !englishLocales.contains(locale) {
                return ["language": locale, "title": "", "body": ""]
            }
            let copy = slides[slideIndex].text(for: locale)
            return [
                "language": locale,
                "title": copy.title,
                "body": copy.body,
            ]
        }
    }

    public static func contentsManifest(
        platform: String,
        slideCount: Int
    ) throws -> [String: Any] {
        guard let fileExtension = imageExtensions[platform] else {
            throw ScreenshotStudioError.unsupportedPlatform(platform)
        }
        let images = (0..<slideCount).flatMap { index in
            locales.map { locale in
                [
                    "filename": "\(locale)_\(index)\(fileExtension)",
                    "index": index,
                    "locale": locale,
                ] as [String: Any]
            }
        }
        return ["images": images]
    }

    private static func expectedArtifacts(
        studioRoot: URL
    ) throws -> [ExpectedArtifact] {
        var artifacts = [
            try expectedProjectPlist(studioRoot: studioRoot),
        ]

        for platform in platforms {
            artifacts.append(
                try expectedDataPlist(
                    platform: platform,
                    slideCount: slideCount,
                    studioRoot: studioRoot
                )
            )
            artifacts += try expectedImageArtifacts(
                platform: platform,
                slideCount: slideCount,
                studioRoot: studioRoot
            )
        }

        artifacts.append(try expectedWatchDataPlist(studioRoot: studioRoot))
        artifacts += try expectedImageArtifacts(
            platform: "appleWatch",
            slideCount: 1,
            studioRoot: studioRoot
        )
        return artifacts
    }

    private static func expectedProjectPlist(
        studioRoot: URL
    ) throws -> ExpectedArtifact {
        let url = studioRoot.appending(path: "project.plist")
        guard var project = try loadPropertyList(at: url) as? [String: Any] else {
            throw ScreenshotStudioError.invalidPropertyList(url.path)
        }
        var projectLocales = project["localizations"] as? [String] ?? []
        for locale in locales where !projectLocales.contains(locale) {
            projectLocales.append(locale)
        }
        project["localizations"] = projectLocales
        return .propertyList(url: url, value: project)
    }

    private static func expectedDataPlist(
        platform: String,
        slideCount: Int,
        studioRoot: URL
    ) throws -> ExpectedArtifact {
        let url = dataPlistURL(platform: platform, studioRoot: studioRoot)
        var platformSlides = try loadSlides(platform: platform, studioRoot: studioRoot)

        if platform != "iphone" {
            let iphoneSlides = try loadSlides(
                platform: "iphone",
                studioRoot: studioRoot
            )
            while platformSlides.count < slideCount,
                  platformSlides.count < iphoneSlides.count {
                platformSlides.append(iphoneSlides[platformSlides.count])
            }
        }

        guard platformSlides.count >= slideCount else {
            throw ScreenshotStudioError.missingSlides(
                platform: platform,
                expected: slideCount,
                actual: platformSlides.count
            )
        }

        platformSlides = Array(platformSlides.prefix(slideCount))
        for index in platformSlides.indices {
            platformSlides[index]["localizations"] = localizationEntries(
                slideIndex: index,
                watchSequenceOnly: false
            )
        }
        return .propertyList(url: url, value: platformSlides)
    }

    private static func expectedWatchDataPlist(
        studioRoot: URL
    ) throws -> ExpectedArtifact {
        let url = dataPlistURL(platform: "appleWatch", studioRoot: studioRoot)
        var watchSlides = try loadSlides(
            platform: "appleWatch",
            studioRoot: studioRoot
        )
        guard !watchSlides.isEmpty else {
            throw ScreenshotStudioError.missingSlides(
                platform: "appleWatch",
                expected: 1,
                actual: 0
            )
        }
        watchSlides[0]["localizations"] = localizationEntries(
            slideIndex: 0,
            watchSequenceOnly: true
        )
        return .propertyList(url: url, value: watchSlides)
    }

    private static func expectedImageArtifacts(
        platform: String,
        slideCount: Int,
        studioRoot: URL
    ) throws -> [ExpectedArtifact] {
        guard let fileExtension = imageExtensions[platform] else {
            throw ScreenshotStudioError.unsupportedPlatform(platform)
        }
        let imagesDirectory = studioRoot
            .appending(path: platform)
            .appending(path: "images")
        let manifest = try contentsManifest(
            platform: platform,
            slideCount: slideCount
        )
        var artifacts: [ExpectedArtifact] = [
            .json(
                url: imagesDirectory.appending(path: "contents.json"),
                value: manifest
            ),
        ]

        for index in 0..<slideCount {
            artifacts += try sharedImageCopies(
                imagesDirectory: imagesDirectory,
                sourceLocale: "en-US",
                targetLocales: englishLocales.filter { $0 != "en-US" },
                index: index,
                fileExtension: fileExtension
            )
            artifacts += try sharedImageCopies(
                imagesDirectory: imagesDirectory,
                sourceLocale: "es-ES",
                targetLocales: ["es-MX"],
                index: index,
                fileExtension: fileExtension
            )
        }
        return artifacts
    }

    private static func sharedImageCopies(
        imagesDirectory: URL,
        sourceLocale: String,
        targetLocales: [String],
        index: Int,
        fileExtension: String
    ) throws -> [ExpectedArtifact] {
        let sourceURL = imagesDirectory.appending(
            path: "\(sourceLocale)_\(index)\(fileExtension)"
        )
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            return []
        }
        let sourceData = try Data(contentsOf: sourceURL)
        return targetLocales.map { locale in
            .data(
                url: imagesDirectory.appending(
                    path: "\(locale)_\(index)\(fileExtension)"
                ),
                value: sourceData
            )
        }
    }

    private static func loadSlides(
        platform: String,
        studioRoot: URL
    ) throws -> [[String: Any]] {
        let url = dataPlistURL(platform: platform, studioRoot: studioRoot)
        guard let slides = try loadPropertyList(at: url) as? [[String: Any]] else {
            throw ScreenshotStudioError.invalidPropertyList(url.path)
        }
        return slides
    }

    private static func dataPlistURL(
        platform: String,
        studioRoot: URL
    ) -> URL {
        studioRoot
            .appending(path: platform)
            .appending(path: "data.plist")
    }

    private static func loadPropertyList(at url: URL) throws -> Any {
        let data = try Data(contentsOf: url)
        var format = PropertyListSerialization.PropertyListFormat.xml
        return try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: &format
        )
    }

    private static func write(_ artifacts: [ExpectedArtifact]) throws {
        for artifact in artifacts {
            if try artifact.matchesCurrentFile() {
                continue
            }
            try FileManager.default.createDirectory(
                at: artifact.url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try artifact.serializedData().write(
                to: artifact.url,
                options: .atomic
            )
        }
    }

    private static func stalePaths(
        _ artifacts: [ExpectedArtifact],
        repositoryRoot: URL
    ) throws -> [String] {
        try artifacts.compactMap { artifact in
            guard try artifact.matchesCurrentFile() else {
                return FileWork.relativePath(
                    for: artifact.url,
                    from: repositoryRoot
                )
            }
            return nil
        }
    }
}

private struct SlideCopy {
    let byLocale: [String: (title: String, body: String)]

    func text(for locale: String) -> (title: String, body: String) {
        if let copy = byLocale[locale] {
            return copy
        }
        if locale.hasPrefix("en"), let copy = byLocale["en-US"] {
            return copy
        }
        preconditionFailure("Missing screenshot copy for \(locale)")
    }
}

private let slides: [SlideCopy] = [
    SlideCopy(byLocale: [
        "en-US": ("Race Through Endless Traffic", "Navigate your car, dodge rivals, and rack up overtakes in this retro-inspired arcade racer."),
        "es-ES": ("Esquiva Tráfico Sin Fin", "Conduce tu coche, esquiva rivales y acumula adelantamientos en este arcade de carreras de inspiración retro."),
        "es-MX": ("Esquiva Carros Sin Fin", "Conduce tu carro, esquiva rivales y rebasa adelantamientos en este arcade de carreras de inspiración retro."),
        "ca": ("Esquiva Trànsit Sense Fi", "Condueix el teu cotxe, esquiva rivals i acumula avançaments en este arcade de carreres d'inspiració retro."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Simple Controls. Pure Arcade Action", "Move left. Move right. Don't crash. Master the basics in seconds, then chase your high score for hours."),
        "es-ES": ("Controles Simples. Acción Arcade Pura", "Izquierda. Derecha. No choques. Domina lo básico en segundos y pasa horas persiguiendo tu récord."),
        "es-MX": ("Controles Simples. Acción Arcade Pura", "Izquierda. Derecha. No choques. Domina lo básico en segundos y pasa horas persiguiendo tu récord."),
        "ca": ("Controls Simples. Acció Arcade Pura", "Esquerra. Dreta. No xoques. Domina l'essencial en segons i passa hores perseguint el teu rècord."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Built For Accessibility", "VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings."),
        "es-ES": ("Diseñado para la Accesibilidad", "VoiceOver, pistas de audio, hápticos y ajustes de juego adaptables."),
        "es-MX": ("Diseñado para la Accesibilidad", "VoiceOver, pistas de audio, hápticos y ajustes de juego adaptables."),
        "ca": ("Dissenyat per a l'Accessibilitat", "VoiceOver, pistes d'àudio, hàptics i opcions de joc adaptables."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("One Wrong Move. Game Over", "The speed climbs. One mistake ends your run. Restart fast and beat your best."),
        "es-ES": ("Un Error. Game Over", "La velocidad sube. Un fallo termina tu partida. ¡Supera tu récord!"),
        "es-MX": ("Un Error. Game Over", "La velocidad sube. Un fallo termina tu partida. ¡Supera tu récord!"),
        "ca": ("Un Error. Game Over", "La velocitat puja. Un error acaba la teua partida. Supera el teu rècord!"),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Climb the Leaderboards", "Earn achievements, chase friends, and share your best runs with Game Center."),
        "es-ES": ("Sube en la Clasificación", "Gana logros, persigue amigos y comparte tus mejores partidas con Game Center."),
        "es-MX": ("Sube en la Clasificación", "Gana logros, persigue amigos y comparte tus mejores partidas con Game Center."),
        "ca": ("Puja en la Classificació", "Guanya assoliments, persegueix amistats i comparteix les teues millors partides amb Game Center."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Choose Your Retro Aesthetic", "Switch from pocket-console green to LCD handheld style, and make every run feel properly retro."),
        "es-ES": ("Elige Tu Estética Retro", "Del verde de las consolas de bolsillo clásicas a los juegos de mano LCD, personaliza tu experiencia visual con temas retro icónicos."),
        "es-MX": ("Elige Tu Estética Retro", "Del verde de las consolas de bolsillo clásicas a los juegos de mano LCD, personaliza tu experiencia visual con temas retro icónicos."),
        "ca": ("Tria la Teua Estètica Retro", "Del verd de les consoles de butxaca clàssiques als jocs de mà LCD, personalitza la teua experiència visual amb temes retro icònics."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Customize Your Experience", "Tune controls, haptics, volume, visual style, and feedback so RetroRapid! fits your play style."),
        "en-GB": ("Customise Your Experience", "Tune controls, haptics, volume, visual style, and feedback so RetroRapid! fits your play style."),
        "en-AU": ("Customise Your Experience", "Tune controls, haptics, volume, visual style, and feedback so RetroRapid! fits your play style."),
        "es-ES": ("Personaliza Tu Experiencia", "Ajusta el volumen, elige la respuesta háptica, selecciona tu tema y afina los controles. RetroRapid! se adapta a tu estilo de juego."),
        "es-MX": ("Personaliza Tu Experiencia", "Ajusta el volumen, elige la respuesta háptica, selecciona tu tema y afina los controles. RetroRapid! se adapta a tu estilo de juego."),
        "ca": ("Personalitza la Teua Experiència", "Ajusta el volum, tria la retroalimentació hàptica, selecciona el teu tema i afina els controls. RetroRapid! s'adapta al teu estil de joc."),
    ]),
]

private enum ExpectedArtifact {
    case propertyList(url: URL, value: Any)
    case json(url: URL, value: Any)
    case data(url: URL, value: Data)

    var url: URL {
        switch self {
        case let .propertyList(url, _), let .json(url, _), let .data(url, _):
            url
        }
    }

    func serializedData() throws -> Data {
        switch self {
        case let .propertyList(_, value):
            try PropertyListSerialization.data(
                fromPropertyList: value,
                format: .xml,
                options: 0
            )
        case let .json(_, value):
            try JSONSerialization.data(withJSONObject: value, options: [])
        case let .data(_, value):
            value
        }
    }

    func matchesCurrentFile() throws -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }

        switch self {
        case let .propertyList(_, expected):
            let currentData = try Data(contentsOf: url)
            var format = PropertyListSerialization.PropertyListFormat.xml
            let current = try PropertyListSerialization.propertyList(
                from: currentData,
                options: [],
                format: &format
            )
            return propertyListObjectsEqual(current, expected)
        case let .json(_, expected):
            let current = try JSONSerialization.jsonObject(
                with: Data(contentsOf: url)
            )
            let currentData = try JSONSerialization.data(
                withJSONObject: current,
                options: [.sortedKeys]
            )
            let expectedData = try JSONSerialization.data(
                withJSONObject: expected,
                options: [.sortedKeys]
            )
            return currentData == expectedData
        case let .data(_, expected):
            return try Data(contentsOf: url) == expected
        }
    }

    private func propertyListObjectsEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        (lhs as AnyObject).isEqual(rhs)
    }
}

public enum ScreenshotStudioError: LocalizedError {
    case projectNotFound
    case invalidPropertyList(String)
    case missingSlides(platform: String, expected: Int, actual: Int)
    case unsupportedPlatform(String)
    case projectOutOfDate([String])

    public var errorDescription: String? {
        switch self {
        case .projectNotFound:
            "Could not find AppStore/RetroRapid.screenshotstudio."
        case let .invalidPropertyList(path):
            "Invalid Screenshot Studio property list: \(path)."
        case let .missingSlides(platform, expected, actual):
            "\(platform) has \(actual) slides; expected at least \(expected)."
        case let .unsupportedPlatform(platform):
            "Unsupported Screenshot Studio platform: \(platform)."
        case let .projectOutOfDate(paths):
            "Screenshot Studio files are out of date:\n"
                + paths.joined(separator: "\n")
        }
    }
}

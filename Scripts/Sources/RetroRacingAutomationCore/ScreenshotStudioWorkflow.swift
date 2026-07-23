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
        "en-US", "en-GB", "en-AU", "en-CA",
        "de-DE", "nl-NL", "it", "fr-FR",
        "es-ES", "es-MX", "ca",
    ]
    public static let slideCount = 7

    private static let englishLocales = ["en-US", "en-GB", "en-AU", "en-CA"]
    private static let baseImageLocale = "en-US"
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
        try contentsManifest(
            platform: platform,
            slideCount: slideCount,
            locales: locales
        )
    }

    static func baseLocaleContentsManifest(
        platform: String,
        slideCount: Int
    ) throws -> [String: Any] {
        try contentsManifest(
            platform: platform,
            slideCount: slideCount,
            locales: [baseImageLocale]
        )
    }

    private static func contentsManifest(
        platform: String,
        slideCount: Int,
        locales manifestLocales: [String]
    ) throws -> [String: Any] {
        guard let fileExtension = imageExtensions[platform] else {
            throw ScreenshotStudioError.unsupportedPlatform(platform)
        }
        let images = (0..<slideCount).flatMap { index in
            manifestLocales.map { locale in
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
        artifacts += try expectedBaseLocaleImageArtifacts(
            platform: "appleWatch",
            slideCount: try loadSlides(
                platform: "appleWatch",
                studioRoot: studioRoot
            ).count,
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
        for index in watchSlides.indices {
            watchSlides[index]["localizations"] = emptyLocalizationEntries(
                preservingOrderFrom: watchSlides[index]["localizations"]
            )
        }
        return .propertyList(url: url, value: watchSlides)
    }

    private static func emptyLocalizationEntries(
        preservingOrderFrom currentValue: Any?
    ) -> [[String: String]] {
        let currentLocales = (currentValue as? [[String: Any]])?
            .compactMap { $0["language"] as? String } ?? []
        let orderedLocales = currentLocales
            + locales.filter { locale in !currentLocales.contains(locale) }
        return orderedLocales.map { locale in
            ["language": locale, "title": "", "body": ""]
        }
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
                sourceLocale: baseImageLocale,
                targetLocales: locales.filter { $0 != baseImageLocale },
                index: index,
                fileExtension: fileExtension
            )
        }
        return artifacts
    }

    private static func expectedBaseLocaleImageArtifacts(
        platform: String,
        slideCount: Int,
        studioRoot: URL
    ) throws -> [ExpectedArtifact] {
        let imagesDirectory = studioRoot
            .appending(path: platform)
            .appending(path: "images")
        let manifest = try baseLocaleContentsManifest(
            platform: platform,
            slideCount: slideCount
        )
        return [
            .json(
                url: imagesDirectory.appending(path: "contents.json"),
                value: manifest
            ),
        ]
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
        "en-US": ("Race Through Endless Traffic", "Dodge traffic and chase overtakes in a retro arcade racer."),
        "de-DE": ("Rase Durch Endlosen Verkehr", "Weiche Verkehr aus und hol dir Überholungen in diesem Retro-Arcade-Rennen."),
        "nl-NL": ("Race Door Eindeloos Verkeer", "Ontwijk verkeer en pak inhaalslagen in deze retro arcade-racer."),
        "it": ("Corri Nel Traffico Infinito", "Schiva il traffico e conquista sorpassi in questo arcade di corse retro."),
        "fr-FR": ("Fonce Dans Le Trafic Sans Fin", "Esquive le trafic et enchaîne les dépassements dans cette course arcade retro."),
        "es-ES": ("Esquiva Tráfico Sin Fin", "Esquiva tráfico y consigue adelantamientos en un arcade de carreras retro."),
        "es-MX": ("Esquiva Carros Sin Fin", "Esquiva carros y logra rebases en un arcade de carreras retro."),
        "ca": ("Esquiva Trànsit Sense Fi", "Esquiva trànsit i acumula avançaments en este arcade de carreres retro."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Simple Controls. Pure Arcade Action", "Move left. Move right. Don't crash. That's the whole game."),
        "de-DE": ("Einfache Steuerung. Pure Arcade-Action", "Links. Rechts. Nicht crashen. Das ist das ganze Spiel."),
        "nl-NL": ("Simpele Besturing. Pure Arcade-Actie", "Links. Rechts. Niet crashen. Dat is het hele spel."),
        "it": ("Controlli Semplici. Pura Azione Arcade", "Sinistra. Destra. Non schiantarti. È tutto il gioco."),
        "fr-FR": ("Commandes Simples. Action Arcade Pure", "Gauche. Droite. Ne crash pas. C'est tout le jeu."),
        "es-ES": ("Controles Simples. Acción Arcade Pura", "Izquierda. Derecha. No choques. Eso es todo el juego."),
        "es-MX": ("Controles Simples. Acción Arcade Pura", "Izquierda. Derecha. No choques. Eso es todo el juego."),
        "ca": ("Controls Simples. Acció Arcade Pura", "Esquerra. Dreta. No xoques. Això és tot el joc."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Built For Accessibility", "VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings."),
        "de-DE": ("Für Barrierefreiheit Gebaut", "VoiceOver, Audiohinweise, Haptik und anpassbare Spieleinstellungen."),
        "nl-NL": ("Gemaakt Voor Toegankelijkheid", "VoiceOver, audiosignalen, haptiek en aanpasbare spelinstellingen."),
        "it": ("Progettato Per L'Accessibilità", "VoiceOver, segnali audio, haptica e impostazioni di gioco adattabili."),
        "fr-FR": ("Conçu Pour L'Accessibilité", "VoiceOver, indices audio, haptique et réglages de jeu adaptables."),
        "es-ES": ("Diseñado para la Accesibilidad", "VoiceOver, pistas de audio, hápticos y ajustes de juego adaptables."),
        "es-MX": ("Diseñado para la Accesibilidad", "VoiceOver, pistas de audio, hápticos y ajustes de juego adaptables."),
        "ca": ("Dissenyat per a l'Accessibilitat", "VoiceOver, pistes d'àudio, hàptics i opcions de joc adaptables."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("One Wrong Move. Game Over", "One mistake ends your run. Restart fast, beat your best."),
        "de-DE": ("Ein Fehler. Game Over", "Ein Fehler beendet deine Runde. Schnell neu starten, Rekord schlagen."),
        "nl-NL": ("Één Fout. Game Over", "Één fout beëindigt je run. Snel herstarten, verbeter je record."),
        "it": ("Un Errore. Game Over", "Un errore termina la partita. Riparti in fretta, batti il tuo record."),
        "fr-FR": ("Une Erreur. Game Over", "Une erreur termine ta partie. Recommence vite, bats ton record."),
        "es-ES": ("Un Error. Game Over", "Un fallo termina tu partida. Reinicia y supera tu récord."),
        "es-MX": ("Un Error. Game Over", "Un fallo termina tu partida. Reinicia y supera tu récord."),
        "ca": ("Un Error. Game Over", "Un error acaba la teua partida. Reinicia i supera el teu rècord."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Chase Friends On The Road", "Game Center markers show the rival score you're chasing."),
        "de-DE": ("Jage Freunde Auf Der Strecke", "Game-Center-Marker zeigen den Punktestand, den du jagst."),
        "nl-NL": ("Jaag Vrienden Op De Baan", "Game Center-markeringen tonen de score die je achtervolgt."),
        "it": ("Insegue Amici In Pista", "I marcatori Game Center mostrano il punteggio che insegui."),
        "fr-FR": ("Poursuis Tes Amis Sur La Piste", "Les marqueurs Game Center montrent le score que tu poursuis."),
        "es-ES": ("Persigue Amigos en Pista", "Los marcadores de Game Center muestran la puntuación que persigues."),
        "es-MX": ("Persigue Amigos en Pista", "Los marcadores de Game Center muestran la puntuación que persigues."),
        "ca": ("Persegueix Amistats en Pista", "Els marcadors de Game Center mostren la puntuació que persegueixes."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Choose Your Retro Aesthetic", "Switch between pocket-console green and LCD handheld styles anytime."),
        "de-DE": ("Wähle Deinen Retro-Look", "Wechsle jederzeit zwischen Pocket-Konsolen-Grün und LCD-Handheld-Stil."),
        "nl-NL": ("Kies Je Retro-Stijl", "Wissel altijd tussen pocket-console groen en LCD-handheld-stijl."),
        "it": ("Scegli La Tua Estetica Retro", "Passa dal verde console tascabile allo stile LCD portatile quando vuoi."),
        "fr-FR": ("Choisis Ton Style Retro", "Passe du vert console de poche au style LCD portable quand tu veux."),
        "es-ES": ("Elige Tu Estética Retro", "Cambia del verde de consola de bolsillo al estilo LCD portátil."),
        "es-MX": ("Elige Tu Estética Retro", "Cambia del verde de consola de bolsillo al estilo LCD portátil."),
        "ca": ("Tria la Teua Estètica Retro", "Canvia del verd de consola de butxaca a l'estil LCD portàtil."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Customize Your Experience", "Tune controls, haptics, volume, and visuals to fit your style."),
        "en-GB": ("Customise Your Experience", "Tune controls, haptics, volume, and visuals to fit your style."),
        "en-AU": ("Customise Your Experience", "Tune controls, haptics, volume, and visuals to fit your style."),
        "de-DE": ("Passe Dein Erlebnis An", "Stelle Steuerung, Haptik, Lautstärke und Optik nach deinem Stil ein."),
        "nl-NL": ("Pas Je Ervaring Aan", "Stel besturing, haptiek, volume en visuals af op jouw stijl."),
        "it": ("Personalizza La Tua Esperienza", "Regola controlli, haptica, volume e grafica al tuo stile."),
        "fr-FR": ("Personnalise Ton Expérience", "Ajuste commandes, haptique, volume et visuels à ton style."),
        "es-ES": ("Personaliza Tu Experiencia", "Ajusta controles, hápticos, volumen y visuales a tu estilo."),
        "es-MX": ("Personaliza Tu Experiencia", "Ajusta controles, hápticos, volumen y visuales a tu estilo."),
        "ca": ("Personalitza la Teua Experiència", "Ajusta els controls, hàptics, volum i visuals al teu estil."),
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

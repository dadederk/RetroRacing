//
//  SyncScreenshotStudioLocalizations.swift
//  RetroRacing
//
//  Created by Dani Devesa on 24/06/2026.
//
//  Keeps the Screenshot Studio project in sync with the canonical seven-slide
//  overlay copy for all App Store locales. Run from the repo root:
//    swift Scripts/SyncScreenshotStudioLocalizations.swift
//

import Foundation

private let locales = ["en-US", "en-GB", "en-AU", "en-CA", "es-ES", "es-MX", "ca"]
private let englishLocales = ["en-US", "en-GB", "en-AU", "en-CA"]
private let platforms7 = ["iphone", "ipad", "mac"]
private let imageExtensions = ["iphone": ".jpeg", "ipad": ".jpeg", "mac": ".png", "appleWatch": ".jpeg"]

private struct SlideCopy {
    let byLocale: [String: (title: String, body: String)]

    func text(for locale: String) -> (title: String, body: String) {
        if let copy = byLocale[locale] {
            return copy
        }
        if englishLocales.contains(locale), let copy = byLocale["en-US"] {
            return copy
        }
        fatalError("Missing copy for locale \(locale)")
    }
}

// Seven-slide storyboard (AppStore/docs/06-screenshots.md).
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

private let studioRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("AppStore/RetroRacing.screenshotstudio", isDirectory: true)

private func loadPropertyList(at url: URL) throws -> Any {
    let data = try Data(contentsOf: url)
    var format = PropertyListSerialization.PropertyListFormat.xml
    return try PropertyListSerialization.propertyList(from: data, options: [], format: &format)
}

private func savePropertyList(_ value: Any, to url: URL) throws {
    let data = try PropertyListSerialization.data(
        fromPropertyList: value,
        format: .xml,
        options: 0
    )
    try data.write(to: url, options: .atomic)
}

private func localizationEntries(for slide: SlideCopy, watchSequenceOnly: Bool) -> [[String: String]] {
    locales.map { locale in
        if watchSequenceOnly, !englishLocales.contains(locale) {
            return ["language": locale, "title": "", "body": ""]
        }
        let copy = slide.text(for: locale)
        return ["language": locale, "title": copy.title, "body": copy.body]
    }
}

private func updateProjectPlist() throws {
    let url = studioRoot.appendingPathComponent("project.plist")
    guard var data = try loadPropertyList(at: url) as? [String: Any] else {
        throw NSError(domain: "SyncScreenshotStudioLocalizations", code: 1)
    }
    var projectLocales = data["localizations"] as? [String] ?? []
    for locale in locales where !projectLocales.contains(locale) {
        projectLocales.append(locale)
    }
    data["localizations"] = projectLocales
    try savePropertyList(data, to: url)
}

private func loadSlides(platform: String) throws -> [[String: Any]] {
    let url = studioRoot.appendingPathComponent(platform).appendingPathComponent("data.plist")
    guard let slides = try loadPropertyList(at: url) as? [[String: Any]] else {
        throw NSError(domain: "SyncScreenshotStudioLocalizations", code: 2)
    }
    return slides
}

private func updateDataPlist(platform: String, slideCount: Int) throws {
    var platformSlides = try loadSlides(platform: platform)
    if platform != "iphone" {
        let iphoneSlides = try loadSlides(platform: "iphone")
        while platformSlides.count < slideCount, platformSlides.count < iphoneSlides.count {
            platformSlides.append(iphoneSlides[platformSlides.count])
        }
    }
    platformSlides = Array(platformSlides.prefix(slideCount))

    for index in 0 ..< slideCount {
        var slide = platformSlides[index]
        slide["localizations"] = localizationEntries(for: slides[index], watchSequenceOnly: false)
        platformSlides[index] = slide
    }

    let url = studioRoot.appendingPathComponent(platform).appendingPathComponent("data.plist")
    try savePropertyList(platformSlides, to: url)
}

private func writeContentsJSON(platform: String, slideCount: Int) throws {
    let imagesDirectory = studioRoot.appendingPathComponent(platform).appendingPathComponent("images", isDirectory: true)
    try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    guard let fileExtension = imageExtensions[platform] else {
        throw NSError(domain: "SyncScreenshotStudioLocalizations", code: 3)
    }

    var images: [[String: Any]] = []
    for index in 0 ..< slideCount {
        for locale in locales {
            images.append([
                "filename": "\(locale)_\(index)\(fileExtension)",
                "index": index,
                "locale": locale,
            ])
        }
    }

    let jsonData = try JSONSerialization.data(withJSONObject: ["images": images], options: [])
    try jsonData.write(to: imagesDirectory.appendingPathComponent("contents.json"), options: .atomic)

    try copySharedBaseImages(in: imagesDirectory, slideCount: slideCount, fileExtension: fileExtension)
}

private func copySharedBaseImages(in imagesDirectory: URL, slideCount: Int, fileExtension: String) throws {
    let fileManager = FileManager.default

    for index in 0 ..< slideCount {
        let baseFile = imagesDirectory.appendingPathComponent("en-US_\(index)\(fileExtension)")
        guard fileManager.fileExists(atPath: baseFile.path) else { continue }

        let baseModified = try baseFile.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate

        for locale in englishLocales where locale != "en-US" {
            let target = imagesDirectory.appendingPathComponent("\(locale)_\(index)\(fileExtension)")
            let targetModified = try? target.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
            if !fileManager.fileExists(atPath: target.path)
                || (baseModified != nil && (targetModified == nil || targetModified! < baseModified!)) {
                if fileManager.fileExists(atPath: target.path) {
                    try fileManager.removeItem(at: target)
                }
                try fileManager.copyItem(at: baseFile, to: target)
            }
        }
    }

    let spanishBase = imagesDirectory.appendingPathComponent("es-ES_0\(fileExtension)")
    guard fileManager.fileExists(atPath: spanishBase.path) else { return }

    for index in 0 ..< slideCount {
        let esBase = imagesDirectory.appendingPathComponent("es-ES_\(index)\(fileExtension)")
        guard fileManager.fileExists(atPath: esBase.path) else { continue }

        let esModified = try esBase.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        let mxTarget = imagesDirectory.appendingPathComponent("es-MX_\(index)\(fileExtension)")
        let mxModified = try? mxTarget.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate

        if !fileManager.fileExists(atPath: mxTarget.path)
            || (esModified != nil && (mxModified == nil || mxModified! < esModified!)) {
            if fileManager.fileExists(atPath: mxTarget.path) {
                try fileManager.removeItem(at: mxTarget)
            }
            try fileManager.copyItem(at: esBase, to: mxTarget)
        }
    }
}

private func updateWatchDataPlist() throws {
    var watchSlides = try loadSlides(platform: "appleWatch")
    guard !watchSlides.isEmpty else {
        throw NSError(domain: "SyncScreenshotStudioLocalizations", code: 4)
    }
    watchSlides[0]["localizations"] = localizationEntries(for: slides[0], watchSequenceOnly: true)
    let url = studioRoot.appendingPathComponent("appleWatch").appendingPathComponent("data.plist")
    try savePropertyList(watchSlides, to: url)
    try writeContentsJSON(platform: "appleWatch", slideCount: 1)
}

do {
    guard FileManager.default.fileExists(atPath: studioRoot.path) else {
        fputs("Run from the repo root so AppStore/RetroRacing.screenshotstudio exists.\n", stderr)
        exit(1)
    }

    try updateProjectPlist()
    for platform in platforms7 {
        try updateDataPlist(platform: platform, slideCount: 7)
        try writeContentsJSON(platform: platform, slideCount: 7)
    }
    try updateWatchDataPlist()
    print("Screenshot Studio localizations synced.")
} catch {
    fputs("Sync failed: \(error)\n", stderr)
    exit(1)
}

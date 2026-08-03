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
        "de-DE", "nl-NL", "it", "fr-FR", "fr-CA",
        "es-ES", "es-MX", "ca",
        "ja", "ko", "pt-BR", "pt-PT", "zh-Hant", "zh-Hans",
    ]
    public static let slideCount = 10
    public static let macSlideCount = 9
    public static let watchSlideCount = 5

    public static func slideCount(for platform: String) -> Int {
        switch AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform) {
        case "appleWatch":
            return watchSlideCount
        case "mac":
            return macSlideCount
        default:
            return slideCount
        }
    }

    /// Maps a platform-specific Studio slide index to the canonical copy index in `slides`.
    static func copySlideIndex(platform: String, slideIndex: Int) -> Int {
        if AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform) == "mac", slideIndex >= 4 {
            return slideIndex + 1
        }
        return slideIndex
    }

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
        watchSequenceOnly: Bool,
        platform: String = "iphone"
    ) throws -> [[String: String]] {
        let copyIndex = copySlideIndex(platform: platform, slideIndex: slideIndex)
        return try locales.map { locale in
            if watchSequenceOnly, !englishLocales.contains(locale) {
                return ["language": locale, "title": "", "body": ""]
            }
            let copy = try slides[copyIndex].text(for: locale)
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
            let platformSlideCount = slideCount(for: platform)
            artifacts.append(
                try expectedDataPlist(
                    platform: platform,
                    slideCount: platformSlideCount,
                    studioRoot: studioRoot
                )
            )
            artifacts += try expectedImageArtifacts(
                platform: platform,
                slideCount: platformSlideCount,
                studioRoot: studioRoot
            )
        }

        artifacts.append(try expectedWatchDataPlist(studioRoot: studioRoot))
        artifacts += try expectedImageArtifacts(
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

        while platformSlides.count < slideCount {
            let template = platformSlides.last ?? [:]
            platformSlides.append(template)
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
            platformSlides[index]["localizations"] = try localizationEntries(
                slideIndex: index,
                watchSequenceOnly: false,
                platform: platform
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

        for (sourceLocale, derivedLocales) in ScreenshotCapturePlan.derivedLocaleMap {
            let requestedDerivedLocales = derivedLocales.filter { locales.contains($0) }
            guard requestedDerivedLocales.isEmpty == false else { continue }
            for index in 0..<slideCount {
                artifacts += try sharedImageCopies(
                    imagesDirectory: imagesDirectory,
                    sourceLocale: sourceLocale,
                    targetLocales: requestedDerivedLocales,
                    index: index,
                    fileExtension: fileExtension
                )
            }
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
            let targetURL = imagesDirectory.appending(
                path: "\(locale)_\(index)\(fileExtension)"
            )
            return .data(
                url: targetURL,
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

    func text(for locale: String) throws -> (title: String, body: String) {
        if let copy = byLocale[locale] {
            return copy
        }
        if locale.hasPrefix("en"), let copy = byLocale["en-US"] {
            return copy
        }
        throw ScreenshotStudioError.missingScreenshotCopy(locale: locale)
    }
}

private let slides: [SlideCopy] = [
    SlideCopy(byLocale: [
        "en-US": ("Race Through Endless Traffic", "Dodge traffic and chase overtakes in a retro arcade racer."),
        "de-DE": ("Rase Durch Endlosen Verkehr", "Weiche Verkehr aus und hol dir Überholungen in diesem Retro-Arcade-Rennen."),
        "nl-NL": ("Race Door Eindeloos Verkeer", "Ontwijk verkeer en pak inhaalslagen in deze retro arcade-racer."),
        "it": ("Corri Nel Traffico Infinito", "Schiva il traffico e conquista sorpassi in questo arcade di corse retro."),
        "fr-FR": ("Fonce Dans Le Trafic Sans Fin", "Esquive le trafic et enchaîne les dépassements dans cette course arcade retro."),
        "fr-CA": ("Foncez Dans Le Trafic Sans Fin", "Évitez le trafic et enchaînez les dépassements dans cette course arcade rétro."),
        "es-ES": ("Esquiva Tráfico Sin Fin", "Esquiva tráfico y consigue adelantamientos en un arcade de carreras retro."),
        "es-MX": ("Esquiva Carros Sin Fin", "Esquiva carros y logra rebases en un arcade de carreras retro."),
        "ca": ("Esquiva Trànsit Sense Fi", "Esquiva trànsit i acumula avançaments en este arcade de carreres retro."),
        "ja": ("終わりなき交通を走り抜け", "交通を避け、レトロアーケードで追い抜きを狙おう。"),
        "ko": ("끝없는 교통을 질주", "교통을 피하고 레트로 아케이드에서 추월을 노려보세요."),
        "pt-BR": ("Corra Pelo Tráfego Infinito", "Desvie do tráfego e busque ultrapassagens neste arcade retrô."),
        "pt-PT": ("Corra Pelo Trânsito Infinito", "Desvie do trânsito e procure ultrapassagens neste arcade retrô."),
        "zh-Hant": ("穿越無盡車流", "閃避車流，在復古街機中追逐超車。"),
        "zh-Hans": ("穿越无尽车流", "闪避车流，在复古街机中追逐超车。"),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Simple Controls. Pure Arcade Action", "Move left. Move right. Don't crash. Deceptively simple."),
        "de-DE": ("Einfache Steuerung. Pure Arcade-Action", "Links. Rechts. Nicht crashen. Täuschend einfach."),
        "nl-NL": ("Simpele Besturing. Pure Arcade-Actie", "Links. Rechts. Niet crashen. Bedrieglijk simpel."),
        "it": ("Controlli Semplici. Pura Azione Arcade", "Sinistra. Destra. Non schiantarti. Ingannatamente semplice."),
        "fr-FR": ("Commandes Simples. Action Arcade Pure", "Gauche. Droite. Ne crash pas. D'une simplicité trompeuse."),
        "fr-CA": ("Commandes Simples. Action Arcade Pure", "Gauche. Droite. Ne crashez pas. D'une simplicité trompeuse."),
        "es-ES": ("Controles Simples. Acción Arcade Pura", "Izquierda. Derecha. No choques. Engañosamente simple."),
        "es-MX": ("Controles Simples. Acción Arcade Pura", "Izquierda. Derecha. No choques. Engañosamente simple."),
        "ca": ("Controls Simples. Acció Arcade Pura", "Esquerra. Dreta. No xoques. Enganyosament simple."),
        "ja": ("シンプル操作。純粋アーケード", "左へ。右へ。クラッシュ禁止。シンプルなのに奥深い。"),
        "ko": ("간단한 조작. 순수 아케이드", "왼쪽. 오른쪽. 충돌 금지. 단순하지만 깊어요."),
        "pt-BR": ("Controles Simples. Ação Arcade", "Esquerda. Direita. Não bata. Simples de enganar."),
        "pt-PT": ("Controlos Simples. Ação Arcade", "Esquerda. Direita. Não bata. Enganosamente simples."),
        "zh-Hant": ("簡單操作。純粹街機", "左移。右移。別撞車。看似簡單。"),
        "zh-Hans": ("简单操作。纯粹街机", "左移。右移。别撞车。看似简单。"),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("One Wrong Move. Game Over", "One mistake ends your run. Restart fast, chase your high score!"),
        "de-DE": ("Ein Fehler. Game Over", "Ein Fehler beendet deine Runde. Schnell neu starten, jag deinen Highscore!"),
        "nl-NL": ("Één Fout. Game Over", "Één fout beëindigt je run. Snel herstarten, jaag op je highscore!"),
        "it": ("Un Errore. Game Over", "Un errore termina la partita. Riparti in fretta, punta al tuo record!"),
        "fr-FR": ("Une Erreur. Game Over", "Une erreur termine ta partie. Recommence vite, vise ton record!"),
        "fr-CA": ("Une Erreur. Game Over", "Une erreur termine votre partie. Recommencez vite, visez votre record!"),
        "es-ES": ("Un Error. Game Over", "Un fallo termina tu partida. Reinicia y persigue tu récord!"),
        "es-MX": ("Un Error. Game Over", "Un fallo termina tu partida. Reinicia y persigue tu récord!"),
        "ca": ("Un Error. Game Over", "Un error acaba la teua partida. Reinicia i persegueix el teu rècord!"),
        "ja": ("一ミスでゲームオーバー", "一つのミスで終了。すぐ再スタート、ハイスコアを狙え！"),
        "ko": ("한 번의 실수, 게임 오버", "실수 한 번이면 끝. 빠르게 재시작하고 최고 점수에 도전!"),
        "pt-BR": ("Um Erro. Fim De Jogo", "Um erro encerra a corrida. Reinicie e busque seu recorde!"),
        "pt-PT": ("Um Erro. Fim De Jogo", "Um erro acaba a corrida. Reinicie e procure o seu recorde!"),
        "zh-Hant": ("一步失誤，遊戲結束", "一個失誤就結束。快速重來，挑戰最高分！"),
        "zh-Hans": ("一步失误，游戏结束", "一个失误就结束。快速重来，挑战最高分！"),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Accessibility Front and Center", "VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings."),
        "de-DE": ("Barrierefreiheit Im Mittelpunkt", "VoiceOver, Audiohinweise, Haptik, größerer Text und anpassbare Spieleinstellungen."),
        "nl-NL": ("Toegankelijkheid Voorop", "VoiceOver, audiosignalen, haptiek, grotere tekst en aanpasbare spelinstellingen."),
        "it": ("Accessibilità Al Centro", "VoiceOver, segnali audio, haptica, testo più grande e impostazioni di gioco adattabili."),
        "fr-FR": ("Accessibilité Au Premier Plan", "VoiceOver, indices audio, haptique, texte plus grand et réglages de jeu adaptables."),
        "fr-CA": ("Accessibilité Au Premier Plan", "VoiceOver, indices audio, haptique, texte plus grand et réglages de jeu adaptables."),
        "es-ES": ("Accesibilidad En Primer Plano", "VoiceOver, pistas de audio, hápticos, texto más grande y ajustes de juego adaptables."),
        "es-MX": ("Accesibilidad En Primer Plano", "VoiceOver, pistas de audio, hápticos, texto más grande y ajustes de juego adaptables."),
        "ca": ("Accessibilitat Al Davant", "VoiceOver, pistes d'àudio, hàptics, text més gran i opcions de joc adaptables."),
        "ja": ("アクセシビリティを前面に", "VoiceOver、音声キュー、触覚、大きい文字、調整可能な設定。"),
        "ko": ("접근성을 중심에", "VoiceOver, 오디오 큐, 햅틱, 큰 텍스트, 맞춤 설정."),
        "pt-BR": ("Acessibilidade Em Destaque", "VoiceOver, pistas sonoras, háptico, texto maior e ajustes adaptáveis."),
        "pt-PT": ("Acessibilidade Em Destaque", "VoiceOver, pistas sonoras, háptico, texto maior e definições adaptáveis."),
        "zh-Hant": ("無障礙設計放首位", "VoiceOver、音效提示、觸覺、較大字體與可調設定。"),
        "zh-Hans": ("无障碍设计放首位", "VoiceOver、音效提示、触觉、较大字体与可调设置。"),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Race Friends with SharePlay", "Challenge friends for free. Countdown, compete, rematch."),
        "de-DE": ("Rase Mit Freunden Per SharePlay", "Fordere Freunde gratis heraus. Countdown, Wettbewerb, Rematch."),
        "nl-NL": ("Race Met Vrienden Via SharePlay", "Daag vrienden gratis uit. Countdown, strijd, rematch."),
        "it": ("Corri Con Amici Via SharePlay", "Sfida gli amici gratis. Countdown, gara, rematch."),
        "fr-FR": ("Course Avec Des Amis Via SharePlay", "Défie tes amis gratuitement. Compte à rebours, course, revanche."),
        "fr-CA": ("Coursez Avec Des Amis Via SharePlay", "Défiez vos amis gratuitement. Compte à rebours, course, revanche."),
        "es-ES": ("Corre Con Amigos Con SharePlay", "Reta a amigos gratis. Cuenta atrás, compite, revancha."),
        "es-MX": ("Corre Con Amigos Con SharePlay", "Reta a amigos gratis. Cuenta atrás, compite, revancha."),
        "ca": ("Corre Amb Amics Amb SharePlay", "Desafia amistats gratis. Compte enrere, competeix, revenja."),
        "ja": ("SharePlayでフレンドとレース", "無料でフレンドに挑戦。カウントダウン、対戦、リマッチ。"),
        "ko": ("SharePlay로 친구와 레이스", "무료로 친구에게 도전. 카운트다운, 대전, 리매치."),
        "pt-BR": ("Corra Com Amigos No SharePlay", "Desafie amigos grátis. Contagem, competição, revanche."),
        "pt-PT": ("Corra Com Amigos No SharePlay", "Desafie amigos grátis. Contagem, competição, desforra."),
        "zh-Hant": ("SharePlay 與好友競賽", "免費挑戰好友。倒數、對戰、重賽。"),
        "zh-Hans": ("SharePlay 与好友竞赛", "免费挑战好友。倒数、对战、重赛。"),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Climb the Leaderboard", "Game Center scores and friend markers keep every run competitive."),
        "de-DE": ("Erklimme Die Bestenliste", "Game-Center-Punkte und Freundesmarker halten jede Runde spannend."),
        "nl-NL": ("Klim Op Het Scorebord", "Game Center-scores en vriendenmarkeringen houden elke run spannend."),
        "it": ("Scala La Classifica", "Punteggi Game Center e marcatori amici rendono ogni gara competitiva."),
        "fr-FR": ("Grimpe Au Classement", "Scores Game Center et marqueurs d'amis rendent chaque course compétitive."),
        "fr-CA": ("Grimpez Au Classement", "Les scores Game Center et les marqueurs d'amis rendent chaque course compétitive."),
        "es-ES": ("Escala La Clasificación", "Puntuaciones de Game Center y marcadores de amigos mantienen cada partida competitiva."),
        "es-MX": ("Escala La Clasificación", "Puntuaciones de Game Center y marcadores de amigos mantienen cada partida competitiva."),
        "ca": ("Puja En La Classificació", "Puntuacions de Game Center i marcadors d'amistats mantenen cada partida competitiva."),
        "ja": ("ランキングを駆け上がれ", "Game Centerスコアとフレンドマーカーで毎ランが熱い。"),
        "ko": ("리더보드를 올라가세요", "Game Center 점수와 친구 마커로 매 판이 경쟁적."),
        "pt-BR": ("Suba No Ranking", "Pontuações do Game Center e marcadores mantêm cada corrida competitiva."),
        "pt-PT": ("Suba Na Classificação", "Pontuações do Game Center e marcadores mantêm cada corrida competitiva."),
        "zh-Hant": ("衝上排行榜", "Game Center 分數與好友標記讓每局都競爭感十足。"),
        "zh-Hans": ("冲上排行榜", "Game Center 分数与好友标记让每局都竞争感十足。"),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Customize Your Experience", "Tune volume, haptics, controls… Go Cruise, Fast, or Rapid!"),
        "en-GB": ("Customise Your Experience", "Tune volume, haptics, controls… Go Cruise, Fast, or Rapid!"),
        "en-AU": ("Customise Your Experience", "Tune volume, haptics, controls… Go Cruise, Fast, or Rapid!"),
        "en-CA": ("Customize Your Experience", "Tune volume, haptics, controls… Go Cruise, Fast, or Rapid!"),
        "de-DE": ("Passe Dein Erlebnis An", "Lautstärke, Haptik, Steuerung… Cruise, Fast oder Rapid!"),
        "nl-NL": ("Pas Je Ervaring Aan", "Volume, haptiek, besturing… Cruise, Fast of Rapid!"),
        "it": ("Personalizza La Tua Esperienza", "Volume, haptica, controlli… Cruise, Fast o Rapid!"),
        "fr-FR": ("Personnalise Ton Expérience", "Volume, haptique, commandes… Cruise, Fast ou Rapid!"),
        "fr-CA": ("Personnalisez Votre Expérience", "Volume, haptique, commandes… Cruise, Fast ou Rapid!"),
        "es-ES": ("Personaliza Tu Experiencia", "Volumen, hápticos, controles… Cruise, Fast o Rapid!"),
        "es-MX": ("Personaliza Tu Experiencia", "Volumen, hápticos, controles… Cruise, Fast o Rapid!"),
        "ca": ("Personalitza La Teua Experiència", "Volum, hàptics, controls… Cruise, Fast o Rapid!"),
        "ja": ("体験をカスタマイズ", "音量、触覚、操作… Cruise、Fast、Rapid！"),
        "ko": ("경험을 맞춤 설정", "볼륨, 햅틱, 조작… Cruise, Fast, Rapid!"),
        "pt-BR": ("Personalize Sua Experiência", "Volume, háptico, controles… Cruise, Fast ou Rapid!"),
        "pt-PT": ("Personalize A Sua Experiência", "Volume, háptico, controlos… Cruise, Fast ou Rapid!"),
        "zh-Hant": ("自訂你的體驗", "調整音量、觸覺、操作… Cruise、Fast 或 Rapid！"),
        "zh-Hans": ("自定义你的体验", "调整音量、触觉、操作… Cruise、Fast 或 Rapid！"),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Choose Your Retro Aesthetic", "Switch between four retro eras, from Pocket to 16-Bit."),
        "en-GB": ("Choose Your Retro Aesthetic", "Switch between four retro eras, from Pocket to 16-Bit."),
        "en-AU": ("Choose Your Retro Aesthetic", "Switch between four retro eras, from Pocket to 16-Bit."),
        "en-CA": ("Choose Your Retro Aesthetic", "Switch between four retro eras, from Pocket to 16-Bit."),
        "de-DE": ("Wähle Deinen Retro-Look", "Wechsle zwischen vier Retro-Epochen, von Pocket bis 16-Bit."),
        "nl-NL": ("Kies Je Retro-Stijl", "Wissel tussen vier retro-tijdperken, van Pocket tot 16-Bit."),
        "it": ("Scegli La Tua Estetica Retro", "Passa tra quattro epoche retrò, da Pocket a 16-Bit."),
        "fr-FR": ("Choisis Ton Style Retro", "Passe entre quatre époques rétro, de Pocket à 16-Bit."),
        "fr-CA": ("Choisissez Votre Style Rétro", "Passez entre quatre époques rétro, de Pocket à 16-Bit."),
        "es-ES": ("Elige Tu Estética Retro", "Cambia entre cuatro eras retro, desde Pocket hasta 16-Bit."),
        "es-MX": ("Elige Tu Estética Retro", "Cambia entre cuatro eras retro, desde Pocket hasta 16-Bit."),
        "ca": ("Tria la Teua Estètica Retro", "Canvia entre quatre èpoques retro, de Pocket a 16-Bit."),
        "ja": ("レトロ美学を選ぼう", "Pocketから16-Bitまで、4つのレトロ時代を切り替え。"),
        "ko": ("레트로 스타일 선택", "Pocket부터 16-Bit까지 네 가지 레트로 시대를 전환하세요."),
        "pt-BR": ("Escolha Seu Visual Retro", "Alterne entre quatro eras retrô, de Pocket a 16-Bit."),
        "pt-PT": ("Escolha O Seu Visual Retrô", "Alterne entre quatro eras retro, de Pocket a 16-Bit."),
        "zh-Hant": ("選擇復古風格", "在四個復古時代間切換，從 Pocket 到 16-Bit。"),
        "zh-Hans": ("选择复古风格", "在四个复古时代间切换，从 Pocket 到 16-Bit。"),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Unlock Retro Achievements", "Earn Game Center trophies as you race and improve."),
        "de-DE": ("Schalte Retro-Erfolge Frei", "Verdiene Game-Center-Trophäen, während du fährst und dich verbesserst."),
        "nl-NL": ("Ontgrendel Retro Prestaties", "Verdien Game Center-trofeeën terwijl je rijdt en verbetert."),
        "it": ("Sblocca Obiettivi Retro", "Ottieni trofei Game Center mentre corri e migliori."),
        "fr-FR": ("Débloque Des Succès Retro", "Gagne des trophées Game Center en courant et en progressant."),
        "fr-CA": ("Débloquez Des Succès Rétro", "Gagnez des trophées Game Center en courant et en progressant."),
        "es-ES": ("Desbloquea Logros Retro", "Gana trofeos de Game Center mientras corres y mejoras."),
        "es-MX": ("Desbloquea Logros Retro", "Gana trofeos de Game Center mientras corres y mejoras."),
        "ca": ("Desbloqueja Assoliments Retro", "Guanya trofeus de Game Center mentre correixes i millores."),
        "ja": ("レトロ実績を解除", "走って上達しながらGame Centerトロフィーを獲得。"),
        "ko": ("레트로 업적 해제", "레이스하며 성장하고 Game Center 트로피를 획득."),
        "pt-BR": ("Desbloqueie Conquistas Retro", "Ganhe troféus do Game Center enquanto corre e melhora."),
        "pt-PT": ("Desbloqueie Conquistas Retrô", "Ganhe troféus do Game Center enquanto corre e melhora."),
        "zh-Hant": ("解鎖復古成就", "競速進步，贏得 Game Center 獎盃。"),
        "zh-Hans": ("解锁复古成就", "竞速进步，赢得 Game Center 奖杯。"),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Play Solo Or With Friends", "Daily free plays, leaderboards, and live friend races."),
        "de-DE": ("Spiele Solo Oder Mit Freunden", "Tägliche Gratis-Spiele, Bestenlisten und Live-Freundesrennen."),
        "nl-NL": ("Speel Solo Of Met Vrienden", "Dagelijkse gratis runs, scoreborden en live vriendenraces."),
        "it": ("Gioca In Solo O Con Amici", "Partite gratis ogni giorno, classifiche e gare live con amici."),
        "fr-FR": ("Joue Solo Ou Avec Des Amis", "Parties gratuites quotidiennes, classements et courses live entre amis."),
        "fr-CA": ("Jouez Solo Ou Avec Des Amis", "Parties gratuites quotidiennes, classements et courses en direct entre amis."),
        "es-ES": ("Juega Solo O Con Amigos", "Partidas gratis diarias, clasificaciones y carreras live con amigos."),
        "es-MX": ("Juega Solo O Con Amigos", "Partidas gratis diarias, clasificaciones y carreras live con amigos."),
        "ca": ("Juga En Solitari O Amb Amics", "Partides gratis diàries, classificacions i carreres live amb amics."),
        "ja": ("ソロでもフレンドでも", "毎日無料プレイ、ランキング、ライブフレンドレース。"),
        "ko": ("솔로 또는 친구와", "매일 무료 플레이, 리더보드, 라이브 친구 레이스."),
        "pt-BR": ("Jogue Solo Ou Com Amigos", "Partidas grátis diárias, rankings e corridas live com amigos."),
        "pt-PT": ("Jogue A Solo Ou Com Amigos", "Partidas grátis diárias, classificações e corridas ao vivo com amigos."),
        "zh-Hant": ("單人或与好友同玩", "每日免費次數、排行榜與即時好友競賽。"),
        "zh-Hans": ("单人或与好友同玩", "每日免费次数、排行榜与即时好友竞赛。"),
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
    case missingScreenshotCopy(locale: String)
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
        case let .missingScreenshotCopy(locale):
            "Missing Screenshot Studio overlay copy for \(locale)."
        case let .projectOutOfDate(paths):
            "Screenshot Studio files are out of date:\n"
                + paths.joined(separator: "\n")
        }
    }
}

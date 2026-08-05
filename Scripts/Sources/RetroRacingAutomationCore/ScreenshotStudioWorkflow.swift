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
        "tr", "pl",
    ]
    public static let slideCount = 10
    public static let macSlideCount = 9
    public static let watchSlideCount = 7

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
        while watchSlides.count < watchSlideCount {
            watchSlides.append(watchSlides.last ?? [:])
        }
        watchSlides = Array(watchSlides.prefix(watchSlideCount))
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
        "de-DE": ("Rase durch endlosen Verkehr", "Weiche dem Verkehr aus und hol dir Überholungen in diesem Retro-Arcade-Rennen."),
        "nl-NL": ("Race door eindeloos verkeer", "Ontwijk verkeer en pak inhaalslagen in deze retro arcade-racer."),
        "it": ("Corri nel traffico infinito", "Schiva il traffico e conquista sorpassi in questo arcade di corse retro."),
        "fr-FR": ("Fonce dans le trafic sans fin", "Esquive le trafic et enchaîne les dépassements dans cette course arcade retro."),
        "fr-CA": ("Foncez dans le trafic sans fin", "Évitez le trafic et enchaînez les dépassements dans cette course arcade rétro."),
        "es-ES": ("Esquiva tráfico sin fin", "Esquiva tráfico y consigue adelantamientos en un arcade de carreras retro."),
        "es-MX": ("Esquiva carros sin fin", "Esquiva carros y logra rebases en un arcade de carreras retro."),
        "ca": ("Esquiva trànsit sense fi", "Esquiva trànsit i acumula avançaments en este arcade de carreres retro."),
        "ja": ("終わりなき交通を走り抜け", "交通を避け、レトロアーケードで追い抜きを狙おう。"),
        "ko": ("끝없는 교통을 질주", "교통을 피하고 레트로 아케이드에서 추월을 노려보세요."),
        "pt-BR": ("Corra pelo tráfego infinito", "Desvie do tráfego e busque ultrapassagens neste arcade retrô."),
        "pt-PT": ("Corra pelo trânsito infinito", "Desvie do trânsito e procure ultrapassagens neste arcade retro."),
        "zh-Hant": ("穿越無盡車流", "閃避車流，在復古街機中追逐超車。"),
        "zh-Hans": ("穿越无尽车流", "闪避车流，在复古街机中追逐超车。"),
        "tr": ("Sonsuz trafikte yarış", "Trafikten kaç, retro arcade yarışında sollamaları kovala."),
        "pl": ("Pędź przez niekończący się ruch", "Omijaj ruch i wyprzedzaj w wyścigowej grze retro."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Simple Controls. Pure Arcade Action", "Move left. Move right. Don't crash. Deceptively simple."),
        "de-DE": ("Einfache Steuerung. Pure Arcade-Action", "Links. Rechts. Nicht crashen. Täuschend einfach."),
        "nl-NL": ("Simpele besturing. Pure arcade-actie", "Links. Rechts. Niet crashen. Bedrieglijk simpel."),
        "it": ("Controlli semplici. Pura azione arcade", "Sinistra. Destra. Non schiantarti. Ingannatamente semplice."),
        "fr-FR": ("Commandes simples. Action arcade pure", "Gauche. Droite. Ne crash pas. D'une simplicité trompeuse."),
        "fr-CA": ("Commandes simples. Action arcade pure", "Gauche. Droite. Ne crashez pas. D'une simplicité trompeuse."),
        "es-ES": ("Controles simples. Acción arcade pura", "Izquierda. Derecha. No choques. Engañosamente simple."),
        "es-MX": ("Controles simples. Acción arcade pura", "Izquierda. Derecha. No choques. Engañosamente simple."),
        "ca": ("Controls simples. Acció arcade pura", "Esquerra. Dreta. No xoques. Enganyosament simple."),
        "ja": ("シンプル操作。純粋アーケード", "左へ。右へ。クラッシュ禁止。シンプルなのに奥深い。"),
        "ko": ("간단한 조작. 순수 아케이드", "왼쪽. 오른쪽. 충돌 금지. 단순하지만 깊어요."),
        "pt-BR": ("Controles simples. Ação arcade", "Esquerda. Direita. Não bata. Simples de enganar."),
        "pt-PT": ("Controlos simples. Ação arcade", "Esquerda. Direita. Não bata. Enganosamente simples."),
        "zh-Hant": ("簡單操作。純粹街機", "左移。右移。別撞車。看似簡單。"),
        "zh-Hans": ("简单操作。纯粹街机", "左移。右移。别撞车。看似简单。"),
        "tr": ("Basit kontroller. Saf arcade", "Sola git. Sağa git. Çarpma. Göründüğünden zor."),
        "pl": ("Proste sterowanie. Czyste arcade", "W lewo. W prawo. Nie rozbij się. Pozornie proste."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("One Wrong Move. Game Over", "One mistake ends your run. Restart fast, chase your high score!"),
        "de-DE": ("Ein Fehler. Game Over", "Ein Fehler beendet deine Runde. Schnell neu starten, jag deinen Highscore!"),
        "nl-NL": ("Één fout. Game Over", "Één fout beëindigt je run. Snel herstarten, jaag op je highscore!"),
        "it": ("Un errore. Game Over", "Un errore termina la partita. Riparti in fretta, punta al tuo record!"),
        "fr-FR": ("Une erreur. Game Over", "Une erreur termine ta partie. Recommence vite, vise ton record!"),
        "fr-CA": ("Une erreur. Game Over", "Une erreur termine votre partie. Recommencez vite, visez votre record!"),
        "es-ES": ("Un error. Game Over", "Un fallo termina tu partida. Reinicia y persigue tu récord!"),
        "es-MX": ("Un error. Game Over", "Un fallo termina tu partida. Reinicia y persigue tu récord!"),
        "ca": ("Un error. Game Over", "Un error acaba la teua partida. Reinicia i perseguix el teu rècord!"),
        "ja": ("一ミスでゲームオーバー", "一つのミスで終了。すぐ再スタート、ハイスコアを狙え！"),
        "ko": ("한 번의 실수, 게임 오버", "실수 한 번이면 끝. 빠르게 재시작하고 최고 점수에 도전!"),
        "pt-BR": ("Um erro. Fim de jogo", "Um erro encerra a corrida. Reinicie e busque seu recorde!"),
        "pt-PT": ("Um erro. Fim de jogo", "Um erro acaba a corrida. Reinicie e procure o seu recorde!"),
        "zh-Hant": ("一步失誤，遊戲結束", "一個失誤就結束。快速重來，挑戰最高分！"),
        "zh-Hans": ("一步失误，游戏结束", "一个失误就结束。快速重来，挑战最高分！"),
        "tr": ("Tek hata. Oyun bitti", "Bir hata yarışı bitirir. Hızla başla, rekorunu kovala!"),
        "pl": ("Jeden błąd. Koniec gry", "Jeden błąd kończy przejazd. Szybki restart i pogoń za rekordem!"),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Accessibility Front and Center", "VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings."),
        "de-DE": ("Barrierefreiheit im Mittelpunkt", "VoiceOver, Audiohinweise, Haptik, größerer Text und anpassbare Spieleinstellungen."),
        "nl-NL": ("Toegankelijkheid voorop", "VoiceOver, audiosignalen, haptiek, grotere tekst en aanpasbare spelinstellingen."),
        "it": ("Accessibilità al centro", "VoiceOver, segnali audio, haptica, testo più grande e impostazioni di gioco adattabili."),
        "fr-FR": ("Accessibilité au premier plan", "VoiceOver, indices audio, haptique, texte plus grand et réglages de jeu adaptables."),
        "fr-CA": ("Accessibilité au premier plan", "VoiceOver, indices audio, haptique, texte plus grand et réglages de jeu adaptables."),
        "es-ES": ("Accesibilidad en primer plano", "VoiceOver, pistas de audio, hápticos, texto más grande y ajustes de juego adaptables."),
        "es-MX": ("Accesibilidad en primer plano", "VoiceOver, pistas de audio, hápticos, texto más grande y ajustes de juego adaptables."),
        "ca": ("Accessibilitat al davant", "VoiceOver, pistes d'àudio, hàptics, text més gran i opcions de joc adaptables."),
        "ja": ("アクセシビリティを前面に", "VoiceOver、音声キュー、触覚、大きい文字、調整可能な設定。"),
        "ko": ("접근성을 중심에", "VoiceOver, 오디오 큐, 햅틱, 큰 텍스트, 맞춤 설정."),
        "pt-BR": ("Acessibilidade em destaque", "VoiceOver, pistas sonoras, háptico, texto maior e ajustes adaptáveis."),
        "pt-PT": ("Acessibilidade em destaque", "VoiceOver, pistas sonoras, háptico, texto maior e definições adaptáveis."),
        "zh-Hant": ("無障礙設計放首位", "VoiceOver、音效提示、觸覺、較大字體與可調設定。"),
        "zh-Hans": ("无障碍设计放首位", "VoiceOver、音效提示、触觉、较大字体与可调设置。"),
        "tr": ("Erişilebilirlik her şeyden önce", "VoiceOver, ses ipuçları, dokunsal geri bildirim, büyük metin ve uyarlanabilir ayarlar."),
        "pl": ("Dostępność na pierwszym planie", "VoiceOver, wskazówki dźwiękowe, haptyka, większy tekst i ustawienia adaptacyjne."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Race Friends with SharePlay", "Challenge friends for free. Countdown, compete, rematch."),
        "de-DE": ("Rase mit Freunden per SharePlay", "Fordere Freunde gratis heraus. Countdown, Wettbewerb, Rematch."),
        "nl-NL": ("Race met vrienden via SharePlay", "Daag vrienden gratis uit. Countdown, strijd, rematch."),
        "it": ("Corri con amici via SharePlay", "Sfida gli amici gratis. Countdown, gara, rematch."),
        "fr-FR": ("Course avec des amis via SharePlay", "Défie tes amis gratuitement. Compte à rebours, course, revanche."),
        "fr-CA": ("Coursez avec des amis via SharePlay", "Défiez vos amis gratuitement. Compte à rebours, course, revanche."),
        "es-ES": ("Corre con amigos con SharePlay", "Reta a amigos gratis. Cuenta atrás, compite, revancha."),
        "es-MX": ("Corre con amigos con SharePlay", "Reta a amigos gratis. Cuenta atrás, compite, revancha."),
        "ca": ("Corre amb amics amb SharePlay", "Desafia amistats gratis. Compte enrere, competeix, revenja."),
        "ja": ("SharePlayでフレンドとレース", "無料でフレンドに挑戦。カウントダウン、対戦、リマッチ。"),
        "ko": ("SharePlay로 친구와 레이스", "무료로 친구에게 도전. 카운트다운, 대전, 리매치."),
        "pt-BR": ("Corra com amigos no SharePlay", "Desafie amigos grátis. Contagem, competição, revanche."),
        "pt-PT": ("Corra com amigos no SharePlay", "Desafie amigos grátis. Contagem, competição, desforra."),
        "zh-Hant": ("SharePlay 與好友競賽", "免費挑戰好友。倒數、對戰、重賽。"),
        "zh-Hans": ("SharePlay 与好友竞赛", "免费挑战好友。倒数、对战、重赛。"),
        "tr": ("SharePlay ile arkadaşlarınla yarış", "Arkadaşlarına ücretsiz meydan oku. Geri sayım, yarış, rövanş."),
        "pl": ("Ścigaj się ze znajomymi przez SharePlay", "Rzuć znajomym bezpłatne wyzwanie. Odliczanie, wyścig, rewanż."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Climb the Leaderboard", "Game Center scores and friend markers keep every run competitive."),
        "de-DE": ("Erklimme die Bestenliste", "Game-Center-Punkte und Freundesmarker halten jede Runde spannend."),
        "nl-NL": ("Klim op het scorebord", "Game Center-scores en vriendenmarkeringen houden elke run spannend."),
        "it": ("Scala la classifica", "Punteggi Game Center e marcatori amici rendono ogni gara competitiva."),
        "fr-FR": ("Grimpe au classement", "Scores Game Center et marqueurs d'amis rendent chaque course compétitive."),
        "fr-CA": ("Grimpez au classement", "Les scores Game Center et les marqueurs d'amis rendent chaque course compétitive."),
        "es-ES": ("Escala la clasificación", "Puntuaciones de Game Center y marcadores de amigos mantienen cada partida competitiva."),
        "es-MX": ("Escala la clasificación", "Puntuaciones de Game Center y marcadores de amigos mantienen cada partida competitiva."),
        "ca": ("Puja en la classificació", "Puntuacions de Game Center i marcadors d'amistats mantenen cada partida competitiva."),
        "ja": ("ランキングを駆け上がれ", "Game Centerスコアとフレンドマーカーで毎ランが熱い。"),
        "ko": ("리더보드를 올라가세요", "Game Center 점수와 친구 마커로 매 판이 경쟁적."),
        "pt-BR": ("Suba no ranking", "Pontuações do Game Center e marcadores mantêm cada corrida competitiva."),
        "pt-PT": ("Suba na classificação", "Pontuações do Game Center e marcadores mantêm cada corrida competitiva."),
        "zh-Hant": ("衝上排行榜", "Game Center 分數與好友標記讓每局都競爭感十足。"),
        "zh-Hans": ("冲上排行榜", "Game Center 分数与好友标记让每局都竞争感十足。"),
        "tr": ("Liderlik tablosunda yüksel", "Game Center skorları ve arkadaş işaretleri her yarışı rekabetçi kılar."),
        "pl": ("Wspinaj się w rankingu", "Wyniki Game Center i znaczniki znajomych podkręcają każdy przejazd."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Customize Your Experience", "Tune volume, haptics, controls… Go Cruise, Fast, or Rapid!"),
        "en-GB": ("Customise Your Experience", "Tune volume, haptics, controls… Go Cruise, Fast, or Rapid!"),
        "en-AU": ("Customise Your Experience", "Tune volume, haptics, controls… Go Cruise, Fast, or Rapid!"),
        "en-CA": ("Customize Your Experience", "Tune volume, haptics, controls… Go Cruise, Fast, or Rapid!"),
        "de-DE": ("Passe dein Erlebnis an", "Lautstärke, Haptik, Steuerung… Cruise, Fast oder Rapid!"),
        "nl-NL": ("Pas je ervaring aan", "Volume, haptiek, besturing… Cruise, Fast of Rapid!"),
        "it": ("Personalizza la tua esperienza", "Volume, haptica, controlli… Cruise, Fast o Rapid!"),
        "fr-FR": ("Personnalise ton expérience", "Volume, haptique, commandes… Cruise, Fast ou Rapid!"),
        "fr-CA": ("Personnalisez votre expérience", "Volume, haptique, commandes… Cruise, Fast ou Rapid!"),
        "es-ES": ("Personaliza tu experiencia", "Volumen, hápticos, controles… Cruise, Fast o Rapid!"),
        "es-MX": ("Personaliza tu experiencia", "Volumen, hápticos, controles… Cruise, Fast o Rapid!"),
        "ca": ("Personalitza la teua experiència", "Volum, hàptics, controls… Cruise, Fast o Rapid!"),
        "ja": ("体験をカスタマイズ", "音量、触覚、操作… Cruise、Fast、Rapid！"),
        "ko": ("경험을 맞춤 설정", "볼륨, 햅틱, 조작… Cruise, Fast, Rapid!"),
        "pt-BR": ("Personalize sua experiência", "Volume, háptico, controles… Cruise, Fast ou Rapid!"),
        "pt-PT": ("Personalize a sua experiência", "Volume, háptico, controlos… Cruise, Fast ou Rapid!"),
        "zh-Hant": ("自訂你的體驗", "調整音量、觸覺、操作… Cruise、Fast 或 Rapid！"),
        "zh-Hans": ("自定义你的体验", "调整音量、触觉、操作… Cruise、Fast 或 Rapid！"),
        "tr": ("Deneyimini özelleştir", "Ses, dokunsal geri bildirim, kontroller… Cruise, Hızlı veya Rapid!"),
        "pl": ("Dostosuj rozgrywkę", "Głośność, haptyka, sterowanie… Cruise, Szybki albo Rapid!"),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Choose Your Retro Aesthetic", "Switch between four retro eras, from Pocket to 16-Bit."),
        "en-GB": ("Choose Your Retro Aesthetic", "Switch between four retro eras, from Pocket to 16-Bit."),
        "en-AU": ("Choose Your Retro Aesthetic", "Switch between four retro eras, from Pocket to 16-Bit."),
        "en-CA": ("Choose Your Retro Aesthetic", "Switch between four retro eras, from Pocket to 16-Bit."),
        "de-DE": ("Wähle deinen Retro-Look", "Wechsle zwischen vier Retro-Epochen, von Pocket bis 16-Bit."),
        "nl-NL": ("Kies je retro-stijl", "Wissel tussen vier retro-tijdperken, van Pocket tot 16-Bit."),
        "it": ("Scegli la tua estetica retro", "Passa tra quattro epoche retrò, da Pocket a 16-Bit."),
        "fr-FR": ("Choisis ton style retro", "Passe entre quatre époques rétro, de Pocket à 16-Bit."),
        "fr-CA": ("Choisissez votre style rétro", "Passez entre quatre époques rétro, de Pocket à 16-Bit."),
        "es-ES": ("Elige tu estética retro", "Cambia entre cuatro eras retro, desde Pocket hasta 16-Bit."),
        "es-MX": ("Elige tu estética retro", "Cambia entre cuatro eras retro, desde Pocket hasta 16-Bit."),
        "ca": ("Tria la teua estètica retro", "Canvia entre quatre èpoques retro, de Pocket a 16-Bit."),
        "ja": ("レトロ美学を選ぼう", "Pocketから16-Bitまで、4つのレトロ時代を切り替え。"),
        "ko": ("레트로 스타일 선택", "Pocket부터 16-Bit까지 네 가지 레트로 시대를 전환하세요."),
        "pt-BR": ("Escolha seu visual retro", "Alterne entre quatro eras retrô, de Pocket a 16-Bit."),
        "pt-PT": ("Escolha o seu visual retro", "Alterne entre quatro eras retro, de Pocket a 16-Bit."),
        "zh-Hant": ("選擇復古風格", "在四個復古時代間切換，從 Pocket 到 16-Bit。"),
        "zh-Hans": ("选择复古风格", "在四个复古时代间切换，从 Pocket 到 16-Bit。"),
        "tr": ("Retro tarzını seç", "Pocket'tan 16-Bit'e dört retro dönem arasında geçiş yap."),
        "pl": ("Wybierz swój styl retro", "Przełączaj cztery epoki retro, od Pocket po 16-Bit."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Unlock Retro Achievements", "Earn Game Center trophies as you race and improve."),
        "de-DE": ("Schalte Retro-Erfolge frei", "Verdiene Game-Center-Trophäen, während du fährst und dich verbesserst."),
        "nl-NL": ("Ontgrendel retro prestaties", "Verdien Game Center-trofeeën terwijl je rijdt en verbetert."),
        "it": ("Sblocca obiettivi retro", "Ottieni trofei Game Center mentre corri e migliori."),
        "fr-FR": ("Débloque des succès retro", "Gagne des trophées Game Center en courant et en progressant."),
        "fr-CA": ("Débloquez des succès rétro", "Gagnez des trophées Game Center en courant et en progressant."),
        "es-ES": ("Desbloquea logros retro", "Gana trofeos de Game Center mientras corres y mejoras."),
        "es-MX": ("Desbloquea logros retro", "Gana trofeos de Game Center mientras corres y mejoras."),
        "ca": ("Desbloqueja assoliments retro", "Guanya trofeus de Game Center mentre corres i millores."),
        "ja": ("レトロ実績を解除", "走って上達しながらGame Centerトロフィーを獲得。"),
        "ko": ("레트로 업적 해제", "레이스하며 성장하고 Game Center 트로피를 획득."),
        "pt-BR": ("Desbloqueie conquistas retro", "Ganhe troféus do Game Center enquanto corre e melhora."),
        "pt-PT": ("Desbloqueie conquistas retro", "Ganhe troféus do Game Center enquanto corre e melhora."),
        "zh-Hant": ("解鎖復古成就", "競速進步，贏得 Game Center 獎盃。"),
        "zh-Hans": ("解锁复古成就", "竞速进步，赢得 Game Center 奖杯。"),
        "tr": ("Retro başarımları aç", "Yarışıp geliştikçe Game Center kupaları kazan."),
        "pl": ("Odblokuj osiągnięcia retro", "Zdobywaj trofea Game Center podczas wyścigów i rozwoju."),
    ]),
    SlideCopy(byLocale: [
        "en-US": ("Play Solo Or With Friends", "Daily free plays, leaderboards, and live friend races."),
        "de-DE": ("Spiele solo oder mit Freunden", "Tägliche Gratis-Spiele, Bestenlisten und Live-Freundesrennen."),
        "nl-NL": ("Speel solo of met vrienden", "Dagelijkse gratis runs, scoreborden en live vriendenraces."),
        "it": ("Gioca in solo o con amici", "Partite gratis ogni giorno, classifiche e gare live con amici."),
        "fr-FR": ("Joue solo ou avec des amis", "Parties gratuites quotidiennes, classements et courses live entre amis."),
        "fr-CA": ("Jouez solo ou avec des amis", "Parties gratuites quotidiennes, classements et courses en direct entre amis."),
        "es-ES": ("Juega solo o con amigos", "Partidas gratis diarias, clasificaciones y carreras live con amigos."),
        "es-MX": ("Juega solo o con amigos", "Partidas gratis diarias, clasificaciones y carreras live con amigos."),
        "ca": ("Juga en solitari o amb amics", "Partides gratis diàries, classificacions i carreres live amb amics."),
        "ja": ("ソロでもフレンドでも", "毎日無料プレイ、ランキング、ライブフレンドレース。"),
        "ko": ("솔로 또는 친구와", "매일 무료 플레이, 리더보드, 라이브 친구 레이스."),
        "pt-BR": ("Jogue solo ou com amigos", "Partidas grátis diárias, rankings e corridas live com amigos."),
        "pt-PT": ("Jogue a solo ou com amigos", "Partidas grátis diárias, classificações e corridas ao vivo com amigos."),
        "zh-Hant": ("單人或與好友同玩", "每日免費次數、排行榜與即時好友競賽。"),
        "zh-Hans": ("单人或与好友同玩", "每日免费次数、排行榜与即时好友竞赛。"),
        "tr": ("Tek başına veya arkadaşlarınla oyna", "Günlük ücretsiz oyunlar, liderlik tabloları ve canlı arkadaş yarışları."),
        "pl": ("Graj solo lub ze znajomymi", "Codzienne bezpłatne gry, rankingi i wyścigi ze znajomymi na żywo."),
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

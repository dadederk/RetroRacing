import SwiftUI
import RetroRacingShared
import CoreText
import AVFoundation

@main
struct RetroRacingApp: App {
    private let leaderboardConfiguration = iOSLeaderboardConfiguration()
    #if canImport(UIKit)
    private let authenticationPresenter = iOSAuthenticationPresenter()
    #else
    private let authenticationPresenter = NoOpAuthenticationPresenter()
    #endif
    private let gameCenterService: GameCenterService
    private let ratingService: RatingService
    private let themeManager: ThemeManager

    init() {
        Self.configureAudioSession()
        Self.registerCustomFont()
        gameCenterService = GameCenterService(
            configuration: leaderboardConfiguration,
            authenticationPresenter: authenticationPresenter
        )
        #if canImport(UIKit)
        ratingService = StoreReviewService(ratingProvider: iOSRatingServiceProvider())
        #else
        ratingService = StoreReviewService(ratingProvider: MacRatingServiceProvider())
        #endif
        themeManager = ThemeManager(
            initialThemes: [ClassicTheme(), GameBoyTheme()],
            userDefaults: .standard
        )
    }

    /// Configures audio session so game sounds play (especially on device).
    private static func configureAudioSession() {
        #if canImport(UIKit)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Non-fatal; sound may still work in simulator
        }
        #endif
    }

    /// Registers the custom font from the shared framework so `.font(.custom("PressStart2P-Regular", size:))` works. Font lives in RetroRacingShared only.
    private static func registerCustomFont() {
        let fontName = "PressStart2P-Regular.ttf"
        let frameworkBundle = Bundle(for: GameScene.self)
        let urls: [URL] = [
            frameworkBundle.url(forResource: "PressStart2P-Regular", withExtension: "ttf"),
            frameworkBundle.url(forResource: fontName, withExtension: nil),
            frameworkBundle.resourceURL?.appendingPathComponent("Resources/Font/\(fontName)", isDirectory: false),
            frameworkBundle.resourceURL?.appendingPathComponent("Font/\(fontName)", isDirectory: false),
            Bundle.main.url(forResource: "PressStart2P-Regular", withExtension: "ttf"),
            Bundle.main.resourceURL?.appendingPathComponent("Resources/Font/\(fontName)", isDirectory: false),
        ].compactMap { $0 }
        for url in urls where (try? url.checkResourceIsReachable()) == true {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                AppLog.log(AppLog.font, "font registered from \(url.lastPathComponent)")
                return
            }
        }
        AppLog.error(AppLog.font, "font '\(fontName)' NOT registered (no reachable URL)")
    }

    var body: some Scene {
        WindowGroup {
            MenuView(
                leaderboardService: gameCenterService,
                gameCenterService: gameCenterService,
                ratingService: ratingService,
                leaderboardConfiguration: leaderboardConfiguration,
                authenticationPresenter: authenticationPresenter,
                themeManager: themeManager
            )
        }
    }
}

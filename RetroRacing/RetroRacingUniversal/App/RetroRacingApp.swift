//
//  RetroRacingApp.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
import RetroRacingShared
import CoreText
import AVFoundation
import GameKit
#if canImport(UIKit)
import UIKit
#endif
#if canImport(UIKit) && !os(tvOS)
import CoreHaptics
#endif

/// App entry point assembling shared services and presenting the universal menu scene.
@main
struct RetroRacingApp: App {
    private let leaderboardConfiguration: LeaderboardConfiguration
    #if canImport(UIKit)
    private let authenticationPresenter = AuthenticationPresenterUniversal()
    #else
    private let authenticationPresenter = NoOpAuthenticationPresenter()
    #endif
    private let gameCenterService: GameCenterService
    private let ratingService: RatingService
    private let themeManager: ThemeManager
    private let fontPreferenceStore: FontPreferenceStore
    private let hapticController: HapticFeedbackController
    private let supportsHapticFeedback: Bool
    private let highestScoreStore: HighestScoreStore

    init() {
        Self.configureAudioSession()
        Self.configureGameCenterAccessPoint()
        let customFontAvailable = Self.registerCustomFont()
        let userDefaults = InfrastructureDefaults.userDefaults
        #if os(macOS)
        leaderboardConfiguration = LeaderboardConfigurationMac()
        #elseif canImport(UIKit)
        if UIDevice.current.userInterfaceIdiom == .pad {
            leaderboardConfiguration = LeaderboardConfigurationIPad()
        } else {
            leaderboardConfiguration = LeaderboardConfigurationUniversal()
        }
        #else
        leaderboardConfiguration = LeaderboardConfigurationUniversal()
        #endif
        let leaderboardPlatformConfig = LeaderboardPlatformConfig(
            leaderboardID: leaderboardConfiguration.leaderboardID,
            authenticateHandlerSetter: { presenter in
                GKLocalPlayer.local.authenticateHandler = { viewController, error in
                    if let viewController = viewController {
                        presenter.presentAuthenticationUI(viewController)
                        return
                    }
                    // When Game Center finishes (success or failure) without UI, notify listeners so they can refresh state.
                    NotificationCenter.default.post(name: .GKPlayerAuthenticationDidChangeNotificationName, object: error)
                }
            }
        )
        gameCenterService = GameCenterService(
            configuration: leaderboardConfiguration,
            authenticationPresenter: authenticationPresenter,
            authenticateHandlerSetter: leaderboardPlatformConfig.authenticateHandlerSetter
        )
        #if canImport(UIKit)
        ratingService = StoreReviewService(userDefaults: userDefaults, ratingProvider: RatingServiceProviderUniversal())
        #else
        ratingService = StoreReviewService(userDefaults: userDefaults, ratingProvider: RatingServiceProviderMac())
        #endif
        let themeConfig = ThemePlatformConfig(
            defaultThemeID: "lcd",
            availableThemes: [LCDTheme(), GameBoyTheme()]
        )
        themeManager = ThemeManager(
            initialThemes: themeConfig.availableThemes,
            defaultThemeID: themeConfig.defaultThemeID,
            userDefaults: userDefaults
        )
        fontPreferenceStore = FontPreferenceStore(userDefaults: userDefaults, customFontAvailable: customFontAvailable)
        let hapticsConfig = HapticsPlatformConfig(
            supportsHaptics: Self.deviceSupportsHapticFeedback(),
            controllerProvider: { Self.makeHapticsController(userDefaults: userDefaults) }
        )
        hapticController = hapticsConfig.controllerProvider()
        supportsHapticFeedback = hapticsConfig.supportsHaptics
        highestScoreStore = UserDefaultsHighestScoreStore(userDefaults: userDefaults)
    }

    /// Returns true when the device has haptic hardware. Used to show/hide haptic setting (configuration injection).
    private static func deviceSupportsHapticFeedback() -> Bool {
        #if canImport(UIKit) && !os(tvOS)
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        #else
        return false
        #endif
    }

    /// Configures access point location but keeps it hidden; we present GC explicitly from the Leaderboard button.
    private static func configureGameCenterAccessPoint() {
        GKAccessPoint.shared.location = .topTrailing
        GKAccessPoint.shared.isActive = false
    }

    private static func makeHapticsController(userDefaults: UserDefaults) -> HapticFeedbackController {
        #if canImport(UIKit) && !os(tvOS)
        return UIKitHapticFeedbackController(userDefaults: userDefaults)
        #else
        return NoOpHapticFeedbackController()
        #endif
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
    /// - Returns: true if registration succeeded (use to show font settings).
    private static func registerCustomFont() -> Bool {
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
                return true
            }
        }
        AppLog.error(AppLog.font, "font '\(fontName)' NOT registered (no reachable URL)")
        return false
    }

    var body: some Scene {
        WindowGroup {
            MenuView(
                leaderboardService: gameCenterService,
                gameCenterService: gameCenterService,
                ratingService: ratingService,
                leaderboardConfiguration: leaderboardConfiguration,
                authenticationPresenter: authenticationPresenter,
                themeManager: themeManager,
                fontPreferenceStore: fontPreferenceStore,
                hapticController: hapticController,
                supportsHapticFeedback: supportsHapticFeedback,
                highestScoreStore: highestScoreStore
            )
        }
    }
}

import SwiftUI
import RetroRacingShared
import CoreText
import AVFoundation
import GameKit
#if canImport(UIKit) && !os(tvOS)
import CoreHaptics
#endif

@main
struct RetroRacingApp: App {
    private let leaderboardConfiguration = LeaderboardConfigurationUniversal()
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

    init() {
        Self.configureAudioSession()
        let customFontAvailable = Self.registerCustomFont()
        gameCenterService = GameCenterService(
            configuration: leaderboardConfiguration,
            authenticationPresenter: authenticationPresenter,
            authenticateHandlerSetter: { presenter in
                GKLocalPlayer.local.authenticateHandler = { viewController, _ in
                    guard let viewController = viewController else { return }
                    presenter.presentAuthenticationUI(viewController)
                }
            }
        )
        #if canImport(UIKit)
        ratingService = StoreReviewService(ratingProvider: RatingServiceProviderUniversal())
        #else
        ratingService = StoreReviewService(ratingProvider: RatingServiceProviderMac())
        #endif
        themeManager = ThemeManager(
            initialThemes: [LCDTheme(), GameBoyTheme()],
            defaultThemeID: "lcd",
            userDefaults: .standard
        )
        fontPreferenceStore = FontPreferenceStore(customFontAvailable: customFontAvailable)
        hapticController = UIKitHapticFeedbackController()
        supportsHapticFeedback = Self.deviceSupportsHapticFeedback()
    }

    /// Returns true when the device has haptic hardware. Used to show/hide haptic setting (configuration injection).
    private static func deviceSupportsHapticFeedback() -> Bool {
        #if canImport(UIKit) && !os(tvOS)
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        #else
        return false
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
                supportsHapticFeedback: supportsHapticFeedback
            )
        }
    }
}

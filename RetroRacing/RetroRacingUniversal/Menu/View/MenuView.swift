import SwiftUI
import RetroRacingShared
import GameKit
#if os(macOS)
import StoreKit
#endif

struct MenuView: View {
    let leaderboardService: LeaderboardService
    let gameCenterService: GameCenterService
    let ratingService: RatingService
    let leaderboardConfiguration: LeaderboardConfiguration
    let authenticationPresenter: AuthenticationPresenter
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    let hapticController: HapticFeedbackController
    /// Injected by app; when false, haptic setting is hidden (device has no haptics).
    let supportsHapticFeedback: Bool

    #if os(macOS)
    @Environment(\.requestReview) private var requestReview
    #endif
    @State private var showGame = false
    @State private var showLeaderboard = false
    @State private var showSettings = false
    #if canImport(UIKit)
    @State private var authViewControllerToPresent: UIViewController?
    #endif
    @State private var showSignInAlert = false

    private static var settingsToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .primaryAction
        #else
        .topBarTrailing
        #endif
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(GameLocalizedStrings.string("gameName"))
                    .font(fontPreferenceStore.font(size: 27))
                    .dynamicTypeSize(.xSmall ... .xxxLarge)
                    .padding(.bottom, 40)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 24) {
                    menuPlayButton
                    menuLeaderboardButton
                    menuRateButton
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: Self.settingsToolbarPlacement) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(GameLocalizedStrings.string("settings"))
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(themeManager: themeManager, fontPreferenceStore: fontPreferenceStore, supportsHapticFeedback: supportsHapticFeedback)
            }
            .navigationDestination(isPresented: $showGame) {
                GameView(
                    leaderboardService: leaderboardService,
                    ratingService: ratingService,
                    theme: themeManager.currentTheme,
                    hapticController: hapticController,
                    fontPreferenceStore: fontPreferenceStore
                )
            }
            .modifier(LeaderboardPresentationModifier(
                isPresented: $showLeaderboard,
                leaderboardID: leaderboardConfiguration.leaderboardID
            ))
            #if canImport(UIKit)
            .fullScreenCover(item: authVCItem) { item in
                AuthViewControllerWrapper(viewController: item.vc) {
                    authViewControllerToPresent = nil
                }
            }
            #endif
            .alert(GameLocalizedStrings.string("leaderboard"), isPresented: $showSignInAlert) {
                Button(GameLocalizedStrings.string("ok"), role: .cancel) {}
            } message: {
                Text(GameLocalizedStrings.string("Sign in to Game Center to view the leaderboard."))
            }
        }
        .onAppear {
            #if canImport(UIKit)
            if let universalPresenter = authenticationPresenter as? AuthenticationPresenterUniversal {
                universalPresenter.onPresent = { [self] vc in
                    authViewControllerToPresent = vc
                }
            }
            #endif
            gameCenterService.authenticate(presenter: authenticationPresenter)
        }
    }

    @ViewBuilder
    private var menuPlayButton: some View {
        Button {
            showGame = true
        } label: {
            Text(GameLocalizedStrings.string("play"))
                .font(fontPreferenceStore.font(size: 18))
        }
        .buttonStyle(.glassProminent)
    }

    @ViewBuilder
    private var menuLeaderboardButton: some View {
        Button {
            if gameCenterService.isAuthenticated() {
                showLeaderboard = true
            } else {
                showSignInAlert = true
            }
        } label: {
            Text(GameLocalizedStrings.string("leaderboard"))
                .font(fontPreferenceStore.font(size: 18))
        }
        .buttonStyle(.glass)
    }

    @ViewBuilder
    private var menuRateButton: some View {
        Button {
            #if os(macOS)
            requestReview()
            #else
            ratingService.requestRating()
            #endif
        } label: {
            Text(GameLocalizedStrings.string("rateApp"))
                .font(fontPreferenceStore.font(size: 18))
        }
        .buttonStyle(.glass)
    }

    #if canImport(UIKit)
    private var authVCItem: Binding<IdentifiableVC?> {
        Binding(
            get: { authViewControllerToPresent.map { IdentifiableVC(vc: $0) } },
            set: { authViewControllerToPresent = $0?.vc }
        )
    }
    #endif
}

#if canImport(UIKit)
private struct IdentifiableVC: Identifiable {
    let id = UUID()
    let vc: UIViewController
}
#endif

/// Presents leaderboard: fullScreenCover on iOS/tvOS, sheet on macOS.
private struct LeaderboardPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let leaderboardID: String

    func body(content: Content) -> some View {
        #if canImport(UIKit)
        content
            .fullScreenCover(isPresented: $isPresented) {
                LeaderboardView(leaderboardID: leaderboardID) {
                    isPresented = false
                }
            }
        #else
        content
            .sheet(isPresented: $isPresented) {
                LeaderboardView(leaderboardID: leaderboardID) {
                    isPresented = false
                }
            }
        #endif
    }
}


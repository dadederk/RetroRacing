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

    #if os(macOS)
    @Environment(\.requestReview) private var requestReview
    #endif
    @State private var showGame = false
    @State private var showLeaderboard = false
    #if canImport(UIKit)
    @State private var authViewControllerToPresent: UIViewController?
    #endif
    @State private var showSignInAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(String(localized: "gameName"))
                    .font(.custom("PressStart2P-Regular", size: 27))
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
            .navigationDestination(isPresented: $showGame) {
                GameView(
                    leaderboardService: leaderboardService,
                    ratingService: ratingService,
                    theme: themeManager.currentTheme
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
            .alert(String(localized: "leaderboard"), isPresented: $showSignInAlert) {
                Button(String(localized: "ok"), role: .cancel) {}
            } message: {
                Text(String(localized: "Sign in to Game Center to view the leaderboard."))
            }
        }
        .onAppear {
            #if canImport(UIKit)
            if let iosPresenter = authenticationPresenter as? iOSAuthenticationPresenter {
                iosPresenter.onPresent = { [self] vc in
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
            Text(String(localized: "play"))
                .font(.custom("PressStart2P-Regular", size: 18))
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
            Text(String(localized: "leaderboard"))
                .font(.custom("PressStart2P-Regular", size: 18))
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
            Text(String(localized: "rateApp"))
                .font(.custom("PressStart2P-Regular", size: 18))
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


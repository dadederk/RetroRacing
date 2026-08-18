//
//  MenuAuthModelTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 05/08/2026.
//

#if canImport(UIKit) && canImport(GameKit) && !os(watchOS)
import XCTest
import UIKit

@testable import RetroRacingShared

@MainActor
final class MenuAuthModelTests: XCTestCase {
    func testGivenSameAuthenticationControllerThenPresentationIdentityRemainsStable() {
        let viewController = UIViewController()

        XCTAssertEqual(
            IdentifiableVC(vc: viewController).id,
            IdentifiableVC(vc: viewController).id
        )
    }

    func testGivenAuthenticationDismissalReportedTwiceThenDismissHandlerRunsOnce() {
        let container = AuthContainerViewController()
        var dismissalCount = 0
        container.onDismiss = { dismissalCount += 1 }
        let presentationController = UIPresentationController(
            presentedViewController: UIViewController(),
            presenting: nil
        )

        container.presentationControllerDidDismiss(presentationController)
        container.presentationControllerDidDismiss(presentationController)

        XCTAssertEqual(dismissalCount, 1)
    }

    func testGivenDismissedAuthenticationWhenGameKitOffersAnotherControllerThenItIsIgnored() {
        let presenter = AuthenticationPresenterUniversal()
        let model = makeModel(authenticationPresenter: presenter)
        model.configurePresentationHandler()
        presenter.presentAuthenticationUI(UIViewController())
        model.authenticationPresentationDidDismiss()

        presenter.presentAuthenticationUI(UIViewController())

        XCTAssertNil(model.authViewControllerToPresent)
    }

    func testGivenDismissedAutomaticAuthenticationWhenMenuReappearsThenAuthenticationDoesNotRestart() {
        // Given
        var authenticationRequestCount = 0
        let service = GameCenterService(
            configuration: MockLeaderboardConfiguration(leaderboardID: "test123"),
            friendSnapshotService: GameCenterFriendSnapshotService(
                configuration: .standard,
                avatarCache: GameCenterAvatarCache()
            ),
            authenticateHandlerSetter: { _ in
                authenticationRequestCount += 1
            },
            isDebugBuild: true,
            allowDebugScoreSubmission: false,
            isAuthenticatedProvider: { false }
        )
        let model = MenuAuthModel(
            gameCenterService: service,
            authenticationPresenter: AuthenticationPresenterUniversal()
        )

        // When
        model.startAuthentication(startedByUser: false)
        model.startAuthentication(startedByUser: false)

        // Then
        XCTAssertEqual(authenticationRequestCount, 1)
        model.cancelAuthTimeout()
    }

    func testGivenAuthenticatedPlayerWhenLeaderboardRequestedThenPresentationIsImmediate() {
        // Given
        let model = makeModel(
            authenticationPresenter: AuthenticationPresenterUniversal(),
            isAuthenticatedProvider: { true }
        )

        // When
        let result = model.requestLeaderboardPresentation(leaderboardID: "rapid")

        // Then
        XCTAssertEqual(result, .present(leaderboardID: "rapid"))
        XCTAssertNil(model.takePendingLeaderboardIDIfReady())
    }

    func testGivenUnauthenticatedPlayerWhenLeaderboardRequestedThenAuthenticationStartsAndPresentationIsDeferred() {
        // Given
        var authenticationRequestCount = 0
        let model = makeModel(
            authenticationPresenter: AuthenticationPresenterUniversal(),
            authenticateHandlerSetter: { _ in authenticationRequestCount += 1 }
        )

        // When
        let result = model.requestLeaderboardPresentation(leaderboardID: "rapid")

        // Then
        XCTAssertEqual(result, .authenticationRequested)
        XCTAssertEqual(authenticationRequestCount, 1)
        XCTAssertNil(model.takePendingLeaderboardIDIfReady())
        model.cancelAuthTimeout()
    }

    func testGivenPendingLeaderboardWhenAuthenticationSucceedsThenPresentationIsReturnedExactlyOnce() {
        // Given
        var isAuthenticated = false
        let model = makeModel(
            authenticationPresenter: AuthenticationPresenterUniversal(),
            isAuthenticatedProvider: { isAuthenticated }
        )
        _ = model.requestLeaderboardPresentation(leaderboardID: "rapid")

        // When
        isAuthenticated = true
        model.authenticationStateDidChange(error: nil)

        // Then
        XCTAssertEqual(model.takePendingLeaderboardIDIfReady(), "rapid")
        XCTAssertNil(model.takePendingLeaderboardIDIfReady())
    }

    func testGivenAuthenticatedPlayerWithAuthenticationCoverWhenCoverDismissesThenDeferredPresentationContinues() {
        // Given
        var isAuthenticated = false
        let authenticationViewController = UIViewController()
        let presenter = AuthenticationPresenterUniversal()
        let model = makeModel(
            authenticationPresenter: presenter,
            authenticateHandlerSetter: { presenter in
                presenter.presentAuthenticationUI(authenticationViewController)
            },
            isAuthenticatedProvider: { isAuthenticated }
        )
        model.configurePresentationHandler()
        _ = model.requestLeaderboardPresentation(leaderboardID: "rapid")
        isAuthenticated = true
        model.authenticationStateDidChange(error: nil)

        // When
        let presentationWhileCovered = model.takePendingLeaderboardIDIfReady()
        model.authenticationPresentationDidDismiss()
        model.authenticationCoverDidDismiss()

        // Then
        XCTAssertNil(presentationWhileCovered)
        XCTAssertEqual(model.takePendingLeaderboardIDIfReady(), "rapid")
    }

    func testGivenCancelledAuthenticationCoverWhenDismissedThenPendingPresentationIsCleared() {
        // Given
        var isAuthenticated = false
        let presenter = AuthenticationPresenterUniversal()
        let model = makeModel(
            authenticationPresenter: presenter,
            authenticateHandlerSetter: { presenter in
                presenter.presentAuthenticationUI(UIViewController())
            },
            isAuthenticatedProvider: { isAuthenticated }
        )
        model.configurePresentationHandler()
        _ = model.requestLeaderboardPresentation(leaderboardID: "rapid")

        // When
        model.authenticationPresentationDidDismiss()
        model.authenticationCoverDidDismiss()
        let cancellationError = model.authError
        isAuthenticated = true
        model.authenticationStateDidChange(error: nil)

        // Then
        XCTAssertEqual(
            cancellationError,
            GameLocalizedStrings.string("Sign in to Game Center to view the leaderboard.")
        )
        XCTAssertNil(model.takePendingLeaderboardIDIfReady())
    }

    func testGivenScheduledAuthenticationTimeoutWhenCancelledThenTimeoutMutationDoesNotRun() async {
        // Given
        let model = makeModel(authenticationPresenter: AuthenticationPresenterUniversal())
        model.startAuthentication(startedByUser: true)

        // When
        let timeoutTask = model.cancelAuthTimeout()
        await timeoutTask?.value

        // Then
        XCTAssertEqual(model.authState, .authenticating)
        XCTAssertNil(model.authError)
    }

    private func makeModel(
        authenticationPresenter: AuthenticationPresenter,
        authenticateHandlerSetter: @escaping AuthenticateHandlerSetter = { _ in },
        isAuthenticatedProvider: @escaping () -> Bool = { false }
    ) -> MenuAuthModel {
        MenuAuthModel(
            gameCenterService: GameCenterService(
                configuration: MockLeaderboardConfiguration(leaderboardID: "test123"),
                friendSnapshotService: GameCenterFriendSnapshotService(
                    configuration: .standard,
                    avatarCache: GameCenterAvatarCache()
                ),
                authenticateHandlerSetter: authenticateHandlerSetter,
                isDebugBuild: true,
                allowDebugScoreSubmission: false,
                isAuthenticatedProvider: isAuthenticatedProvider
            ),
            authenticationPresenter: authenticationPresenter
        )
    }

    func testGivenCompletedAutomaticAttemptWhenUserExplicitlyRetriesThenAuthenticationRestarts() {
        // Given
        var authenticationRequestCount = 0
        let service = GameCenterService(
            configuration: MockLeaderboardConfiguration(leaderboardID: "test123"),
            friendSnapshotService: GameCenterFriendSnapshotService(
                configuration: .standard,
                avatarCache: GameCenterAvatarCache()
            ),
            authenticateHandlerSetter: { _ in
                authenticationRequestCount += 1
            },
            isDebugBuild: true,
            allowDebugScoreSubmission: false,
            isAuthenticatedProvider: { false }
        )
        let model = MenuAuthModel(
            gameCenterService: service,
            authenticationPresenter: AuthenticationPresenterUniversal()
        )

        // When
        model.startAuthentication(startedByUser: false)
        model.startAuthentication(startedByUser: true)

        // Then
        XCTAssertEqual(authenticationRequestCount, 2)
        model.cancelAuthTimeout()
    }
}
#endif

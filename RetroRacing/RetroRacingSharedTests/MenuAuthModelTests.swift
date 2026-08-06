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

    private func makeModel(authenticationPresenter: AuthenticationPresenter) -> MenuAuthModel {
        MenuAuthModel(
            gameCenterService: GameCenterService(
                configuration: MockLeaderboardConfiguration(leaderboardID: "test123"),
                friendSnapshotService: GameCenterFriendSnapshotService(
                    configuration: .standard,
                    avatarCache: GameCenterAvatarCache()
                ),
                authenticateHandlerSetter: { _ in },
                isDebugBuild: true,
                allowDebugScoreSubmission: false,
                isAuthenticatedProvider: { false }
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

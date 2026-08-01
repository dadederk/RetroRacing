//
//  SharePlayHostActivationRoutingPolicyTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 31/07/2026.
//

import XCTest
@testable import RetroRacingShared

final class SharePlayHostActivationRoutingPolicyTests: XCTestCase {
    func testGivenEligibleGroupSessionThenRouteActivatesDirectly() {
        XCTAssertEqual(
            SharePlayHostActivationRoutingPolicy.route(
                isEligibleForGroupSession: true
            ),
            .directActivation
        )
    }

    func testGivenIneligibleGroupSessionThenRoutePresentsSharingController() {
        XCTAssertEqual(
            SharePlayHostActivationRoutingPolicy.route(
                isEligibleForGroupSession: false
            ),
            .sharingController
        )
    }

    func testGivenCurrentEligibleControllerHandoffThenRecoveryIsAttempted() {
        XCTAssertTrue(
            SharePlayHostActivationRoutingPolicy.shouldRecoverControllerHandoff(
                isEligibleForGroupSession: true,
                isActivationRequestCurrent: true,
                hasAttemptedRecovery: false
            )
        )
    }

    func testGivenIneligibleControllerHandoffThenRecoveryIsNotAttempted() {
        XCTAssertFalse(
            SharePlayHostActivationRoutingPolicy.shouldRecoverControllerHandoff(
                isEligibleForGroupSession: false,
                isActivationRequestCurrent: true,
                hasAttemptedRecovery: false
            )
        )
    }

    func testGivenStaleControllerHandoffThenRecoveryIsNotAttempted() {
        XCTAssertFalse(
            SharePlayHostActivationRoutingPolicy.shouldRecoverControllerHandoff(
                isEligibleForGroupSession: true,
                isActivationRequestCurrent: false,
                hasAttemptedRecovery: false
            )
        )
    }

    func testGivenCompletedControllerRecoveryThenItIsNotRepeated() {
        XCTAssertFalse(
            SharePlayHostActivationRoutingPolicy.shouldRecoverControllerHandoff(
                isEligibleForGroupSession: true,
                isActivationRequestCurrent: true,
                hasAttemptedRecovery: true
            )
        )
    }
}

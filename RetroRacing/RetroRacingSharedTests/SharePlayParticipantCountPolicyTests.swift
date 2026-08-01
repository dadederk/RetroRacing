//
//  SharePlayParticipantCountPolicyTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 01/08/2026.
//

import XCTest
@testable import RetroRacingShared

final class SharePlayParticipantCountPolicyTests: XCTestCase {
    func testGivenOneParticipantBeforeReadyWhenClassifyingThenWaitBeforeReady() {
        let disposition = SharePlayParticipantCountPolicy.disposition(
            participantCount: 1,
            hasObservedTwoParticipants: false,
            isIntentionalTeardown: false
        )

        XCTAssertEqual(disposition, .waitingBeforeReady)
        XCTAssertEqual(disposition.ignoredLossReason, "before_ready")
    }

    func testGivenTwoParticipantsBeforeReadyWhenClassifyingThenExactlyTwoReady() {
        let disposition = SharePlayParticipantCountPolicy.disposition(
            participantCount: 2,
            hasObservedTwoParticipants: false,
            isIntentionalTeardown: false
        )

        XCTAssertEqual(disposition, .exactlyTwoReady)
        XCTAssertNil(disposition.ignoredLossReason)
    }

    func testGivenTwoParticipantsAfterReadyWhenClassifyingThenAlreadyReady() {
        let disposition = SharePlayParticipantCountPolicy.disposition(
            participantCount: 2,
            hasObservedTwoParticipants: true,
            isIntentionalTeardown: false
        )

        XCTAssertEqual(disposition, .exactlyTwoAlreadyReady)
        XCTAssertNil(disposition.ignoredLossReason)
    }

    func testGivenMoreThanTwoParticipantsWhenClassifyingThenUnsupported() {
        let disposition = SharePlayParticipantCountPolicy.disposition(
            participantCount: 3,
            hasObservedTwoParticipants: false,
            isIntentionalTeardown: false
        )

        XCTAssertEqual(disposition, .unsupportedMoreThanTwo)
        XCTAssertNil(disposition.ignoredLossReason)
    }

    func testGivenParticipantLossAfterReadyWhenClassifyingThenLossAfterReady() {
        let disposition = SharePlayParticipantCountPolicy.disposition(
            participantCount: 1,
            hasObservedTwoParticipants: true,
            isIntentionalTeardown: false
        )

        XCTAssertEqual(disposition, .lossAfterReady)
        XCTAssertNil(disposition.ignoredLossReason)
    }

    func testGivenParticipantLossDuringIntentionalTeardownWhenClassifyingThenIgnoredTeardown() {
        let disposition = SharePlayParticipantCountPolicy.disposition(
            participantCount: 1,
            hasObservedTwoParticipants: true,
            isIntentionalTeardown: true
        )

        XCTAssertEqual(disposition, .ignoredIntentionalTeardown)
        XCTAssertEqual(disposition.ignoredLossReason, "intentional_teardown")
    }
}

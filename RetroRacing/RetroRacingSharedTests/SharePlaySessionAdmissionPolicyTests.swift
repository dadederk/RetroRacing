//
//  SharePlaySessionAdmissionPolicyTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 30/07/2026.
//

import XCTest
@testable import RetroRacingShared

final class SharePlaySessionAdmissionPolicyTests: XCTestCase {
    func testGivenWaitingSessionBeforeJoinWhenPublishingThenStateIsQuarantined() {
        XCTAssertFalse(
            SharePlaySessionAdmissionPolicy.shouldPublish(
                state: .waitingForFriend,
                isSessionJoined: false
            )
        )
    }

    func testGivenAbortedSessionBeforeJoinWhenPublishingThenStateIsQuarantined() {
        XCTAssertFalse(
            SharePlaySessionAdmissionPolicy.shouldPublish(
                state: .aborted(reason: .disconnected),
                isSessionJoined: false
            )
        )
    }

    func testGivenWaitingSessionAfterJoinWhenPublishingThenStateIsVisible() {
        XCTAssertTrue(
            SharePlaySessionAdmissionPolicy.shouldPublish(
                state: .waitingForFriend,
                isSessionJoined: true
            )
        )
    }

    func testGivenIdleStateBeforeJoinWhenPublishingThenResetIsVisible() {
        XCTAssertTrue(
            SharePlaySessionAdmissionPolicy.shouldPublish(
                state: .idle,
                isSessionJoined: false
            )
        )
    }

    func testGivenInvalidationBeforeJoinThenSessionIsDiscarded() {
        XCTAssertEqual(
            SharePlaySessionAdmissionPolicy.invalidationDisposition(isSessionJoined: false),
            .discard
        )
    }

    func testGivenInvalidationAfterJoinThenMatchIsAborted() {
        XCTAssertEqual(
            SharePlaySessionAdmissionPolicy.invalidationDisposition(isSessionJoined: true),
            .abort
        )
    }
}

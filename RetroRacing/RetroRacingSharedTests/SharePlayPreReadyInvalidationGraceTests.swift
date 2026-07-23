//
//  SharePlayPreReadyInvalidationGraceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 23/07/2026.
//

import XCTest
@testable import RetroRacingShared

final class SharePlayPreReadyInvalidationGraceTests: XCTestCase {
    func testGivenPendingGraceWhenCancelledBeforeDeadlineThenDisconnectIsNotCalled() async {
        let grace = SharePlayPreReadyInvalidationGrace()
        var disconnectCount = 0

        grace.schedule(graceDuration: 0.2, shouldDisconnect: { true }) {
            disconnectCount += 1
        }
        XCTAssertTrue(grace.hasPendingTask)

        grace.cancel()
        XCTAssertFalse(grace.hasPendingTask)

        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(disconnectCount, 0)
    }

    func testGivenCancelledGraceWhenRescheduledThenOnlyLatestDisconnectFires() async {
        let grace = SharePlayPreReadyInvalidationGrace()
        var disconnectCount = 0

        grace.schedule(graceDuration: 0.2, shouldDisconnect: { true }) {
            disconnectCount += 1
        }
        grace.cancel()
        grace.schedule(graceDuration: 0.05, shouldDisconnect: { true }) {
            disconnectCount += 1
        }

        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(disconnectCount, 1)
    }

    func testGivenPendingGraceWhenShouldDisconnectIsFalseThenCallbackIsNotCalled() async {
        let grace = SharePlayPreReadyInvalidationGrace()
        var disconnectCount = 0

        grace.schedule(graceDuration: 0.05, shouldDisconnect: { false }) {
            disconnectCount += 1
        }

        try? await Task.sleep(nanoseconds: 120_000_000)
        XCTAssertEqual(disconnectCount, 0)
        XCTAssertFalse(grace.hasPendingTask)
    }

    func testGivenPendingGraceWhenShouldDisconnectIsTrueThenCallbackIsCalled() async {
        let grace = SharePlayPreReadyInvalidationGrace()
        var disconnectCount = 0

        grace.schedule(graceDuration: 0.05, shouldDisconnect: { true }) {
            disconnectCount += 1
        }

        try? await Task.sleep(nanoseconds: 120_000_000)
        XCTAssertEqual(disconnectCount, 1)
        XCTAssertFalse(grace.hasPendingTask)
    }
}

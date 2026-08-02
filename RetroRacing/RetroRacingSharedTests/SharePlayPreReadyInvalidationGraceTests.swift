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
        // Given
        let sleeper = RecordingGraceSleeper()
        let spy = RecordingDisconnectSpy()
        let grace = SharePlayPreReadyInvalidationGrace(
            sleep: { nanoseconds in
                await sleeper.sleep(nanoseconds: nanoseconds)
            }
        )

        // When
        grace.schedule(graceDuration: 0.2, shouldDisconnect: { true }) {
            spy.record()
        }
        XCTAssertTrue(grace.hasPendingTask)

        await sleeper.waitForSleepRequest()
        grace.cancel()
        await sleeper.releaseAll()
        await Task.yield()

        // Then
        XCTAssertFalse(grace.hasPendingTask)
        XCTAssertEqual(spy.count, 0)
    }

    func testGivenCancelledGraceWhenRescheduledThenOnlyLatestDisconnectFires() async {
        // Given
        let sleeper = RecordingGraceSleeper()
        let spy = RecordingDisconnectSpy()
        let grace = SharePlayPreReadyInvalidationGrace(
            sleep: { nanoseconds in
                await sleeper.sleep(nanoseconds: nanoseconds)
            }
        )

        // When
        grace.schedule(graceDuration: 0.2, shouldDisconnect: { true }) {
            spy.record()
        }
        await sleeper.waitForSleepRequest()
        grace.cancel()
        grace.schedule(graceDuration: 0.05, shouldDisconnect: { true }) {
            spy.record()
        }
        await sleeper.waitForSleepRequest(count: 2)
        await sleeper.releaseAll()
        await waitUntil { spy.count == 1 }

        // Then
        XCTAssertEqual(spy.count, 1)
    }

    func testGivenPendingGraceWhenShouldDisconnectIsFalseThenCallbackIsNotCalled() async {
        // Given
        let sleeper = RecordingGraceSleeper()
        let spy = RecordingDisconnectSpy()
        let grace = SharePlayPreReadyInvalidationGrace(
            sleep: { nanoseconds in
                await sleeper.sleep(nanoseconds: nanoseconds)
            }
        )

        // When
        grace.schedule(graceDuration: 0.05, shouldDisconnect: { false }) {
            spy.record()
        }
        await sleeper.waitForSleepRequest()
        await sleeper.releaseAll()
        await waitUntil { grace.hasPendingTask == false }

        // Then
        XCTAssertEqual(spy.count, 0)
        XCTAssertFalse(grace.hasPendingTask)
    }

    func testGivenPendingGraceWhenShouldDisconnectIsTrueThenCallbackIsCalled() async {
        // Given
        let sleeper = RecordingGraceSleeper()
        let spy = RecordingDisconnectSpy()
        let grace = SharePlayPreReadyInvalidationGrace(
            sleep: { nanoseconds in
                await sleeper.sleep(nanoseconds: nanoseconds)
            }
        )

        // When
        grace.schedule(graceDuration: 0.05, shouldDisconnect: { true }) {
            spy.record()
        }
        await sleeper.waitForSleepRequest()
        await sleeper.releaseAll()
        await waitUntil { spy.count == 1 }

        // Then
        XCTAssertEqual(spy.count, 1)
        XCTAssertFalse(grace.hasPendingTask)
    }

    private func waitUntil(
        maxYields: Int = 100,
        condition: () -> Bool
    ) async {
        var remainingYields = maxYields
        while condition() == false, remainingYields > 0 {
            await Task.yield()
            remainingYields -= 1
        }
    }
}

private final class RecordingDisconnectSpy: @unchecked Sendable {
    private let lock = NSLock()
    private var disconnectCount = 0

    var count: Int {
        lock.withLock { disconnectCount }
    }

    func record() {
        lock.withLock {
            disconnectCount += 1
        }
    }
}

private actor RecordingGraceSleeper {
    private var sleepRequests: [UInt64] = []
    private var sleepRequestContinuation: CheckedContinuation<Void, Never>?
    private var releaseContinuations: [CheckedContinuation<Void, Never>] = []

    func sleep(nanoseconds: UInt64) async {
        sleepRequests.append(nanoseconds)
        sleepRequestContinuation?.resume()
        sleepRequestContinuation = nil

        await withCheckedContinuation { continuation in
            releaseContinuations.append(continuation)
        }
    }

    func waitForSleepRequest(count: Int = 1) async {
        guard sleepRequests.count < count else { return }
        await withCheckedContinuation { continuation in
            sleepRequestContinuation = continuation
        }
    }

    func releaseAll() {
        let continuations = releaseContinuations
        releaseContinuations = []
        continuations.forEach { $0.resume() }
    }
}

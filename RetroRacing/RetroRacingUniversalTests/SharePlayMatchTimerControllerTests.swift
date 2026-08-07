//
//  SharePlayMatchTimerControllerTests.swift
//  RetroRacingUniversalTests
//
//  Created by Dani Devesa on 01/08/2026.
//

import Foundation
import Testing
@testable import RetroRacingShared

@MainActor
struct SharePlayMatchTimerControllerTests {
    @Test func testGivenCountdownTimerWhenDeadlineArrivesThenCallbackFires() async {
        var controller = SharePlayMatchTimerController(sleep: { _ in })
        let recorder = TimerCallbackRecorder<Date>()
        let startAt = Date().addingTimeInterval(60)

        controller.scheduleCountdown(generation: 7, startAt: startAt) { generation, startAt in
            await recorder.record(generation: generation, value: startAt)
        }
        let didFire = await waitUntil {
            await recorder.events.count == 1
        }

        #expect(didFire)
        #expect(await recorder.events == [TimerCallbackEvent(generation: 7, value: startAt)])
    }

    @Test func testGivenRetryTimerWhenDeadlineArrivesThenCallbackFires() async {
        var controller = SharePlayMatchTimerController(sleep: { _ in })
        let recorder = TimerCallbackRecorder<Date>()
        let deadline = Date().addingTimeInterval(60)

        controller.scheduleRetryTimeout(generation: 11, deadline: deadline) { generation, deadline in
            await recorder.record(generation: generation, value: deadline)
        }
        let didFire = await waitUntil {
            await recorder.events.count == 1
        }

        #expect(didFire)
        #expect(await recorder.events == [TimerCallbackEvent(generation: 11, value: deadline)])
    }

    @Test func testGivenCountdownTimerWhenCancelledThenCallbackDoesNotFire() async {
        let sleeper = RecordingTimerSleeper()
        var controller = SharePlayMatchTimerController(
            sleep: { nanoseconds in
                await sleeper.sleep(nanoseconds: nanoseconds)
            }
        )
        let recorder = TimerCallbackRecorder<Date>()
        let startAt = Date().addingTimeInterval(0.04)

        controller.scheduleCountdown(generation: 3, startAt: startAt) { generation, startAt in
            await recorder.record(generation: generation, value: startAt)
        }
        await sleeper.waitForSleepRequest()
        controller.cancelCountdown()
        await sleeper.releaseAll()
        await Task.yield()

        #expect(await recorder.events.isEmpty)
        #expect(controller.hasPendingCountdown == false)
    }

    @Test func testGivenRetryTimerWhenCancelledThenCallbackDoesNotFire() async {
        let sleeper = RecordingTimerSleeper()
        var controller = SharePlayMatchTimerController(
            sleep: { nanoseconds in
                await sleeper.sleep(nanoseconds: nanoseconds)
            }
        )
        let recorder = TimerCallbackRecorder<Date>()
        let deadline = Date().addingTimeInterval(0.04)

        controller.scheduleRetryTimeout(generation: 5, deadline: deadline) { generation, deadline in
            await recorder.record(generation: generation, value: deadline)
        }
        await sleeper.waitForSleepRequest()
        controller.cancelRetryTimeout()
        await sleeper.releaseAll()
        await Task.yield()

        #expect(await recorder.events.isEmpty)
        #expect(controller.hasPendingRetryTimeout == false)
    }

    func waitUntil(
        timeoutNanoseconds: UInt64 = 200_000_000,
        pollNanoseconds: UInt64 = 1_000_000,
        condition: @escaping @MainActor () async -> Bool
    ) async -> Bool {
        var elapsedNanoseconds: UInt64 = 0
        while elapsedNanoseconds < timeoutNanoseconds {
            if await condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: pollNanoseconds)
            elapsedNanoseconds += pollNanoseconds
        }
        return await condition()
    }
}

private struct TimerCallbackEvent<Value: Equatable>: Equatable {
    let generation: Int
    let value: Value
}

private actor TimerCallbackRecorder<Value: Equatable> {
    private var recordedEvents: [TimerCallbackEvent<Value>] = []

    var events: [TimerCallbackEvent<Value>] {
        recordedEvents
    }

    func record(generation: Int, value: Value) {
        recordedEvents.append(TimerCallbackEvent(generation: generation, value: value))
    }
}

private actor RecordingTimerSleeper {
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

    func waitForSleepRequest() async {
        guard sleepRequests.isEmpty else { return }
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

//
//  SharePlayMatchTimerControllerTests.swift
//  RetroRacingUniversalTests
//
//  Created by Dani Devesa on 01/08/2026.
//

import Foundation
import Testing
@testable import RetroRacingUniversal

@MainActor
struct SharePlayMatchTimerControllerTests {
    @Test func testGivenCountdownTimerWhenDeadlineArrivesThenCallbackFires() async {
        var controller = SharePlayMatchTimerController()
        let recorder = TimerCallbackRecorder<Date>()
        let startAt = Date().addingTimeInterval(0.01)

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
        var controller = SharePlayMatchTimerController()
        let recorder = TimerCallbackRecorder<Date>()
        let deadline = Date().addingTimeInterval(0.01)

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
        var controller = SharePlayMatchTimerController()
        let recorder = TimerCallbackRecorder<Date>()
        let startAt = Date().addingTimeInterval(0.04)

        controller.scheduleCountdown(generation: 3, startAt: startAt) { generation, startAt in
            await recorder.record(generation: generation, value: startAt)
        }
        controller.cancelCountdown()
        try? await Task.sleep(nanoseconds: 70_000_000)

        #expect(await recorder.events.isEmpty)
        #expect(controller.hasPendingCountdown == false)
    }

    @Test func testGivenRetryTimerWhenCancelledThenCallbackDoesNotFire() async {
        var controller = SharePlayMatchTimerController()
        let recorder = TimerCallbackRecorder<Date>()
        let deadline = Date().addingTimeInterval(0.04)

        controller.scheduleRetryTimeout(generation: 5, deadline: deadline) { generation, deadline in
            await recorder.record(generation: generation, value: deadline)
        }
        controller.cancelRetryTimeout()
        try? await Task.sleep(nanoseconds: 70_000_000)

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

//
//  SharePlayMatchTimerController.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 01/08/2026.
//

#if canImport(GroupActivities) && os(iOS)
import Foundation
import RetroRacingShared

nonisolated struct SharePlayMatchTimerController {
    private var countdownTask: Task<Void, Never>?
    private var retryTimeoutTask: Task<Void, Never>?

    var hasPendingCountdown: Bool {
        countdownTask != nil
    }

    var hasPendingRetryTimeout: Bool {
        retryTimeoutTask != nil
    }

    mutating func scheduleCountdown(
        generation: Int,
        startAt: Date,
        onComplete: @escaping @Sendable (_ generation: Int, _ expectedStartAt: Date) async -> Void
    ) {
        cancelCountdown()
        let delay = max(0, startAt.timeIntervalSinceNow)
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_COUNTDOWN_TIMER",
            outcome: .deferred,
            fields: [
                .int("generation", generation),
                .double("delaySeconds", delay)
            ]
        )
        countdownTask = Task { @concurrent in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard Task.isCancelled == false else { return }
            await onComplete(generation, startAt)
        }
    }

    mutating func scheduleRetryTimeout(
        generation: Int,
        deadline: Date,
        onComplete: @escaping @Sendable (_ generation: Int, _ expectedDeadline: Date) async -> Void
    ) {
        cancelRetryTimeout()
        let delay = max(0, deadline.timeIntervalSinceNow)
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_RETRY_TIMER",
            outcome: .deferred,
            fields: [
                .int("generation", generation),
                .double("delaySeconds", delay)
            ]
        )
        retryTimeoutTask = Task { @concurrent in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard Task.isCancelled == false else { return }
            await onComplete(generation, deadline)
        }
    }

    mutating func markCountdownCompleted() {
        countdownTask = nil
    }

    mutating func markRetryTimeoutCompleted() {
        retryTimeoutTask = nil
    }

    mutating func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
    }

    mutating func cancelRetryTimeout() {
        retryTimeoutTask?.cancel()
        retryTimeoutTask = nil
    }

    mutating func cancelTimers() {
        cancelCountdown()
        cancelRetryTimeout()
    }
}
#endif

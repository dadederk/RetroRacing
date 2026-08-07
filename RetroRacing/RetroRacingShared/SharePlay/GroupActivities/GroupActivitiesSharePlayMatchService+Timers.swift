//
//  GroupActivitiesSharePlayMatchService+Timers.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 31/07/2026.
//

#if canImport(GroupActivities)
import GroupActivities
import Foundation

extension GroupActivitiesSharePlayMatchService {
    func scheduleCountdownCompletion() {
        guard case .countdown(let startAt, _) = stateMachine?.state else { return }
        let generation = sessionGeneration
        timerController.scheduleCountdown(generation: generation, startAt: startAt) { [weak self] generation, startAt in
            await self?.completeCountdown(generation: generation, expectedStartAt: startAt)
        }
    }

    func completeCountdown(generation: Int, expectedStartAt: Date) async {
        guard generation == sessionGeneration else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_COUNTDOWN_TIMER",
                outcome: .ignored,
                fields: [
                    .reason("stale_generation"),
                    .int("callbackGeneration", generation),
                    .int("sessionGeneration", sessionGeneration)
                ]
            )
            return
        }
        guard var machine = stateMachine else { return }
        guard case .countdown(let currentStartAt, _) = machine.state,
              currentStartAt == expectedStartAt else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_COUNTDOWN_TIMER",
                outcome: .ignored,
                fields: [
                    .reason("stale_deadline"),
                    .int("generation", generation),
                    .string("state", machine.state.diagnosticName)
                ]
            )
            return
        }
        timerController.markCountdownCompleted()
        let previousState = machine.state
        machine.beginRound()
        stateMachine = machine
        await notifyStateChanged()
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_COUNTDOWN_TIMER",
            outcome: .completed,
            fields: [
                .int("generation", sessionGeneration),
                .string("previousState", previousState.diagnosticName),
                .string("newState", machine.state.diagnosticName)
            ]
        )
    }

    func scheduleRetryTimeoutIfNeeded() {
        guard case .retryWaiting(_, _, let deadline) = stateMachine?.state else { return }
        let generation = sessionGeneration
        timerController.scheduleRetryTimeout(generation: generation, deadline: deadline) { [weak self] generation, deadline in
            await self?.completeRetryTimeout(generation: generation, expectedDeadline: deadline)
        }
    }

    func completeRetryTimeout(generation: Int, expectedDeadline: Date) async {
        guard generation == sessionGeneration else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_RETRY_TIMER",
                outcome: .ignored,
                fields: [
                    .reason("stale_generation"),
                    .int("callbackGeneration", generation),
                    .int("sessionGeneration", sessionGeneration)
                ]
            )
            return
        }
        guard var machine = stateMachine else { return }
        guard case .retryWaiting(_, _, let currentDeadline) = machine.state,
              currentDeadline == expectedDeadline else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_RETRY_TIMER",
                outcome: .ignored,
                fields: [
                    .reason("stale_deadline"),
                    .int("generation", generation),
                    .string("state", machine.state.diagnosticName)
                ]
            )
            return
        }
        timerController.markRetryTimeoutCompleted()
        let previousState = machine.state
        let commands = machine.retryTimeoutElapsed()
        stateMachine = machine
        await sendAll(commands)
        await notifyStateChanged()
        AppLog.warning(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_RETRY_TIMER",
            outcome: .completed,
            fields: [
                .int("generation", sessionGeneration),
                .string("previousState", previousState.diagnosticName),
                .string("newState", machine.state.diagnosticName),
                .int("emittedCommands", commands.count)
            ]
        )
    }

    func cancelCountdown() {
        timerController.cancelCountdown()
    }

    func cancelRetryTimeout() {
        timerController.cancelRetryTimeout()
    }

    func cancelTimers() {
        timerController.cancelTimers()
    }
}
#endif

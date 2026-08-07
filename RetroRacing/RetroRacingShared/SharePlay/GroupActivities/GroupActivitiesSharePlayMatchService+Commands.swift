//
//  GroupActivitiesSharePlayMatchService+Commands.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 31/07/2026.
//

#if canImport(GroupActivities)
import GroupActivities
import Foundation

extension GroupActivitiesSharePlayMatchService {
    public func hostStartRoundIfReady(difficulty: GameDifficulty) async {
        guard var machine = stateMachine else {
            logHostStartBlocked(reason: "missing_state_machine")
            return
        }
        guard machine.localRole == .host else {
            logHostStartBlocked(reason: "not_host", machine: machine)
            return
        }
        guard case .waitingForFriend = machine.state else {
            logHostStartBlocked(reason: "not_waiting_for_friend", machine: machine)
            return
        }
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_HOST_START_ROUND",
            outcome: .requested,
            fields: [
                .int("generation", sessionGeneration),
                .string("difficulty", difficulty.rawValue)
            ]
        )
        let trafficSeed = trafficSeedProvider()
        let commands = machine.hostStartRound(difficulty: difficulty, trafficSeed: trafficSeed)
        stateMachine = machine
        await sendAll(commands)
        scheduleCountdownCompletion()
        await notifyStateChanged()
    }

    public func updateLocalScore(_ score: Int, lives: Int) async {
        guard var machine = stateMachine else { return }
        let commands = machine.updateLocalScore(score, lives: lives)
        stateMachine = machine
        await sendAll(commands)
    }

    public func reportLocalElimination(finalScore: Int) async {
        guard var machine = stateMachine, case .inRound = machine.state else { return }
        var commands = machine.updateLocalScore(finalScore, lives: 0)
        commands += machine.localPlayerEliminated(finalScore: finalScore)
        stateMachine = machine
        await sendAll(commands)
        await notifyStateChanged()
    }

    public func retry() async {
        guard var machine = stateMachine else { return }
        let commands = machine.retryTapped()
        stateMachine = machine
        await sendAll(commands)
        scheduleRetryTimeoutIfNeeded()
        await notifyStateChanged()
        await autoStartHostRoundIfReady()
    }

    func resendSessionReadyIfWaitingForFriend(reason: String) async {
        guard let machine = stateMachine else { return }
        let commands = machine.resendSessionReadyIfWaitingForFriend()
        guard commands.isEmpty == false else { return }
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_SESSION_READY_RESEND",
            outcome: .requested,
            fields: [
                .reason(reason),
                .int("generation", sessionGeneration),
                .string("state", machine.state.diagnosticName),
                .bool("remoteReady", machine.isRemoteReady)
            ]
        )
        await sendAll(commands)
    }

    func autoStartHostRoundIfReady() async {
        guard let machine = stateMachine else {
            logAutoStartBlocked(reason: "missing_state_machine")
            return
        }
        guard machine.localRole == .host else {
            logAutoStartBlocked(reason: "not_host", machine: machine)
            return
        }
        guard case .waitingForFriend = machine.state else {
            logAutoStartBlocked(reason: "not_waiting_for_friend", machine: machine)
            return
        }
        guard sessionRuntimeState.isJoined else {
            logAutoStartBlocked(reason: "session_not_joined", machine: machine)
            return
        }
        guard sessionRuntimeState.hasTwoParticipants else {
            logAutoStartBlocked(reason: "waiting_for_two_participants", machine: machine)
            return
        }
        guard machine.isRemoteReady else {
            logAutoStartBlocked(reason: "waiting_for_remote_ready", machine: machine)
            return
        }
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_AUTO_START_ROUND",
            outcome: .requested,
            fields: [
                .int("generation", sessionGeneration),
                .string("state", stateMachine?.state.diagnosticName),
                .string("role", stateMachine?.localRole.rawValue)
            ]
        )
        await hostStartRoundIfReady(difficulty: difficultyProvider())
    }

    func handleIncoming(_ command: SharePlayMatchCommand, generation: Int) async {
        guard generation == sessionGeneration else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_COMMAND_RECEIVE",
                outcome: .ignored,
                fields: [
                    .reason("stale_generation"),
                    .int("callbackGeneration", generation),
                    .int("sessionGeneration", sessionGeneration),
                    .string("command", command.diagnosticName)
                ]
            )
            return
        }
        guard var machine = stateMachine else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_COMMAND_RECEIVE",
                outcome: .ignored,
                fields: [
                    .reason("missing_state_machine"),
                    .int("generation", sessionGeneration),
                    .string("command", command.diagnosticName)
                ]
            )
            return
        }
        let previousState = machine.state
        let wasRemoteReady = machine.isRemoteReady
        let shouldLogCommandLifecycle = shouldLogLifecycle(for: command)
        if shouldLogCommandLifecycle {
            AppLog.debug(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_COMMAND_RECEIVE",
                outcome: .completed,
                fields: [
                    .int("generation", sessionGeneration),
                    .string("command", command.diagnosticName),
                    .string("previousState", previousState.diagnosticName)
                ]
            )
        }
        let commands = machine.receive(command)
        stateMachine = machine
        await sendAll(commands)
        let didStateChange = previousState != machine.state
        let didRemoteReadyChange = wasRemoteReady != machine.isRemoteReady
        let shouldApplySideEffects = didStateChange || didRemoteReadyChange || commands.isEmpty == false
        guard shouldApplySideEffects || shouldLogCommandLifecycle else { return }
        let previousStateName = previousState.diagnosticName
        let newStateName = machine.state.diagnosticName
        let didStateKindChange = previousStateName != newStateName
        if didStateKindChange || shouldLogCommandLifecycle {
            AppLog.info(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_COMMAND_APPLY",
                outcome: .completed,
                fields: [
                    .int("generation", sessionGeneration),
                    .string("command", command.diagnosticName),
                    .string("previousState", previousStateName),
                    .string("newState", newStateName),
                    .int("emittedCommands", commands.count)
                ]
            )
        }
        guard shouldApplySideEffects else { return }

        if case .countdown = machine.state {
            scheduleCountdownCompletion()
        } else {
            cancelCountdown()
        }
        if case .retryWaiting = machine.state {
            scheduleRetryTimeoutIfNeeded()
        } else {
            cancelRetryTimeout()
        }
        await notifyStateChanged()

        if case .waitingForFriend = machine.state {
            await autoStartHostRoundIfReady()
        }
    }

    func sendAll(_ commands: [SharePlayMatchCommand]) async {
        for command in commands {
            if shouldLogLifecycle(for: command) {
                AppLog.debug(
                    AppLog.lifecycle + AppLog.game,
                    "SHAREPLAY_COMMAND_SEND",
                    outcome: .requested,
                    fields: [
                        .int("generation", sessionGeneration),
                        .string("command", command.diagnosticName),
                        .string("state", stateMachine?.state.diagnosticName)
                    ]
                )
            }
            await coordinator.send(command)
        }
    }

    func shouldLogLifecycle(for command: SharePlayMatchCommand) -> Bool {
        switch command {
        case .scoreUpdate:
            return false
        case .sessionReady,
             .roundStart,
             .playerEliminated,
             .roundResult,
             .retryReady,
             .sessionFinished,
             .sessionAborted:
            return true
        @unknown default:
            return true
        }
    }
}
#endif

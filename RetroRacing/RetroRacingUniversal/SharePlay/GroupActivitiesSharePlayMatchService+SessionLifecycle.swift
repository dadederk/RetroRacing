//
//  GroupActivitiesSharePlayMatchService+SessionLifecycle.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 31/07/2026.
//

#if canImport(GroupActivities) && os(iOS)
import GroupActivities
import Foundation
import RetroRacingShared

extension GroupActivitiesSharePlayMatchService {
    public func observeIncomingSessions() async {
        guard isObservingSessions == false else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_SESSION_OBSERVER",
                outcome: .ignored,
                fields: [.reason("already_running")]
            )
            return
        }
        isObservingSessions = true
        defer { isObservingSessions = false }
        AppLog.info(AppLog.lifecycle + AppLog.game, "SHAREPLAY_SESSION_OBSERVER", outcome: .started)
        for await session in RetroRacingGroupActivity.sessions() {
            if Task.isCancelled { return }
            await handle(session: session)
        }
    }

    public func leaveSession() async {
        cancelTimers()
        guard var machine = stateMachine else {
            let shouldNotifyIdle = hostActivationController.cancelForLeaveWithoutSession()
            await coordinator.leave()
            clearSessionRuntimeState()
            guard shouldNotifyIdle,
                  let notification = stateNotifier.idleNotification() else { return }
            await notification.send()
            return
        }
        let commands = machine.leaveSession()
        stateMachine = machine
        await sendAll(commands)
        await coordinator.leave()
        clearSessionRuntimeState()
        await notifyStateChanged()
    }

    func handle(session: GroupSession<RetroRacingGroupActivity>) async {
        cancelTimers()
        sessionGeneration += 1
        let generation = sessionGeneration

        let wasPendingHostActivation = hostActivationController.isPendingHostActivation
        let previousStateName = stateMachine?.state.diagnosticName
        let role: SharePlayPlayerRole = session.isLocallyInitiated ? .host : .guest
        if role == .guest {
            hostActivationController.clearPending()
        }
        clearSessionRuntimeState()

        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_SESSION_HANDLE",
            outcome: .started,
            fields: [
                .int("generation", generation),
                .string("role", role.rawValue),
                .bool("isLocallyInitiated", session.isLocallyInitiated),
                .bool("wasPendingHostActivation", wasPendingHostActivation),
                .string("previousState", previousStateName)
            ]
        )

        var machine = SharePlayMatchStateMachine(localRole: role)
        _ = machine.startWaitingForFriend()
        stateMachine = machine

        await coordinator.configure(
            session: session,
            onSessionJoined: { [weak self] in
                await self?.sessionBecameJoined(generation: generation)
            },
            onParticipantsReady: { [weak self] in
                await self?.participantsBecameReady(generation: generation)
            },
            onDisconnected: { [weak self] in
                await self?.handleDisconnected(generation: generation)
            },
            onOpponentDisplayNameChanged: { [weak self] name in
                await self?.updateOpponentDisplayName(name, generation: generation)
            },
            onCommand: { [weak self] command in
                await self?.handleIncoming(command, generation: generation)
            }
        )

        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_SESSION_HANDLE",
            outcome: .completed,
            fields: [
                .int("generation", generation),
                .string("state", machine.state.diagnosticName),
                .string("role", role.rawValue),
                .bool("isSessionJoined", sessionRuntimeState.isJoined)
            ]
        )
    }

    func sessionBecameJoined(generation: Int) async {
        guard generation == sessionGeneration else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_SESSION_ADMISSION",
                outcome: .ignored,
                fields: [
                    .reason("stale_generation"),
                    .int("callbackGeneration", generation),
                    .int("sessionGeneration", sessionGeneration)
                ]
            )
            return
        }
        guard sessionRuntimeState.isJoined == false else { return }
        sessionRuntimeState.isJoined = true
        hostActivationController.clearPending()
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_SESSION_ADMISSION",
            outcome: .completed,
            fields: [
                .int("generation", generation),
                .string("state", stateMachine?.state.diagnosticName),
                .string("role", stateMachine?.localRole.rawValue)
            ]
        )
        await notifyStateChanged()
        await resendSessionReadyIfWaitingForFriend(reason: "session_joined")
        await autoStartHostRoundIfReady()
    }

    func updateOpponentDisplayName(_ name: String?, generation: Int) async {
        guard generation == sessionGeneration else { return }
        sessionRuntimeState.opponentDisplayName = name
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_OPPONENT_NAME",
            outcome: .completed,
            fields: [
                .int("generation", sessionGeneration),
                .string("opponentName", AppLog.redactedPlayer(name))
            ]
        )
        await notifyStateChanged()
    }

    func participantsBecameReady(generation: Int) async {
        guard generation == sessionGeneration else { return }
        sessionRuntimeState.hasTwoParticipants = true
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_PARTICIPANTS_READY",
            outcome: .completed,
            fields: [
                .int("generation", sessionGeneration),
                .string("state", stateMachine?.state.diagnosticName),
                .bool("remoteReady", stateMachine?.isRemoteReady == true)
            ]
        )
        await resendSessionReadyIfWaitingForFriend(reason: "participants_ready")
        await autoStartHostRoundIfReady()
    }

    func handleDisconnected(generation: Int) async {
        guard generation == sessionGeneration else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_DISCONNECTED",
                outcome: .ignored,
                fields: [
                    .reason("stale_generation"),
                    .int("callbackGeneration", generation),
                    .int("sessionGeneration", sessionGeneration)
                ]
            )
            return
        }
        guard var machine = stateMachine else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_DISCONNECTED",
                outcome: .ignored,
                fields: [
                    .reason("missing_state_machine"),
                    .int("generation", generation)
                ]
            )
            return
        }
        guard SharePlaySessionAdmissionPolicy.invalidationDisposition(
            isSessionJoined: sessionRuntimeState.isJoined
        ) == .abort else {
            AppLog.info(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_DISCONNECTED",
                outcome: .ignored,
                fields: [
                    .reason("session_invalidated_before_join"),
                    .int("generation", generation),
                    .string("previousState", machine.state.diagnosticName)
                ]
            )
            cancelTimers()
            stateMachine = nil
            clearSessionRuntimeState()
            return
        }
        let previousState = machine.state
        AppLog.warning(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_DISCONNECTED",
            outcome: .started,
            fields: [
                .int("generation", generation),
                .string("previousState", previousState.diagnosticName)
            ]
        )
        cancelTimers()
        machine.disconnected()
        stateMachine = machine
        await notifyStateChanged()
        AppLog.warning(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_DISCONNECTED",
            outcome: .completed,
            fields: [
                .int("generation", generation),
                .string("previousState", previousState.diagnosticName),
                .string("newState", machine.state.diagnosticName)
            ]
        )
    }

    func clearSessionRuntimeState() {
        sessionRuntimeState.clear()
        stateNotifier.clearCache()
    }
}
#endif

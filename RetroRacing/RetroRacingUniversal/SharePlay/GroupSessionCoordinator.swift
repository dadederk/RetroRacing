//
//  GroupSessionCoordinator.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 22/07/2026.
//

#if canImport(GroupActivities) && (os(iOS) || os(macOS))
import GroupActivities
import Combine
import Foundation
import RetroRacingShared

/// Owns one `GroupSession<RetroRacingGroupActivity>` lifecycle and its observation tasks.
/// Same-actor extension files keep observation, participant policy, and grace disconnects separate.
actor GroupSessionCoordinator {
    var transport: GroupSessionMessengerTransport?
    var session: GroupSession<RetroRacingGroupActivity>?
    var stateTask: Task<Void, Never>?
    var participantsTask: Task<Void, Never>?
    var participantLossTask: Task<Void, Never>?
    let preReadyInvalidationGrace = SharePlayPreReadyInvalidationGrace()
    let participantLossGraceDuration: TimeInterval
    let preReadyInvalidationGraceDuration: TimeInterval
    var isIntentionalTeardown = false
    var hasObservedJoinedState = false
    var hasObservedTwoParticipants = false
    var lastOpponentDisplayName: String?
    var observationGeneration = 0

    /// Called once the locally configured session reaches the joined state.
    var onSessionJoined: (@Sendable () async -> Void)?
    /// Called once at least 2 participants are active in the session.
    var onParticipantsReady: (@Sendable () async -> Void)?
    /// Called when the session invalidates (disconnect, remote left, etc.).
    var onDisconnected: (@Sendable () async -> Void)?
    /// Called when the remote participant's display name is resolved or cleared.
    var onOpponentDisplayNameChanged: (@Sendable (String?) async -> Void)?

    init(
        participantLossGraceDuration: TimeInterval = 1.5,
        preReadyInvalidationGraceDuration: TimeInterval? = nil
    ) {
        self.participantLossGraceDuration = participantLossGraceDuration
        self.preReadyInvalidationGraceDuration = preReadyInvalidationGraceDuration ?? participantLossGraceDuration
    }

    /// Joins the given session and starts observing it. Tears down any previously configured
    /// session first (v1 supports exactly one active SharePlay session at a time).
    func configure(
        session: GroupSession<RetroRacingGroupActivity>,
        onSessionJoined: @escaping @Sendable () async -> Void,
        onParticipantsReady: @escaping @Sendable () async -> Void,
        onDisconnected: @escaping @Sendable () async -> Void,
        onOpponentDisplayNameChanged: @escaping @Sendable (String?) async -> Void,
        onCommand: @escaping @Sendable (SharePlayMatchCommand) async -> Void
    ) async {
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_COORDINATOR_CONFIGURE",
            outcome: .started,
            fields: [
                .int("currentGeneration", observationGeneration),
                .bool("hadSession", self.session != nil),
                .bool("participantLossPending", participantLossTask != nil),
                .bool("preReadyInvalidationPending", preReadyInvalidationGrace.hasPendingTask)
            ]
        )
        cancelPreReadyInvalidationDisconnect(reason: "replacement_session")
        await tearDown(reason: "configure_new_session")
        self.onSessionJoined = onSessionJoined
        self.onParticipantsReady = onParticipantsReady
        self.onDisconnected = onDisconnected
        self.onOpponentDisplayNameChanged = onOpponentDisplayNameChanged
        observationGeneration += 1
        let generation = observationGeneration
        self.session = session
        hasObservedJoinedState = false
        hasObservedTwoParticipants = false
        lastOpponentDisplayName = nil

        let transport = GroupSessionMessengerTransport(session: session)
        transport.startReceiving { [weak self] command in
            await self?.handleReceivedCommand(command, generation: generation, onCommand: onCommand)
        }
        self.transport = transport

        stateTask = Task { [weak self] in
            for await state in session.$state.values {
                guard let self, Task.isCancelled == false else { return }
                let shouldContinue = await self.handleGroupState(state, generation: generation)
                guard shouldContinue else {
                    return
                }
            }
        }

        participantsTask = Task { [weak self] in
            for await participants in session.$activeParticipants.values {
                guard let self, Task.isCancelled == false else { return }
                let shouldContinue = await self.handleParticipants(participants, generation: generation)
                guard shouldContinue else {
                    return
                }
            }
        }

        session.join()
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_COORDINATOR_CONFIGURE",
            outcome: .completed,
            fields: [.int("generation", generation)]
        )
    }

    /// Sends a command over the currently configured transport, if any.
    func send(_ command: SharePlayMatchCommand) async {
        await transport?.send(command)
    }

    /// Leaves the session gracefully (user-initiated exit, not a disconnect).
    func leave() async {
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_COORDINATOR_LEAVE",
            outcome: .requested,
            fields: [
                .int("generation", observationGeneration),
                .bool("hadSession", session != nil)
            ]
        )
        session?.leave()
        await tearDown(reason: "leave")
    }

    func tearDown(reason: String, cancelsPreReadyInvalidation: Bool = true) async {
        let hadSession = session != nil
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_COORDINATOR_TEARDOWN",
            outcome: hadSession || stateTask != nil || participantsTask != nil ? .started : .skipped,
            fields: [
                .reason(reason),
                .int("generation", observationGeneration),
                .bool("hadSession", hadSession),
                .bool("participantLossPending", participantLossTask != nil),
                .bool("preReadyInvalidationPending", preReadyInvalidationGrace.hasPendingTask),
                .bool("cancelsPreReadyInvalidation", cancelsPreReadyInvalidation)
            ]
        )
        observationGeneration += 1
        isIntentionalTeardown = true
        stateTask?.cancel()
        participantsTask?.cancel()
        cancelParticipantLossDisconnect()
        if cancelsPreReadyInvalidation {
            cancelPreReadyInvalidationDisconnect(reason: reason)
        }
        stateTask = nil
        participantsTask = nil
        transport?.stop()
        transport = nil
        session = nil
        hasObservedJoinedState = false
        hasObservedTwoParticipants = false
        await updateOpponentDisplayNameIfNeeded(nil)
        isIntentionalTeardown = false
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_COORDINATOR_TEARDOWN",
            outcome: .completed,
            fields: [
                .reason(reason),
                .int("generation", observationGeneration)
            ]
        )
    }
}
#endif

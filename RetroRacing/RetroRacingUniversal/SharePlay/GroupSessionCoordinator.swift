//
//  GroupSessionCoordinator.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 22/07/2026.
//

#if canImport(GroupActivities) && os(iOS)
import GroupActivities
import Combine
import Foundation
import RetroRacingShared

/// Owns the lifecycle of a single `GroupSession<RetroRacingGroupActivity>`: joining it,
/// observing state/participant changes, and wiring a `GroupSessionMessengerTransport`.
/// `GroupActivitiesSharePlayMatchService` owns one instance and reconfigures it whenever a new
/// session arrives from `RetroRacingGroupActivity.sessions()`.
nonisolated final class GroupSessionCoordinator: @unchecked Sendable {
    private(set) var transport: GroupSessionMessengerTransport?
    private var session: GroupSession<RetroRacingGroupActivity>?
    private var stateTask: Task<Void, Never>?
    private var participantsTask: Task<Void, Never>?
    private var participantLossTask: Task<Void, Never>?
    private let preReadyInvalidationGrace = SharePlayPreReadyInvalidationGrace()
    private let participantLossGraceDuration: TimeInterval
    private let preReadyInvalidationGraceDuration: TimeInterval
    private var isIntentionalTeardown = false
    private var hasObservedTwoParticipants = false
    private var lastOpponentDisplayName: String?
    private var observationGeneration = 0

    /// Called once at least 2 participants are active in the session.
    var onParticipantsReady: (() -> Void)?
    /// Called when the session invalidates (disconnect, remote left, etc.).
    var onDisconnected: (() -> Void)?
    /// Called when the remote participant's display name is resolved or cleared.
    var onOpponentDisplayNameChanged: ((String?) -> Void)?

    init(
        participantLossGraceDuration: TimeInterval = 1.5,
        preReadyInvalidationGraceDuration: TimeInterval? = nil
    ) {
        self.participantLossGraceDuration = participantLossGraceDuration
        self.preReadyInvalidationGraceDuration = preReadyInvalidationGraceDuration ?? participantLossGraceDuration
    }

    /// Joins the given session and starts observing it. Tears down any previously configured
    /// session first (v1 supports exactly one active SharePlay session at a time).
    func configure(session: GroupSession<RetroRacingGroupActivity>, onCommand: @escaping (SharePlayMatchCommand) -> Void) {
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
        tearDown(reason: "configure_new_session")
        observationGeneration += 1
        let generation = observationGeneration
        self.session = session
        hasObservedTwoParticipants = false
        lastOpponentDisplayName = nil

        let transport = GroupSessionMessengerTransport(session: session)
        transport.startReceiving(onCommand: onCommand)
        self.transport = transport

        stateTask = Task { [weak self] in
            for await state in session.$state.values {
                guard let self, Task.isCancelled == false, self.isCurrentObservation(generation) else { return }
                AppLog.debug(
                    AppLog.lifecycle + AppLog.game,
                    "SHAREPLAY_GROUP_STATE",
                    outcome: .completed,
                    fields: [
                        .int("generation", generation),
                        .string("groupState", String(describing: state)),
                        .bool("intentionalTeardown", self.isIntentionalTeardown)
                    ]
                )
                if case .invalidated = state {
                    self.cancelParticipantLossDisconnect()
                    if self.isIntentionalTeardown == false {
                        if self.hasObservedTwoParticipants {
                            AppLog.warning(
                                AppLog.lifecycle + AppLog.game,
                                "SHAREPLAY_GROUP_INVALIDATED",
                                outcome: .started,
                                fields: [
                                    .int("generation", generation),
                                    .bool("hasObservedTwoParticipants", self.hasObservedTwoParticipants)
                                ]
                            )
                            self.onDisconnected?()
                        } else {
                            self.schedulePreReadyInvalidationDisconnect(for: generation)
                        }
                    } else {
                        AppLog.info(
                            AppLog.lifecycle + AppLog.game,
                            "SHAREPLAY_GROUP_INVALIDATED",
                            outcome: .ignored,
                            fields: [
                                .reason("intentional_teardown"),
                                .int("generation", generation)
                            ]
                        )
                    }
                    self.tearDown(
                        reason: "group_invalidated",
                        cancelsPreReadyInvalidation: self.isIntentionalTeardown || self.hasObservedTwoParticipants
                    )
                    return
                }
            }
        }

        participantsTask = Task { [weak self] in
            for await participants in session.$activeParticipants.values {
                guard let self, Task.isCancelled == false, self.isCurrentObservation(generation) else { return }
                // GroupActivities `Participant` exposes only an id in iOS 26 — no public
                // display-name API. UI falls back to the localized "Your friend" label.
                self.updateOpponentDisplayNameIfNeeded(nil)
                AppLog.debug(
                    AppLog.lifecycle + AppLog.game,
                    "SHAREPLAY_PARTICIPANTS",
                    outcome: .completed,
                    fields: [
                        .int("generation", generation),
                        .int("participantCount", participants.count),
                        .bool("hasObservedTwoParticipants", self.hasObservedTwoParticipants),
                        .bool("intentionalTeardown", self.isIntentionalTeardown),
                        .bool("participantLossPending", self.participantLossTask != nil)
                    ]
                )
                if participants.count >= 2 {
                    self.cancelParticipantLossDisconnect()
                    if self.hasObservedTwoParticipants == false {
                        self.hasObservedTwoParticipants = true
                        AppLog.info(
                            AppLog.lifecycle + AppLog.game,
                            "SHAREPLAY_PARTICIPANTS_READY",
                            outcome: .completed,
                            fields: [
                                .int("generation", generation),
                                .int("participantCount", participants.count)
                            ]
                        )
                        self.onParticipantsReady?()
                    }
                } else if self.hasObservedTwoParticipants, self.isIntentionalTeardown == false {
                    self.scheduleParticipantLossDisconnect(for: generation)
                } else {
                    AppLog.debug(
                        AppLog.lifecycle + AppLog.game,
                        "SHAREPLAY_PARTICIPANT_LOSS",
                        outcome: .ignored,
                        fields: [
                            .reason(
                                self.hasObservedTwoParticipants
                                ? "intentional_teardown"
                                : "before_ready"
                            ),
                            .int("generation", generation),
                            .int("participantCount", participants.count)
                        ]
                    )
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
    func leave() {
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
        tearDown(reason: "leave")
    }

    private func tearDown(reason: String, cancelsPreReadyInvalidation: Bool = true) {
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
        hasObservedTwoParticipants = false
        updateOpponentDisplayNameIfNeeded(nil)
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

    private func isCurrentObservation(_ generation: Int) -> Bool {
        observationGeneration == generation
    }

    private func schedulePreReadyInvalidationDisconnect(for generation: Int) {
        guard preReadyInvalidationGrace.hasPendingTask == false else {
            AppLog.debug(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_GROUP_INVALIDATED",
                outcome: .ignored,
                fields: [
                    .reason("pre_ready_already_pending"),
                    .int("generation", generation)
                ]
            )
            return
        }

        AppLog.warning(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_GROUP_INVALIDATED",
            outcome: .deferred,
            fields: [
                .reason("pre_ready"),
                .int("generation", generation),
                .double("graceSeconds", preReadyInvalidationGraceDuration)
            ]
        )

        preReadyInvalidationGrace.schedule(
            graceDuration: preReadyInvalidationGraceDuration,
            shouldDisconnect: { [weak self] in
                guard let self else { return false }
                return self.session == nil
                    && self.hasObservedTwoParticipants == false
                    && self.isIntentionalTeardown == false
            },
            onDisconnect: { [weak self] in
                guard let self else { return }
                AppLog.warning(
                    AppLog.lifecycle + AppLog.game,
                    "SHAREPLAY_GROUP_INVALIDATED",
                    outcome: .started,
                    fields: [
                        .reason("pre_ready_grace_elapsed"),
                        .int("generation", generation),
                        .int("currentGeneration", self.observationGeneration)
                    ]
                )
                self.onDisconnected?()
            }
        )
    }

    private func cancelPreReadyInvalidationDisconnect(reason: String) {
        guard preReadyInvalidationGrace.hasPendingTask else { return }
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_GROUP_INVALIDATED",
            outcome: .cancelled,
            fields: [
                .reason(reason),
                .int("generation", observationGeneration)
            ]
        )
        preReadyInvalidationGrace.cancel()
    }

    private func scheduleParticipantLossDisconnect(for generation: Int) {
        guard participantLossTask == nil else {
            AppLog.debug(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_PARTICIPANT_LOSS",
                outcome: .ignored,
                fields: [
                    .reason("already_pending"),
                    .int("generation", generation)
                ]
            )
            return
        }
        AppLog.warning(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_PARTICIPANT_LOSS",
            outcome: .deferred,
            fields: [
                .int("generation", generation),
                .double("graceSeconds", participantLossGraceDuration)
            ]
        )
        let delay = UInt64(max(0, participantLossGraceDuration) * 1_000_000_000)
        participantLossTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard let self else { return }
            guard Task.isCancelled == false else {
                AppLog.debug(
                    AppLog.lifecycle + AppLog.game,
                    "SHAREPLAY_PARTICIPANT_LOSS",
                    outcome: .cancelled,
                    fields: [
                        .reason("task_cancelled"),
                        .int("generation", generation)
                    ]
                )
                return
            }
            guard self.isCurrentObservation(generation),
                  self.hasObservedTwoParticipants,
                  self.isIntentionalTeardown == false else {
                AppLog.warning(
                    AppLog.lifecycle + AppLog.game,
                    "SHAREPLAY_PARTICIPANT_LOSS",
                    outcome: .ignored,
                    fields: [
                        .reason("guard_failed_after_grace"),
                        .int("callbackGeneration", generation),
                        .int("currentGeneration", self.observationGeneration),
                        .bool("hasObservedTwoParticipants", self.hasObservedTwoParticipants),
                        .bool("intentionalTeardown", self.isIntentionalTeardown)
                    ]
                )
                return
            }
            self.participantLossTask = nil
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_PARTICIPANT_LOSS",
                outcome: .started,
                fields: [.int("generation", generation)]
            )
            self.onDisconnected?()
            self.tearDown(reason: "participant_loss")
        }
    }

    private func cancelParticipantLossDisconnect() {
        if participantLossTask != nil {
            AppLog.debug(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_PARTICIPANT_LOSS",
                outcome: .cancelled,
                fields: [.int("generation", observationGeneration)]
            )
        }
        participantLossTask?.cancel()
        participantLossTask = nil
    }

    private func updateOpponentDisplayNameIfNeeded(_ displayName: String?) {
        guard lastOpponentDisplayName != displayName else { return }
        lastOpponentDisplayName = displayName
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_OPPONENT_NAME",
            outcome: .completed,
            fields: [
                .int("generation", observationGeneration),
                .string("opponentName", AppLog.redactedPlayer(displayName))
            ]
        )
        onOpponentDisplayNameChanged?(displayName)
    }
}
#endif

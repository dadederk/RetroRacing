//
//  GroupSessionCoordinator+DisconnectGrace.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 31/07/2026.
//

#if canImport(GroupActivities) && os(iOS)
import GroupActivities
import Combine
import Foundation
import RetroRacingShared

extension GroupSessionCoordinator {
    func schedulePreReadyInvalidationDisconnect(for generation: Int) {
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
            shouldDisconnect: {
                true
            },
            onDisconnect: { [weak self] in
                Task { await self?.completePreReadyInvalidationDisconnect(generation: generation) }
            }
        )
    }

    func cancelPreReadyInvalidationDisconnect(reason: String) {
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

    func completePreReadyInvalidationDisconnect(generation: Int) async {
        guard session == nil,
              hasObservedTwoParticipants == false,
              isIntentionalTeardown == false else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_GROUP_INVALIDATED",
                outcome: .ignored,
                fields: [
                    .reason("guard_failed_after_pre_ready_grace"),
                    .int("callbackGeneration", generation),
                    .int("currentGeneration", observationGeneration),
                    .bool("hasSession", session != nil),
                    .bool("hasObservedTwoParticipants", hasObservedTwoParticipants),
                    .bool("intentionalTeardown", isIntentionalTeardown)
                ]
            )
            return
        }
        AppLog.warning(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_GROUP_INVALIDATED",
            outcome: .started,
            fields: [
                .reason("pre_ready_grace_elapsed"),
                .int("generation", generation),
                .int("currentGeneration", observationGeneration)
            ]
        )
        await onDisconnected?()
    }

    func scheduleParticipantLossDisconnect(for generation: Int) {
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
            guard Task.isCancelled == false else {
                await self?.logParticipantLossTaskCancelled(generation: generation)
                return
            }
            await self?.completeParticipantLossDisconnect(generation: generation)
        }
    }

    func logParticipantLossTaskCancelled(generation: Int) {
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_PARTICIPANT_LOSS",
            outcome: .cancelled,
            fields: [
                .reason("task_cancelled"),
                .int("generation", generation)
            ]
        )
    }

    func completeParticipantLossDisconnect(generation: Int) async {
        guard isCurrentObservation(generation),
              hasObservedTwoParticipants,
              isIntentionalTeardown == false else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_PARTICIPANT_LOSS",
                outcome: .ignored,
                fields: [
                    .reason("guard_failed_after_grace"),
                    .int("callbackGeneration", generation),
                    .int("currentGeneration", observationGeneration),
                    .bool("hasObservedTwoParticipants", hasObservedTwoParticipants),
                    .bool("intentionalTeardown", isIntentionalTeardown)
                ]
            )
            return
        }
        participantLossTask = nil
        AppLog.warning(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_PARTICIPANT_LOSS",
            outcome: .started,
            fields: [.int("generation", generation)]
        )
        await onDisconnected?()
        await tearDown(reason: "participant_loss")
    }

    func cancelParticipantLossDisconnect() {
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
}
#endif

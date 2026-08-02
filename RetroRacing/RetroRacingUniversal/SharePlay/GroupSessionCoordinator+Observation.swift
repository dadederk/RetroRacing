//
//  GroupSessionCoordinator+Observation.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 31/07/2026.
//

#if canImport(GroupActivities) && (os(iOS) || os(macOS))
import GroupActivities
import Combine
import Foundation
import RetroRacingShared

extension GroupSessionCoordinator {
    func isCurrentObservation(_ generation: Int) -> Bool {
        observationGeneration == generation
    }

    func handleReceivedCommand(
        _ command: SharePlayMatchCommand,
        generation: Int,
        onCommand: @Sendable (SharePlayMatchCommand) async -> Void
    ) async {
        let currentGeneration = observationGeneration
        guard isCurrentObservation(generation) else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_COMMAND_RECEIVE",
                outcome: .ignored,
                fields: [
                    .reason("stale_coordinator_generation"),
                    .int("callbackGeneration", generation),
                    .int("currentGeneration", currentGeneration),
                    .string("command", command.diagnosticName)
                ]
            )
            return
        }
        await onCommand(command)
    }

    func handleGroupState(
        _ state: GroupSession<RetroRacingGroupActivity>.State,
        generation: Int
    ) async -> Bool {
        guard isCurrentObservation(generation) else { return false }
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_GROUP_STATE",
            outcome: .completed,
            fields: [
                .int("generation", generation),
                .string("groupState", String(describing: state)),
                .bool("intentionalTeardown", isIntentionalTeardown)
            ]
        )
        if case .joined = state, hasObservedJoinedState == false {
            hasObservedJoinedState = true
            AppLog.info(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_GROUP_JOINED",
                outcome: .completed,
                fields: [.int("generation", generation)]
            )
            await onSessionJoined?()
        }

        guard case .invalidated = state else { return true }

        cancelParticipantLossDisconnect()
        if isIntentionalTeardown == false {
            if hasObservedTwoParticipants {
                AppLog.warning(
                    AppLog.lifecycle + AppLog.game,
                    "SHAREPLAY_GROUP_INVALIDATED",
                    outcome: .started,
                    fields: [
                        .int("generation", generation),
                        .bool("hasObservedTwoParticipants", hasObservedTwoParticipants)
                    ]
                )
                await onDisconnected?()
            } else {
                schedulePreReadyInvalidationDisconnect(for: generation)
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
        await tearDown(
            reason: "group_invalidated",
            cancelsPreReadyInvalidation: isIntentionalTeardown || hasObservedTwoParticipants
        )
        return false
    }
}
#endif

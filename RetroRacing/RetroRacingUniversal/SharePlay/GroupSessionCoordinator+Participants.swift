//
//  GroupSessionCoordinator+Participants.swift
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
    func handleParticipants(
        _ participants: Set<Participant>,
        generation: Int
    ) async -> Bool {
        guard isCurrentObservation(generation) else { return false }
        // GroupActivities `Participant` exposes only an id in iOS 26 — no public
        // display-name API. UI falls back to the localized "Your friend" label.
        await updateOpponentDisplayNameIfNeeded(nil)
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_PARTICIPANTS",
            outcome: .completed,
            fields: [
                .int("generation", generation),
                .int("participantCount", participants.count),
                .bool("hasObservedTwoParticipants", hasObservedTwoParticipants),
                .bool("intentionalTeardown", isIntentionalTeardown),
                .bool("participantLossPending", participantLossTask != nil)
            ]
        )
        let disposition = SharePlayParticipantCountPolicy.disposition(
            participantCount: participants.count,
            hasObservedTwoParticipants: hasObservedTwoParticipants,
            isIntentionalTeardown: isIntentionalTeardown
        )
        switch disposition {
        case .exactlyTwoReady:
            cancelParticipantLossDisconnect()
            hasObservedTwoParticipants = true
            AppLog.info(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_PARTICIPANTS_READY",
                outcome: .completed,
                fields: [
                    .int("generation", generation),
                    .int("participantCount", participants.count)
                ]
            )
            await onParticipantsReady?()
        case .exactlyTwoAlreadyReady:
            cancelParticipantLossDisconnect()
        case .unsupportedMoreThanTwo:
            AppLog.error(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_PARTICIPANTS",
                outcome: .blocked,
                fields: [
                    .reason("unsupported_participant_count"),
                    .int("generation", generation),
                    .int("participantCount", participants.count)
                ]
            )
            session?.leave()
            await onDisconnected?()
            await tearDown(reason: "unsupported_participant_count")
            return false
        case .lossAfterReady:
            scheduleParticipantLossDisconnect(for: generation)
        case .waitingBeforeReady,
             .ignoredIntentionalTeardown:
            let ignoredLossReason = disposition.ignoredLossReason ?? "unknown_participant_loss"
            AppLog.debug(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_PARTICIPANT_LOSS",
                outcome: .ignored,
                fields: [
                    .reason(ignoredLossReason),
                    .int("generation", generation),
                    .int("participantCount", participants.count)
                ]
            )
        }
        return true
    }

    func updateOpponentDisplayNameIfNeeded(_ displayName: String?) async {
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
        await onOpponentDisplayNameChanged?(displayName)
    }
}
#endif

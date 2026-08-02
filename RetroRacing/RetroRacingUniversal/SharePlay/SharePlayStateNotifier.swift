//
//  SharePlayStateNotifier.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 01/08/2026.
//

#if canImport(GroupActivities) && (os(iOS) || os(macOS))
import Foundation
import RetroRacingShared

nonisolated struct SharePlayStateNotification: Sendable {
    let handler: @Sendable (SharePlayUIState) async -> Void
    let state: SharePlayUIState

    func send() async {
        await handler(state)
    }
}

nonisolated struct SharePlayStateNotifier {
    private var stateChangeHandler: (@Sendable (SharePlayUIState) async -> Void)?
    private var lastNotifiedStateName: String?

    mutating func setStateChangeHandler(
        _ handler: @escaping @Sendable (SharePlayUIState) async -> Void
    ) {
        stateChangeHandler = handler
    }

    mutating func clearCache() {
        lastNotifiedStateName = nil
    }

    func idleNotification() -> SharePlayStateNotification? {
        guard let stateChangeHandler else { return nil }
        return SharePlayStateNotification(handler: stateChangeHandler, state: .idle)
    }

    mutating func notification(
        state: SharePlayMatchState?,
        localRole: SharePlayPlayerRole?,
        opponentDisplayName: String?,
        isSessionJoined: Bool,
        generation: Int
    ) -> SharePlayStateNotification? {
        guard let state else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_STATE_NOTIFY",
                outcome: .skipped,
                fields: [
                    .reason("missing_state_machine"),
                    .int("generation", generation)
                ]
            )
            return nil
        }
        guard SharePlaySessionAdmissionPolicy.shouldPublish(
            state: state,
            isSessionJoined: isSessionJoined
        ) else {
            AppLog.debug(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_STATE_NOTIFY",
                outcome: .deferred,
                fields: [
                    .reason("session_not_joined"),
                    .int("generation", generation),
                    .string("state", state.diagnosticName)
                ]
            )
            return nil
        }
        guard let stateChangeHandler else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_STATE_NOTIFY",
                outcome: .skipped,
                fields: [
                    .reason("missing_handler"),
                    .int("generation", generation),
                    .string("state", state.diagnosticName)
                ]
            )
            return nil
        }

        logNotification(state: state, localRole: localRole, generation: generation)
        lastNotifiedStateName = state.diagnosticName
        return SharePlayStateNotification(
            handler: stateChangeHandler,
            state: SharePlayUIState(
                state: state,
                localRole: localRole,
                opponentDisplayName: opponentDisplayName
            )
        )
    }

    private func logNotification(
        state: SharePlayMatchState,
        localRole: SharePlayPlayerRole?,
        generation: Int
    ) {
        let stateName = state.diagnosticName
        if lastNotifiedStateName != stateName {
            AppLog.info(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_STATE_NOTIFY",
                outcome: .completed,
                fields: [
                    .int("generation", generation),
                    .string("previousState", lastNotifiedStateName),
                    .string("newState", stateName),
                    .string("role", localRole?.rawValue)
                ]
            )
        } else {
            AppLog.debug(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_STATE_NOTIFY",
                outcome: .completed,
                fields: [
                    .int("generation", generation),
                    .string("newState", stateName),
                    .bool("sameStateKind", true)
                ]
            )
        }
    }
}
#endif

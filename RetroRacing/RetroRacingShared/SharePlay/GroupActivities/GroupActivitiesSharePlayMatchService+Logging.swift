//
//  GroupActivitiesSharePlayMatchService+Logging.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 31/07/2026.
//

#if canImport(GroupActivities)
import GroupActivities
import Foundation

extension GroupActivitiesSharePlayMatchService {
    func logHostStartBlocked(reason: String, machine: SharePlayMatchStateMachine? = nil) {
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_HOST_START_ROUND",
            outcome: .blocked,
            fields: [
                .reason(reason),
                .int("generation", sessionGeneration),
                .string("state", machine?.state.diagnosticName ?? stateMachine?.state.diagnosticName),
                .string("role", machine?.localRole.rawValue ?? stateMachine?.localRole.rawValue)
            ]
        )
    }

    func logAutoStartBlocked(reason: String, machine: SharePlayMatchStateMachine? = nil) {
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_AUTO_START_ROUND",
            outcome: .blocked,
            fields: [
                .reason(reason),
                .int("generation", sessionGeneration),
                .bool("hasTwoParticipants", sessionRuntimeState.hasTwoParticipants),
                .bool("remoteReady", machine?.isRemoteReady ?? (stateMachine?.isRemoteReady == true)),
                .string("state", machine?.state.diagnosticName ?? stateMachine?.state.diagnosticName),
                .string("role", machine?.localRole.rawValue ?? stateMachine?.localRole.rawValue)
            ]
        )
    }
}
#endif

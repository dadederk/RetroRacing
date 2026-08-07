//
//  GroupActivitiesSharePlayHostActivationController.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/08/2026.
//

#if canImport(GroupActivities)
import Foundation
import GroupActivities

nonisolated enum GroupActivitiesSharePlayHostActivationDisposition: Sendable, Equatable {
    case activate
    case completed(Bool)
}

nonisolated struct GroupActivitiesSharePlayHostActivationDiagnostics: Sendable, Equatable {
    let generation: Int
    let stateName: String?
}

/// Owns host activation state and logging; the service actor owns when to call it.
nonisolated final class GroupActivitiesSharePlayHostActivationController {
    typealias ActivityActivation = @Sendable () async throws -> Bool

    private var isPending = false
    private var isInFlight = false
    private let activateActivity: ActivityActivation

    init(
        activateActivity: @escaping ActivityActivation = {
            try await RetroRacingGroupActivity().activate()
        }
    ) {
        self.activateActivity = activateActivity
    }

    var isPendingHostActivation: Bool {
        isPending
    }

    var isActivationInFlight: Bool {
        isInFlight
    }

    func clearPending() {
        isPending = false
    }

    func prepare(
        source: SharePlayHostActivationReason,
        isSessionActive: Bool,
        diagnostics: GroupActivitiesSharePlayHostActivationDiagnostics
    ) -> Bool {
        if isPending {
            logIgnored(reason: "pending_host_activation", source: source, diagnostics: diagnostics)
            return false
        }
        if isInFlight {
            logIgnored(reason: "activation_in_flight", source: source, diagnostics: diagnostics)
            return false
        }
        if isSessionActive {
            logIgnored(reason: "active_session", source: source, diagnostics: diagnostics)
            return false
        }
        isPending = true
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_HOST_ACTIVATION",
            outcome: .requested,
            fields: [.bool("pendingHostActivation", isPending)]
        )
        return true
    }

    func beginDirectActivation(
        reason: SharePlayHostActivationReason,
        hasDeliveredSession: Bool,
        diagnostics: GroupActivitiesSharePlayHostActivationDiagnostics
    ) -> GroupActivitiesSharePlayHostActivationDisposition {
        guard isPending else {
            logIgnored(reason: "no_pending_host_activation", source: reason, diagnostics: diagnostics)
            return .completed(hasDeliveredSession)
        }
        guard hasDeliveredSession == false else {
            logIgnored(reason: "session_already_delivered", source: reason, diagnostics: diagnostics)
            return .completed(true)
        }
        guard isInFlight == false else {
            logIgnored(reason: "activation_in_flight", source: reason, diagnostics: diagnostics)
            return .completed(true)
        }

        isInFlight = true
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_DIRECT_ACTIVATION",
            outcome: .requested,
            fields: [
                .reason(reason.rawValue),
                .int("generation", diagnostics.generation)
            ]
        )
        return .activate
    }

    func activatePendingActivity() async throws -> Bool {
        try await activateActivity()
    }

    func completeDirectActivation(
        didActivate: Bool,
        reason: SharePlayHostActivationReason,
        sessionWasDelivered: Bool,
        diagnostics: GroupActivitiesSharePlayHostActivationDiagnostics
    ) -> Bool {
        isInFlight = false
        let shouldAwaitSession = didActivate || sessionWasDelivered
        if shouldAwaitSession == false {
            isPending = false
        }
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_DIRECT_ACTIVATION",
            outcome: shouldAwaitSession ? .completed : .failed,
            fields: [
                .reason(reason.rawValue),
                .bool("didActivate", didActivate),
                .bool("sessionWasDelivered", sessionWasDelivered),
                .int("generation", diagnostics.generation)
            ]
        )
        return shouldAwaitSession
    }

    func failDirectActivation(
        error: Error,
        reason: SharePlayHostActivationReason,
        sessionWasDelivered: Bool,
        diagnostics: GroupActivitiesSharePlayHostActivationDiagnostics
    ) -> Bool {
        isInFlight = false
        if sessionWasDelivered == false {
            isPending = false
        }
        AppLog.error(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_DIRECT_ACTIVATION",
            outcome: sessionWasDelivered ? .completed : .failed,
            fields: [
                .reason(reason.rawValue),
                .bool("sessionWasDelivered", sessionWasDelivered),
                .int("generation", diagnostics.generation)
            ] + AppLog.Field.error(error)
        )
        return sessionWasDelivered
    }

    @discardableResult
    func cancel(reason: SharePlayHostActivationReason) -> Bool {
        let wasPending = isPending
        isPending = false
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_HOST_ACTIVATION",
            outcome: wasPending ? .completed : .ignored,
            fields: [.bool("wasPendingHostActivation", wasPending)]
                + [.reason(reason.rawValue)]
        )
        return wasPending
    }

    @discardableResult
    func cancelForLeaveWithoutSession() -> Bool {
        let wasPending = isPending
        isPending = false
        guard wasPending else { return false }
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_HOST_ACTIVATION",
            outcome: .cancelled,
            fields: [
                .reason(SharePlayHostActivationReason.leaveWithoutSession.rawValue),
                .bool("wasPendingHostActivation", wasPending)
            ]
        )
        return true
    }

    private func logIgnored(
        reason: String,
        source: SharePlayHostActivationReason,
        diagnostics: GroupActivitiesSharePlayHostActivationDiagnostics
    ) {
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_HOST_ACTIVATION",
            outcome: .ignored,
            fields: [
                .reason(reason),
                .string("source", source.rawValue),
                .int("generation", diagnostics.generation),
                .string("state", diagnostics.stateName),
                .bool("pendingHostActivation", isPending)
            ]
        )
    }
}
#endif

//
//  GroupActivitiesSharePlayMatchService+Activation.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 31/07/2026.
//

#if canImport(GroupActivities)
import GroupActivities
import Foundation

extension GroupActivitiesSharePlayMatchService {
    public func prepareHostActivation() async -> Bool {
        hostActivationController.prepare(
            source: .menuRequest,
            isSessionActive: stateMachine?.state.isActive == true,
            diagnostics: hostActivationDiagnostics
        )
    }

    public func activatePendingHostSession(reason: SharePlayHostActivationReason) async -> Bool {
        switch hostActivationController.beginDirectActivation(
            reason: reason,
            hasDeliveredSession: hasDeliveredSession,
            diagnostics: hostActivationDiagnostics
        ) {
        case .completed(let result):
            return result
        case .activate:
            break
        }

        do {
            let didActivate = try await hostActivationController.activatePendingActivity()
            return hostActivationController.completeDirectActivation(
                didActivate: didActivate,
                reason: reason,
                sessionWasDelivered: hasDeliveredSession,
                diagnostics: hostActivationDiagnostics
            )
        } catch {
            return hostActivationController.failDirectActivation(
                error: error,
                reason: reason,
                sessionWasDelivered: hasDeliveredSession,
                diagnostics: hostActivationDiagnostics
            )
        }
    }

    public func cancelHostActivation(reason: SharePlayHostActivationReason) async {
        hostActivationController.cancel(reason: reason)
    }

    var hasDeliveredSession: Bool {
        stateMachine?.state.isActive == true
    }

    var hostActivationDiagnostics: GroupActivitiesSharePlayHostActivationDiagnostics {
        GroupActivitiesSharePlayHostActivationDiagnostics(
            generation: sessionGeneration,
            stateName: stateMachine?.state.diagnosticName
        )
    }
}
#endif

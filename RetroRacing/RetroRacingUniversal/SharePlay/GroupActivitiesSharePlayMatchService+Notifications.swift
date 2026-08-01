//
//  GroupActivitiesSharePlayMatchService+Notifications.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 31/07/2026.
//

#if canImport(GroupActivities) && os(iOS)
import GroupActivities
import Foundation
import RetroRacingShared

extension GroupActivitiesSharePlayMatchService {
    public func setStateChangeHandler(
        _ handler: @escaping @Sendable (SharePlayUIState) async -> Void
    ) async {
        stateNotifier.setStateChangeHandler(handler)
    }

    func notifyStateChanged() async {
        guard let notification = stateNotifier.notification(
            state: stateMachine?.state,
            localRole: stateMachine?.localRole,
            opponentDisplayName: sessionRuntimeState.opponentDisplayName,
            isSessionJoined: sessionRuntimeState.isJoined,
            generation: sessionGeneration
        ) else { return }
        await notification.send()
    }
}
#endif

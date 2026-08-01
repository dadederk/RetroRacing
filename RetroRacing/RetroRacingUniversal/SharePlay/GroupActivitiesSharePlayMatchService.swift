//
//  GroupActivitiesSharePlayMatchService.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 22/07/2026.
//

#if canImport(GroupActivities) && os(iOS)
import GroupActivities
import Foundation
import RetroRacingShared

/// Production `SharePlayMatchService` backed by the GroupActivities framework (iOS/iPad only,
/// per v1 scope). This actor owns the match state machine and session runtime state, while
/// small collaborators own local activation, notification, and timer bookkeeping.
public actor GroupActivitiesSharePlayMatchService: SharePlayMatchService {
    let difficultyProvider: @Sendable () -> GameDifficulty
    let coordinator = GroupSessionCoordinator()
    let hostActivationController = GroupActivitiesSharePlayHostActivationController()

    var stateMachine: SharePlayMatchStateMachine?
    var sessionRuntimeState = GroupActivitiesSharePlaySessionRuntimeState()
    var sessionGeneration = 0
    var stateNotifier = SharePlayStateNotifier()
    var isObservingSessions = false
    var timerController = SharePlayMatchTimerController()

    public init(difficultyProvider: @escaping @Sendable () -> GameDifficulty) {
        self.difficultyProvider = difficultyProvider
    }
}

nonisolated struct GroupActivitiesSharePlaySessionRuntimeState {
    var isJoined = false
    var hasTwoParticipants = false
    var opponentDisplayName: String?

    mutating func clear() {
        isJoined = false
        hasTwoParticipants = false
        opponentDisplayName = nil
    }
}
#endif

//
//  GroupActivitiesSharePlayMatchService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

#if canImport(GroupActivities)
import GroupActivities
import Foundation

/// Production `SharePlayMatchService` backed by the GroupActivities framework.
/// This actor owns the match state machine and session runtime state, while
/// small collaborators own local activation, notification, and timer bookkeeping.
public actor GroupActivitiesSharePlayMatchService: SharePlayMatchService {
    let difficultyProvider: @Sendable () -> GameDifficulty
    let trafficSeedProvider: @Sendable () -> UInt64
    let coordinator = GroupSessionCoordinator()
    let hostActivationController = GroupActivitiesSharePlayHostActivationController()

    var stateMachine: SharePlayMatchStateMachine?
    var sessionRuntimeState = GroupActivitiesSharePlaySessionRuntimeState()
    var sessionGeneration = 0
    var stateNotifier = SharePlayStateNotifier()
    var isObservingSessions = false
    var timerController = SharePlayMatchTimerController()

    public init(
        difficultyProvider: @escaping @Sendable () -> GameDifficulty,
        trafficSeedProvider: @escaping @Sendable () -> UInt64 = { UInt64.random(in: UInt64.min...UInt64.max) }
    ) {
        self.difficultyProvider = difficultyProvider
        self.trafficSeedProvider = trafficSeedProvider
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

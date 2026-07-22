//
//  SharePlayUIState.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// Bundles the current SharePlay match state with the local participant's role so both values
/// can be pushed from the composition root (`RetroRacingApp`, which owns the long-lived
/// `SharePlayMatchService` state-change handler) down into `GameView`/`GameViewModel` (which are
/// recreated every play session) as a single atomic update.
public struct SharePlayUIState: Sendable, Equatable {
    public let state: SharePlayMatchState
    public let localRole: SharePlayPlayerRole?
    /// Remote participant display name from GroupActivities, when available.
    public let opponentDisplayName: String?

    public static let idle = SharePlayUIState(state: .idle, localRole: nil, opponentDisplayName: nil)

    public init(
        state: SharePlayMatchState,
        localRole: SharePlayPlayerRole?,
        opponentDisplayName: String? = nil
    ) {
        self.state = state
        self.localRole = localRole
        self.opponentDisplayName = opponentDisplayName
    }
}

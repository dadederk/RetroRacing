//
//  MenuSessionTransitionPolicy.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 05/03/2026.
//

import Foundation

/// Snapshot of menu + gameplay session state used by launch flow transitions.
public struct MenuSessionState: Equatable {
    public let shouldStartGame: Bool
    public let isMenuPresented: Bool
    public let sessionID: UUID

    public init(
        shouldStartGame: Bool,
        isMenuPresented: Bool,
        sessionID: UUID
    ) {
        self.shouldStartGame = shouldStartGame
        self.isMenuPresented = isMenuPresented
        self.sessionID = sessionID
    }
}

/// Pure transition rules for menu Play/Finish actions.
public enum MenuSessionTransitionPolicy {
    /// Play always starts a fresh session and dismisses menu overlays.
    public static func stateAfterPlayRequest(
        from _: MenuSessionState,
        newSessionID: UUID = UUID()
    ) -> MenuSessionState {
        MenuSessionState(
            shouldStartGame: true,
            isMenuPresented: false,
            sessionID: newSessionID
        )
    }

    /// Finish always returns to a pre-game state and shows the menu.
    public static func stateAfterFinishRequest(
        from _: MenuSessionState,
        newSessionID: UUID = UUID()
    ) -> MenuSessionState {
        MenuSessionState(
            shouldStartGame: false,
            isMenuPresented: true,
            sessionID: newSessionID
        )
    }
}

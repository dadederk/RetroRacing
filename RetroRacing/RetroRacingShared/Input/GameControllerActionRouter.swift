//
//  GameControllerActionRouter.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-03-02.
//

import Foundation

/// The outcome of routing a `GameControllerAction` in the current game state.
public enum GameControllerRouteResult: Equatable, Sendable {
    case ignored
    case moveLeft
    case moveRight
    case togglePause
    case requestPlay
}

/// Pure routing logic for game controller actions.
///
/// Routes an action based on game state (menu visibility), keeping
/// the routing rule testable independently of the view layer.
public enum GameControllerActionRouter {
    /// Resolves a controller action into a concrete game outcome.
    ///
    /// - Parameters:
    ///   - action: The action emitted by the controller.
    ///   - isMenuOverlayVisible: Whether the menu/pause overlay is currently visible.
    public static func route(
        action: GameControllerAction,
        isMenuOverlayVisible: Bool
    ) -> GameControllerRouteResult {
        if isMenuOverlayVisible {
            switch action {
            case .pauseResume:
                return .requestPlay
            case .moveLeft, .moveRight:
                return .ignored
            }
        }

        switch action {
        case .moveLeft:
            return .moveLeft
        case .moveRight:
            return .moveRight
        case .pauseResume:
            return .togglePause
        }
    }
}

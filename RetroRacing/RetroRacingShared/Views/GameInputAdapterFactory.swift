//
//  GameInputAdapterFactory.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import Foundation

/// Factory for creating the platform-appropriate input adapter.
public protocol GameInputAdapterFactory {
    func makeAdapter(controller: RacingGameController, hapticController: HapticFeedbackController?) -> GameInputAdapter
}

public struct TouchInputAdapterFactory: GameInputAdapterFactory {
    public init() {}

    public func makeAdapter(controller: RacingGameController, hapticController: HapticFeedbackController?) -> GameInputAdapter {
        TouchGameInputAdapter(controller: controller, hapticController: hapticController)
    }
}

public struct RemoteInputAdapterFactory: GameInputAdapterFactory {
    public init() {}

    public func makeAdapter(controller: RacingGameController, hapticController: HapticFeedbackController?) -> GameInputAdapter {
        RemoteGameInputAdapter(controller: controller, hapticController: hapticController)
    }
}

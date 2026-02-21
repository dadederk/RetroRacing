//
//  InGameHelpPresentationPolicy.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 19/02/2026.
//

import Foundation

/// Pure decision helper for first-run VoiceOver tutorial auto-presentation.
public enum InGameHelpPresentationPolicy {
    public static func shouldAutoPresent(
        voiceOverRunning: Bool,
        hasSeenTutorial: Bool,
        shouldStartGame: Bool,
        hasScene: Bool,
        isScenePaused: Bool
    ) -> Bool {
        voiceOverRunning
            && hasSeenTutorial == false
            && shouldStartGame
            && hasScene
            && isScenePaused == false
    }
}

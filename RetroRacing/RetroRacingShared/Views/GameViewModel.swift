//
//  GameViewModel.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI
import SpriteKit
import Observation

@MainActor
@Observable
final class GameViewModel {
    var scene: GameScene?
    var delegate: GameSceneDelegateImpl?
    var inputAdapter: GameInputAdapter?
    var hud = HUDState()
    var pause = PauseState()
    var controls = ControlState()
    var isMenuOverlayPresented = false

    let leaderboardService: LeaderboardService
    let ratingService: RatingService
    let theme: (any GameTheme)?
    let hapticController: HapticFeedbackController?
    let highestScoreStore: HighestScoreStore
    let inputAdapterFactory: any GameInputAdapterFactory
    /// Optional play limit service used to record daily plays.
    let playLimitService: PlayLimitService?
    var selectedDifficulty: GameDifficulty
    var selectedAudioFeedbackMode: AudioFeedbackMode
    var selectedLaneMoveCueStyle: LaneMoveCueStyle
    var shouldStartGame: Bool

    init(
        leaderboardService: LeaderboardService,
        ratingService: RatingService,
        theme: (any GameTheme)?,
        hapticController: HapticFeedbackController?,
        highestScoreStore: HighestScoreStore,
        inputAdapterFactory: any GameInputAdapterFactory,
        playLimitService: PlayLimitService?,
        selectedDifficulty: GameDifficulty,
        selectedAudioFeedbackMode: AudioFeedbackMode,
        selectedLaneMoveCueStyle: LaneMoveCueStyle,
        shouldStartGame: Bool
    ) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        self.theme = theme
        self.hapticController = hapticController
        self.highestScoreStore = highestScoreStore
        self.inputAdapterFactory = inputAdapterFactory
        self.playLimitService = playLimitService
        self.selectedDifficulty = selectedDifficulty
        self.selectedAudioFeedbackMode = selectedAudioFeedbackMode
        self.selectedLaneMoveCueStyle = selectedLaneMoveCueStyle
        self.shouldStartGame = shouldStartGame
    }

    var pauseButtonDisabled: Bool {
        pause.pauseButtonDisabled
    }
}

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
    let achievementProgressService: AchievementProgressService
    let inputAdapterFactory: any GameInputAdapterFactory
    /// Optional play limit service used to record daily plays.
    let playLimitService: PlayLimitService?
    var selectedDifficulty: GameDifficulty
    var selectedAudioFeedbackMode: AudioFeedbackMode
    var selectedLaneMoveCueStyle: LaneMoveCueStyle
    var selectedBigRivalCarsEnabled: Bool
    var selectedRoadVisualStyle: RoadVisualStyle
    var shouldStartGame: Bool
    var runInputTelemetry = RunAchievementTelemetry()
    var friendSnapshot: FriendLeaderboardSnapshot?
    var runBaselineBestScore: Int = 0
    var overtakenFriendPlayerIDs = Set<String>()
    var currentUpcomingFriendMilestone: UpcomingFriendMilestone?
    var pendingFriendOvertakeAnnouncement: String?
    var debugForcedAchievementIdentifier: AchievementIdentifier?
    var debugShowsSpriteKitFrameStats = false

    init(
        leaderboardService: LeaderboardService,
        ratingService: RatingService,
        theme: (any GameTheme)?,
        hapticController: HapticFeedbackController?,
        highestScoreStore: HighestScoreStore,
        achievementProgressService: AchievementProgressService,
        inputAdapterFactory: any GameInputAdapterFactory,
        playLimitService: PlayLimitService?,
        selectedDifficulty: GameDifficulty,
        selectedAudioFeedbackMode: AudioFeedbackMode,
        selectedLaneMoveCueStyle: LaneMoveCueStyle,
        selectedBigRivalCarsEnabled: Bool,
        selectedRoadVisualStyle: RoadVisualStyle,
        shouldStartGame: Bool
    ) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        self.theme = theme
        self.hapticController = hapticController
        self.highestScoreStore = highestScoreStore
        self.achievementProgressService = achievementProgressService
        self.inputAdapterFactory = inputAdapterFactory
        self.playLimitService = playLimitService
        self.selectedDifficulty = selectedDifficulty
        self.selectedAudioFeedbackMode = selectedAudioFeedbackMode
        self.selectedLaneMoveCueStyle = selectedLaneMoveCueStyle
        self.selectedBigRivalCarsEnabled = selectedBigRivalCarsEnabled
        self.selectedRoadVisualStyle = selectedRoadVisualStyle
        self.shouldStartGame = shouldStartGame
    }

    var pauseButtonDisabled: Bool {
        pause.pauseButtonDisabled
    }
}

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
    /// Optional special-event service. When an event is active, play recording is skipped.
    let specialEventService: SpecialEventService?
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

    /// Optional SharePlay match service. `nil` outside the v1 iOS/iPad scope, in previews, and
    /// in tests. Used to report local score/elimination and to drive retry/leave actions.
    let sharePlayMatchService: (any SharePlayMatchService)?
    /// Mirrors the app-level SharePlay state. `GameViewModel` is recreated every session, so the
    /// long-lived state-change handler lives at the composition root; `GameView` pushes updates
    /// down here via `applySharePlayState(_:)`, matching the existing `shouldStartGame` flow.
    var sharePlayState: SharePlayMatchState = .idle
    /// The local participant's role for the active SharePlay match, if any.
    var sharePlayLocalRole: SharePlayPlayerRole?
    var sharePlayOpponentName: String?
    /// Captures/restores the guest's own difficulty selection around a SharePlay match.
    var sharePlayGuestSpeedRestore = SharePlayGuestSpeedRestore()
    /// Prevents duplicate SharePlay countdown beeps while SwiftUI's timeline refreshes.
    var sharePlayCountdownCueScheduler = SharePlayCountdownCueScheduler()
    /// Stable social recap for the finished SharePlay result sheet.
    var sharePlayResultSocialStats: GameOverSocialStatsSummary?

    init(
        leaderboardService: LeaderboardService,
        ratingService: RatingService,
        theme: (any GameTheme)?,
        hapticController: HapticFeedbackController?,
        highestScoreStore: HighestScoreStore,
        achievementProgressService: AchievementProgressService,
        inputAdapterFactory: any GameInputAdapterFactory,
        playLimitService: PlayLimitService?,
        specialEventService: SpecialEventService?,
        sharePlayMatchService: (any SharePlayMatchService)? = nil,
        initialSharePlayUIState: SharePlayUIState = .idle,
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
        self.specialEventService = specialEventService
        self.sharePlayMatchService = sharePlayMatchService
        self.sharePlayState = initialSharePlayUIState.state
        self.sharePlayLocalRole = initialSharePlayUIState.localRole
        self.sharePlayOpponentName = initialSharePlayUIState.opponentDisplayName
        self.selectedDifficulty = selectedDifficulty
        self.selectedAudioFeedbackMode = selectedAudioFeedbackMode
        self.selectedLaneMoveCueStyle = selectedLaneMoveCueStyle
        self.selectedBigRivalCarsEnabled = selectedBigRivalCarsEnabled
        self.selectedRoadVisualStyle = selectedRoadVisualStyle
        self.shouldStartGame = shouldStartGame

        if case .finished(let result) = initialSharePlayUIState.state {
            captureSharePlayResultSocialStatsIfNeeded(
                finalScore: result.score(for: initialSharePlayUIState.localRole ?? .host)
            )
        }
    }

    var pauseButtonDisabled: Bool {
        pause.pauseButtonDisabled
    }
}

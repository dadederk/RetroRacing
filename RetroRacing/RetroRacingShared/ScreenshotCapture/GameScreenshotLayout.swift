//
//  GameScreenshotLayout.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public struct GameScreenshotLayout: Sendable {
    public let gridState: GridState
    public let safetyMarkerRows: [Int]
    public let score: Int
    public let lives: Int
    public let speedIncreaseImminent: Bool
    public let upcomingMilestones: [UpcomingFriendMilestone]

    public init(
        gridState: GridState,
        safetyMarkerRows: [Int],
        score: Int,
        lives: Int,
        speedIncreaseImminent: Bool,
        upcomingMilestones: [UpcomingFriendMilestone]
    ) {
        self.gridState = gridState
        self.safetyMarkerRows = safetyMarkerRows
        self.score = score
        self.lives = lives
        self.speedIncreaseImminent = speedIncreaseImminent
        self.upcomingMilestones = upcomingMilestones
    }

    public static let hookGameplay = GameScreenshotLayout(
        gridState: Self.makeHookGrid(),
        safetyMarkerRows: [],
        score: ScreenshotFixtureCatalog.hookGameplayScore,
        lives: 3,
        speedIncreaseImminent: false,
        upcomingMilestones: []
    )

    public static let actionGameplay = GameScreenshotLayout(
        gridState: Self.makeActionGrid(),
        safetyMarkerRows: [1, 2],
        score: ScreenshotFixtureCatalog.actionGameplayScore,
        lives: ScreenshotFixtureCatalog.actionGameplayLives,
        speedIncreaseImminent: true,
        upcomingMilestones: []
    )

    /// Same crash grid as action gameplay, but HUD score matches the game-over sheet run score
    /// so iPad/Mac sheet chrome that reveals the background stays consistent.
    public static let gameOverBackground = GameScreenshotLayout(
        gridState: Self.makeActionGrid(),
        safetyMarkerRows: [1, 2],
        score: ScreenshotFixtureCatalog.gameOverRunScore,
        lives: 0,
        speedIncreaseImminent: false,
        upcomingMilestones: []
    )

    public static func friendMarkerGameplay() -> GameScreenshotLayout {
        GameScreenshotLayout(
            gridState: Self.makeFriendMarkerGrid(),
            safetyMarkerRows: [],
            score: ScreenshotFixtureCatalog.friendMarkerCurrentScore,
            lives: 3,
            speedIncreaseImminent: false,
            upcomingMilestones: [ScreenshotFixtureCatalog.rivalFriendMilestone()]
        )
    }

    private static func makeHookGrid() -> GridState {
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid[0] = [.Car, .Empty, .Car]
        gridState.grid[1] = [.Empty, .Car, .Empty]
        gridState.grid[2] = [.Car, .Empty, .Empty]
        gridState.grid[3] = [.Empty, .Car, .Empty]
        gridState.grid[4] = [.Empty, .Player, .Empty]
        return gridState
    }

    private static func makeActionGrid() -> GridState {
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid[0] = [.Car, .Empty, .Car]
        gridState.grid[1] = [.Empty, .Car, .Empty]
        gridState.grid[2] = [.Empty, .Empty, .Car]
        gridState.grid[3] = [.Empty, .Car, .Empty]
        gridState.grid[4] = [.Empty, .Empty, .Crash]
        return gridState
    }

    private static func makeFriendMarkerGrid() -> GridState {
        var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gridState.grid[0] = [.Empty, .Car, .Empty]
        gridState.grid[1] = [.Car, .Empty, .Car]
        gridState.grid[2] = [.Car, .Car, .Empty]
        gridState.grid[3] = [.Car, .Car, .Empty]
        gridState.grid[4] = [.Empty, .Player, .Empty]
        return gridState
    }
}

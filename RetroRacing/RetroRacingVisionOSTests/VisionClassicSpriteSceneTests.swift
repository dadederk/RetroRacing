//
//  VisionClassicSpriteSceneTests.swift
//  RetroRacingVisionOSTests
//
//  Created by Dani Devesa on 07/08/2026.
//

import CoreGraphics
import SpriteKit
import Testing
@testable import RetroRacingShared

struct VisionClassicSpriteSceneTests {
    @MainActor
    @Test("Classic renders coordinator snapshots through the shared SpriteKit scene")
    func sharedSnapshotRenderer() throws {
        let collisionSnapshot = try #require(GameSnapshot.fixture(
            phase: .collision,
            grid: [
                [.rival, .empty, .rival],
                [.empty, .empty, .empty],
                [.empty, .rival, .empty],
                [.empty, .empty, .empty],
                [.empty, .crash, .empty]
            ],
            playerColumn: 1,
            score: 12,
            lives: 2,
            level: 2,
            roadPhase: 1,
            safetyMarkerRows: [],
            difficulty: .rapid,
            activePauseReasons: []
        ))
        let scene = GameScene.snapshotRenderingScene(
            size: CGSize(width: 600, height: 600),
            snapshot: collisionSnapshot,
            theme: ThirtyTwoBitTheme(),
            imageLoader: PlatformFactories.makeImageLoader(),
            roadVisualStyle: .detailedRoad
        )

        scene.setUpScene()

        let crashSprite = try #require(scene.spritesForGivenState.first {
            $0.name == GameSpriteNodeName.crash
        })
        #expect(scene.roadSurfaceNodes.count == collisionSnapshot.numberOfRows)
        #expect(scene.lineOverlayNodes.contains { $0.name == "road_dash_line" })
        #expect(crashSprite.size.height <= scene.sizeForCell().height)
        #expect(scene.gameState.score == collisionSnapshot.score)
        #expect(scene.gameState.lives == collisionSnapshot.lives)

        scene.update(10)
        #expect(scene.gameState.score == collisionSnapshot.score)
    }

    @MainActor
    @Test("A later coordinator snapshot replaces the crash without starting another game engine")
    func subsequentSnapshotReplacesCrash() throws {
        let collisionSnapshot = try #require(makeSnapshot(phase: .collision, occupant: .crash))
        let runningSnapshot = try #require(makeSnapshot(phase: .running, occupant: .player))
        let scene = GameScene.snapshotRenderingScene(
            size: CGSize(width: 600, height: 600),
            snapshot: collisionSnapshot,
            theme: SixtyFourBitTheme(),
            imageLoader: PlatformFactories.makeImageLoader()
        )
        scene.setUpScene()

        scene.render(snapshot: runningSnapshot)

        #expect(scene.spritesForGivenState.contains { $0.name == GameSpriteNodeName.crash } == false)
        #expect(scene.playerSpriteNode != nil)
        #expect(scene.gameState.isPaused == false)
    }

    private func makeSnapshot(
        phase: GamePhase,
        occupant: GameGridOccupant
    ) -> GameSnapshot? {
        GameSnapshot.fixture(
            phase: phase,
            grid: [
                [.empty, .empty, .empty],
                [.empty, .empty, .empty],
                [.empty, .rival, .empty],
                [.empty, .empty, .empty],
                [.empty, occupant, .empty]
            ],
            playerColumn: 1,
            score: 4,
            lives: 2,
            level: 1,
            roadPhase: 0,
            safetyMarkerRows: [],
            difficulty: .cruise,
            activePauseReasons: []
        )
    }
}

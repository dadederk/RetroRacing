//
//  VisionGameSessionCoordinatorTests.swift
//  RetroRacingVisionOSTests
//
//  Created by Dani Devesa on 05/08/2026.
//

import RealityKit
import UIKit
import XCTest
@testable import RetroRacingShared
@testable import RetroRacingVisionOS

@MainActor
final class VisionGameSessionCoordinatorTests: XCTestCase {
    func testGivenVisionOSCatalogWhenResolvingGalleryAssetsThenEveryThemeSpriteExists() {
        let bundle = VisionThemeSpriteAssets.bundle

        for theme in ThemePlatformConfig.visionOS.availableThemes {
            let assetNames = [
                theme.playerCarSprite(),
                theme.rivalCarSprite(),
                theme.lifeSprite(),
                theme.resolvedFriendLifeSprite(),
                theme.crashSprite(),
            ].compactMap { $0 }

            XCTAssertEqual(assetNames.count, 5, "Missing asset name for \(theme.id.rawValue)")
            for assetName in assetNames {
                XCTAssertNotNil(
                    UIImage(named: assetName, in: bundle, compatibleWith: nil),
                    "Missing visionOS asset \(assetName) for \(theme.id.rawValue)"
                )
            }
        }
    }

    func testGivenFreshSessionWhenPlayIsRequestedThenEngineStartsAndSchedulerRuns() {
        let scheduler = ManualGameLoopScheduler()
        let session = makeSession(scheduler: scheduler)

        session.play()

        XCTAssertEqual(session.snapshot.phase, .running)
        XCTAssertEqual(session.screen, .playing)
        XCTAssertTrue(scheduler.isRunning)
    }

    func testGivenAnyClassicThemeWhenRaceIsActiveThenSpatialEntryIsAvailable() {
        let session = makeSession()

        session.play()

        XCTAssertTrue(session.canEnterSpatialMode)
    }

    func testGivenActiveRunWhenVolumeAndRendererBecomeReadyThenSnapshotIsPreserved() async {
        let scheduler = ManualGameLoopScheduler()
        let recorder = SpatialActionRecorder()
        let session = makeSession(scheduler: scheduler)
        session.play()
        session.moveLeft()
        scheduler.tick(1.3)
        let snapshotBeforeEntry = session.snapshot

        let transitionID = await enterReady(session: session, recorder: recorder)

        XCTAssertNotNil(transitionID)
        XCTAssertEqual(session.presentation, .spatial)
        XCTAssertEqual(session.spatialState, .ready)
        assertSameRun(session.snapshot, snapshotBeforeEntry)
        XCTAssertEqual(session.snapshot.activePauseReasons, [.spatialReady])
        XCTAssertEqual(recorder.pushedVolumeIDs, [VisionSceneID.spatial])
        XCTAssertEqual(recorder.dismissedWindowIDs, [VisionSceneID.classic])
    }

    func testGivenReadyVolumeWhenPlayIsSelectedThenReadyPauseClears() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = await enterReady(session: session, recorder: recorder)

        session.startSpatialGame()

        XCTAssertEqual(session.spatialState, .active)
        XCTAssertFalse(session.snapshot.activePauseReasons.contains(.spatialReady))
        XCTAssertEqual(session.snapshot.phase, .running)
    }

    func testGivenUserPausedRunWhenReadyResumeIsSelectedThenUserAndReadyPausesClear() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        session.togglePause()
        _ = await enterReady(session: session, recorder: recorder)

        session.startSpatialGame()

        XCTAssertEqual(session.spatialState, .active)
        XCTAssertEqual(session.snapshot.phase, .running)
        XCTAssertFalse(session.isUserPaused)
        XCTAssertFalse(session.snapshot.activePauseReasons.contains(.spatialReady))
    }

    func testGivenSpatialEntryInProgressWhenRequestedAgainThenDuplicateIsRejected() {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()

        let first = session.beginSpatialPresentation(using: recorder.actions)
        let second = session.beginSpatialPresentation(using: recorder.actions)

        XCTAssertTrue(first)
        XCTAssertFalse(second)
    }

    func testGivenPreflightWhenCancelledThenClassicAndExactRunAreRestored() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        let snapshot = session.snapshot
        _ = session.beginSpatialPresentation(using: recorder.actions)

        session.cancelSpatialPresentation(using: recorder.actions)
        await settleTasks()

        XCTAssertEqual(session.spatialState, .inactive)
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(session.snapshot, snapshot)
        XCTAssertEqual(recorder.pushedVolumeIDs, [])
        XCTAssertEqual(recorder.dismissedWindowIDs, [])
    }

    func testGivenOpeningVolumeWhenCancelledThenVolumeDismissesAndRunRestores() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        let snapshot = session.snapshot
        _ = session.beginSpatialPresentation(using: recorder.actions)
        await settleTasks()

        session.cancelSpatialPresentation(using: recorder.actions)
        await settleTasks()

        XCTAssertEqual(session.spatialState, .inactive)
        XCTAssertEqual(session.snapshot, snapshot)
        XCTAssertEqual(recorder.dismissedWindowIDs, [VisionSceneID.spatial])
    }

    func testGivenStaleRendererCallbackWhenNewEntryIsOpeningThenCallbackIsIgnored() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = session.beginSpatialPresentation(using: recorder.actions)
        await settleTasks()
        let staleID = session.currentSpatialTransitionID()
        session.cancelSpatialPresentation(using: recorder.actions)
        await settleTasks()
        _ = session.beginSpatialPresentation(using: recorder.actions)
        await settleTasks()
        let currentID = session.currentSpatialTransitionID()

        if let staleID {
            session.spatialContentDidBecomeReady(
                transitionID: staleID,
                using: recorder.actions
            )
        }

        XCTAssertNotEqual(staleID, currentID)
        XCTAssertEqual(session.spatialState, .opening)
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(recorder.dismissedWindowIDs, [VisionSceneID.spatial])
    }

    func testGivenModelPreflightFailureThenVolumeDoesNotPush() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession(modelRepository: FailingModelRepository())
        session.play()

        _ = session.beginSpatialPresentation(using: recorder.actions)
        await settleTasks()

        XCTAssertEqual(session.spatialState, .failure(.modelUnavailable))
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(recorder.pushedVolumeIDs, [])
        XCTAssertFalse(session.snapshot.activePauseReasons.contains(.spatialReady))
    }

    func testGivenSystemVolumeCloseWhenSpatialIsActiveThenClassicAndSnapshotRestore() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = await activateSpatial(session: session, recorder: recorder)
        let snapshot = session.snapshot

        session.spatialSceneDidDisappear(using: recorder.actions)
        session.spatialSceneDidDisappear(using: recorder.actions)

        XCTAssertEqual(session.spatialState, .inactive)
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(session.snapshot, snapshot)
        XCTAssertEqual(recorder.openedWindowIDs, [VisionSceneID.classic])
    }

    func testGivenAppBackgroundingWhenSpatialIsActiveThenReturnWaitsForClassicReadiness() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = await activateSpatial(session: session, recorder: recorder)

        session.spatialDidEnterBackground(using: recorder.actions)
        let stateBeforeClassicReady = session.spatialState
        await settleTasks()
        session.classicDidBecomeReady()

        XCTAssertEqual(stateBeforeClassicReady, .returning)
        XCTAssertEqual(session.spatialState, .inactive)
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(recorder.openedWindowIDs, [VisionSceneID.classic])
        XCTAssertEqual(
            recorder.dismissedWindowIDs,
            [VisionSceneID.classic, VisionSceneID.spatial]
        )
    }

    func testGivenReturnRequestedTwiceThenVolumeDismissesOnce() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = await activateSpatial(session: session, recorder: recorder)

        let first = session.beginReturnToClassic(using: recorder.actions)
        let second = session.beginReturnToClassic(using: recorder.actions)
        await settleTasks()

        XCTAssertTrue(first)
        XCTAssertFalse(second)
        XCTAssertEqual(recorder.openedWindowIDs, [VisionSceneID.classic])
        XCTAssertEqual(
            recorder.dismissedWindowIDs,
            [VisionSceneID.classic, VisionSceneID.spatial]
        )
    }

    func testGivenRepeatedSpatialSwitchingThenEveryRunUsesANewTokenAndPreservesSnapshot() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        let snapshot = session.snapshot

        let firstID = await activateSpatial(session: session, recorder: recorder)
        _ = session.beginReturnToClassic(using: recorder.actions)
        await settleTasks()
        session.classicDidBecomeReady()
        let secondID = await activateSpatial(session: session, recorder: recorder)

        XCTAssertNotEqual(firstID, secondID)
        assertSameRun(session.snapshot, snapshot)
        XCTAssertEqual(session.spatialState, .active)
    }

    func testGivenIncomingSharePlayWhenSpatialIsActiveThenClassicHandoffPrecedesMatchState() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = await activateSpatial(session: session, recorder: recorder)

        session.applySharePlayState(waitingSharePlayState(role: .guest))
        let didBeginReturn = session.beginReturnToClassic(using: recorder.actions)
        await settleTasks()
        session.classicDidBecomeReady()

        XCTAssertTrue(didBeginReturn)
        XCTAssertFalse(session.requiresClassicForSharePlay)
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertTrue(session.snapshot.activePauseReasons.contains(.sharePlay))
    }

    func testGivenSharePlayArrivesDuringPreflightWhenEntryCancelsThenStateAppliesInClassic() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = session.beginSpatialPresentation(using: recorder.actions)
        session.applySharePlayState(waitingSharePlayState(role: .host))

        session.cancelSpatialPresentation(using: recorder.actions)
        await settleTasks()

        XCTAssertEqual(session.spatialState, .inactive)
        XCTAssertFalse(session.requiresClassicForSharePlay)
        XCTAssertTrue(session.snapshot.activePauseReasons.contains(.sharePlay))
    }

    func testGivenGameOverInSpatialModeWhenReturningThenExactSnapshotRemains() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession(engine: GameOverFixtureEngine())
        session.play()
        _ = await activateSpatial(session: session, recorder: recorder)
        let gameOverSnapshot = session.snapshot

        _ = session.beginReturnToClassic(using: recorder.actions)
        await settleTasks()
        session.classicDidBecomeReady()

        XCTAssertEqual(session.screen, .gameOver)
        XCTAssertEqual(session.snapshot, gameOverSnapshot)
        XCTAssertEqual(session.presentation, .classic)
    }

    func testGivenGameOverInSpatialModeWhenFinishIsSelectedThenRunResetsAndVolumeDismisses() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession(engine: GameOverFixtureEngine())
        session.play()
        _ = await activateSpatial(session: session, recorder: recorder)

        session.finishSpatialPresentation(using: recorder.actions)
        await settleTasks()

        XCTAssertEqual(session.screen, .menu)
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(session.spatialState, .inactive)
        XCTAssertEqual(session.snapshot.phase, .finished)
        XCTAssertEqual(recorder.openedWindowIDs, [VisionSceneID.classic])
        XCTAssertEqual(
            recorder.dismissedWindowIDs,
            [VisionSceneID.classic, VisionSceneID.spatial]
        )
    }

    func testGivenSettingsOverlayAndUserPauseWhenSettingsClosesThenUserPauseRemains() {
        let session = makeSession()
        session.play()

        session.setOverlayPresented(true)
        session.togglePause()
        session.setOverlayPresented(false)

        XCTAssertEqual(session.snapshot.activePauseReasons, [.user])
    }

    func testGivenControllerActionsWhenRaceIsActiveThenTheyUseSharedCommands() {
        let controller = RecordingControllerInputSource()
        let session = makeSession(controllerInputSource: controller)
        session.play()

        controller.send(.moveLeft)
        controller.send(.pauseResume)

        XCTAssertEqual(session.snapshot.playerColumn, 0)
        XCTAssertTrue(session.isUserPaused)
    }

    func testGivenLaneSelectionsWhenTargetingCurrentOrAdjacentLaneThenOnlyAdjacentMoves() {
        let session = makeSession()
        session.play()

        session.selectLane(1)
        let afterCurrentLane = session.snapshot.playerColumn
        session.selectLane(0)

        XCTAssertEqual(afterCurrentLane, 1)
        XCTAssertEqual(session.snapshot.playerColumn, 0)
    }

    func testGivenDirectTouchPreferenceWhenEvaluatingSurfacesThenOnlyRaceBoardsAreEligible() {
        let enabledSurfaces = VisionDirectTouchSurface.allCases.filter {
            VisionGameInteractionPolicy.isDirectTouchEnabled(on: $0, userEnabled: true)
        }

        XCTAssertEqual(enabledSurfaces, [.classicBoard, .tabletopRoad])
    }

    func testGivenVolumeRouterWhenSwitchingPresentationsThenInjectedActionsAreUsed() async {
        let recorder = SpatialActionRecorder()
        let router = VisionVolumeRouter(
            volumeID: VisionSceneID.spatial,
            classicWindowID: VisionSceneID.classic
        )

        router.push(using: recorder.actions)
        router.hideClassic(using: recorder.actions)
        router.restoreClassic(using: recorder.actions)
        await router.dismiss(using: recorder.actions)

        XCTAssertEqual(recorder.pushedVolumeIDs, [VisionSceneID.spatial])
        XCTAssertEqual(recorder.openedWindowIDs, [VisionSceneID.classic])
        XCTAssertEqual(
            recorder.dismissedWindowIDs,
            [VisionSceneID.classic, VisionSceneID.spatial]
        )
    }

    func testGivenPackagedModelWhenLoadingTwiceThenRepositoryLoadsOnlyOnce() async throws {
        let repository = TabletopModelRepository(
            playerResourceName: "player-car-64bit",
            rivalResourceName: "rival-car-64bit",
            bundle: .main
        )

        let first = try await repository.canonicalCars()
        let second = try await repository.canonicalCars()

        XCTAssertTrue(first.player === second.player)
        XCTAssertTrue(first.rival === second.rival)
        XCTAssertFalse(first.player === first.rival)
        XCTAssertEqual(repository.loadCount, 2)
    }

    func testGivenPackagedModelsWhenInspectingVisibleGeometryThenEveryModelHasMaterials() async throws {
        let repository = TabletopModelRepository(
            playerResourceName: "player-car-64bit",
            rivalResourceName: "rival-car-64bit",
            bundle: .main
        )

        let cars = try await repository.canonicalCars()

        for car in [cars.player, cars.rival] {
            let models = enabledModels(in: car, ancestorsEnabled: true)
            XCTAssertFalse(models.isEmpty)
            XCTAssertTrue(models.allSatisfy { $0.materials.isEmpty == false })
        }
    }

    func testGivenInvalidModelResourceWhenLoadingThenTypedFailureIsThrown() async {
        let repository = TabletopModelRepository(
            playerResourceName: "missing-player-car",
            rivalResourceName: "missing-rival-car",
            bundle: .main
        )

        do {
            _ = try await repository.canonicalCars()
            XCTFail("Expected the invalid resource to fail")
        } catch let error as TabletopModelError {
            XCTAssertEqual(error, .resourceUnavailable)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeSession(
        engine: (any GameEngineProtocol)? = nil,
        scheduler: ManualGameLoopScheduler? = nil,
        modelRepository: (any TabletopModelRepositoryProtocol)? = nil,
        controllerInputSource: (any GameControllerInputSource)? = nil,
        difficultyProvider: @escaping @MainActor () -> GameDifficulty = { .rapid }
    ) -> VisionGameSessionCoordinator {
        let scheduler = scheduler ?? ManualGameLoopScheduler()
        let audioFeedbackCoordinator = GameplayAudioFeedbackCoordinator(
            soundPlayer: VisionTestSoundPlayer(),
            laneCuePlayer: VisionTestLaneCuePlayer(),
            hapticController: nil,
            speedWarningPlayer: VisionTestSpeedWarningPlayer(),
            preferences: GameplayAudioFeedbackPreferences(
                volume: { 0.8 },
                mode: { .retro },
                laneMoveStyle: { .laneConfirmation },
                speedWarningMode: { .none }
            )
        )
        let modelRepository = modelRepository ?? StubModelRepository()
        let spatialPresentationCoordinator = VisionSpatialPresentationCoordinator(
            volumeRouter: VisionVolumeRouter(
                volumeID: VisionSceneID.spatial,
                classicWindowID: VisionSceneID.classic
            ),
            modelRepository: modelRepository
        )
        let session = VisionGameSessionCoordinator(
            engine: engine ?? GameEngine(
                randomSource: VisionTestRandomSource(),
                difficulty: .rapid,
                trafficMode: .seeded(64)
            ),
            scheduler: scheduler,
            spatialPresentationCoordinator: spatialPresentationCoordinator,
            tabletopModelRepository: modelRepository,
            controllerInputSource: controllerInputSource ?? RecordingControllerInputSource(),
            difficultyProvider: difficultyProvider,
            sharePlayMatchService: NoOpSharePlayMatchService(),
            audioFeedbackCoordinator: audioFeedbackCoordinator,
            leaderboardService: VisionTestLeaderboardService(),
            highestScoreStore: VisionTestHighestScoreStore(),
            announcementPoster: VisionTestAnnouncementPoster()
        )
        session.setPresentationActive(.classic, isActive: true)
        return session
    }

    private func enterReady(
        session: VisionGameSessionCoordinator,
        recorder: SpatialActionRecorder
    ) async -> VisionSpatialTransitionID? {
        if session.spatialState == .inactive {
            XCTAssertTrue(session.beginSpatialPresentation(using: recorder.actions))
        }
        await settleTasks()
        let transitionID = session.currentSpatialTransitionID()
        if let transitionID {
            session.spatialContentDidBecomeReady(
                transitionID: transitionID,
                using: recorder.actions
            )
        }
        return transitionID
    }

    private func activateSpatial(
        session: VisionGameSessionCoordinator,
        recorder: SpatialActionRecorder
    ) async -> VisionSpatialTransitionID? {
        let transitionID = await enterReady(session: session, recorder: recorder)
        session.startSpatialGame()
        return transitionID
    }

    private func assertSameRun(
        _ actual: GameSnapshot,
        _ expected: GameSnapshot,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual.grid, expected.grid, file: file, line: line)
        XCTAssertEqual(actual.playerColumn, expected.playerColumn, file: file, line: line)
        XCTAssertEqual(actual.score, expected.score, file: file, line: line)
        XCTAssertEqual(actual.lives, expected.lives, file: file, line: line)
        XCTAssertEqual(actual.level, expected.level, file: file, line: line)
        XCTAssertEqual(actual.roadPhase, expected.roadPhase, file: file, line: line)
        XCTAssertEqual(actual.safetyMarkerRows, expected.safetyMarkerRows, file: file, line: line)
        XCTAssertEqual(actual.difficulty, expected.difficulty, file: file, line: line)
    }

    private func waitingSharePlayState(role: SharePlayPlayerRole) -> SharePlayUIState {
        SharePlayUIState(
            state: .waitingForFriend,
            localRole: role,
            opponentDisplayName: "Alex"
        )
    }

    private func settleTasks() async {
        for _ in 0..<10 {
            await Task.yield()
        }
    }

    private func enabledModels(
        in entity: Entity,
        ancestorsEnabled: Bool
    ) -> [ModelComponent] {
        let isEnabled = ancestorsEnabled && entity.isEnabled
        var result = [ModelComponent]()
        if isEnabled, let model = entity.components[ModelComponent.self] {
            result.append(model)
        }
        for child in entity.children {
            result.append(contentsOf: enabledModels(
                in: child,
                ancestorsEnabled: isEnabled
            ))
        }
        return result
    }
}

@MainActor
private final class ManualGameLoopScheduler: GameLoopScheduling {
    private var tickHandler: (@MainActor (TimeInterval) -> Void)?
    var isRunning: Bool { tickHandler != nil }

    func start(onTick: @escaping @MainActor (TimeInterval) -> Void) {
        tickHandler = onTick
    }

    func stop() {
        tickHandler = nil
    }

    func tick(_ elapsedTime: TimeInterval) {
        tickHandler?(elapsedTime)
    }
}

@MainActor
private final class SpatialActionRecorder {
    private(set) var pushedVolumeIDs = [String]()
    private(set) var openedWindowIDs = [String]()
    private(set) var dismissedWindowIDs = [String]()

    var actions: VisionSpatialActions {
        VisionSpatialActions(
            pushVolume: { [weak self] in self?.pushedVolumeIDs.append($0) },
            openWindow: { [weak self] in self?.openedWindowIDs.append($0) },
            dismissWindow: { [weak self] in self?.dismissedWindowIDs.append($0) }
        )
    }
}

@MainActor
private final class RecordingControllerInputSource: GameControllerInputSource {
    private var handler: (@MainActor @Sendable (GameControllerAction) -> Void)?

    func start(handler: @escaping @MainActor @Sendable (GameControllerAction) -> Void) {
        self.handler = handler
    }

    func stop() {
        handler = nil
    }

    func send(_ action: GameControllerAction) {
        handler?(action)
    }
}

@MainActor
private final class StubModelRepository: TabletopModelRepositoryProtocol {
    func canonicalCars() async throws -> TabletopCanonicalCars {
        let player = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.12, 0.07, 0.20)),
            materials: [SimpleMaterial(color: .red, isMetallic: false)]
        )
        let rival = ModelEntity(
            mesh: .generateBox(size: SIMD3<Float>(0.12, 0.07, 0.20)),
            materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
        )
        return TabletopCanonicalCars(player: player, rival: rival)
    }
}

@MainActor
private final class FailingModelRepository: TabletopModelRepositoryProtocol {
    func canonicalCars() async throws -> TabletopCanonicalCars {
        throw TabletopModelError.invalidBounds
    }
}

private final class VisionTestRandomSource: RandomSource {
    func nextInt(upperBound: Int) -> Int { 0 }
}

private final class VisionTestSoundPlayer: SoundEffectPlayer {
    func play(_ effect: SoundEffect, completion: (() -> Void)?) { completion?() }
    func stopAll(fadeDuration: TimeInterval) {}
    func setVolume(_ volume: Double) {}
}

private final class VisionTestLaneCuePlayer: LaneCuePlayer {
    func playTickCue(safeColumns: Set<CueColumn>, mode: AudioFeedbackMode) {}
    func playMoveCue(
        column: CueColumn,
        isSafe: Bool,
        mode: AudioFeedbackMode,
        style: LaneMoveCueStyle
    ) {}
    func playSpeedWarningCue() {}
    func setVolume(_ volume: Double) {}
    func stopAll(fadeDuration: TimeInterval) {}
}

@MainActor
private struct VisionTestSpeedWarningPlayer: SpeedIncreaseWarningFeedbackPlaying {
    func play(mode: SpeedWarningFeedbackMode) {}
}

@MainActor
private struct VisionTestAnnouncementPoster: AccessibilityAnnouncementPosting {
    func postAnnouncement(
        _ announcement: String,
        priority: AccessibilityAnnouncementPriority
    ) {}
}

private final class VisionTestLeaderboardService: LeaderboardService {
    func submitScore(_ score: Int, difficulty: GameDifficulty) {}
    func isAuthenticated() -> Bool { true }
    func fetchLocalPlayerBestScore(for difficulty: GameDifficulty) async -> Int? { nil }
}

private final class VisionTestHighestScoreStore: HighestScoreStore {
    func currentBest(for difficulty: GameDifficulty) -> Int { 0 }
    func updateIfHigher(_ score: Int, for difficulty: GameDifficulty) -> Bool { false }
    func syncFromRemote(bestScore: Int, for difficulty: GameDifficulty) {}
}

@MainActor
private final class GameOverFixtureEngine: GameEngineProtocol {
    private(set) var snapshot = GameOverFixtureEngine.makeSnapshot(
        phase: .ready,
        lives: 3,
        score: 0,
        pauseReasons: [.startup]
    )

    func handle(_ command: GameCommand) -> [GameEvent] {
        switch command {
        case .start:
            snapshot = Self.makeSnapshot(
                phase: .gameOver,
                lives: 0,
                score: 87,
                pauseReasons: []
            )
            return [.started, .gameOver(score: snapshot.score)]
        case .setPause(let reason, let isActive):
            var reasons = snapshot.activePauseReasons
            if isActive { reasons.insert(reason) } else { reasons.remove(reason) }
            snapshot = Self.makeSnapshot(
                phase: snapshot.phase,
                lives: snapshot.lives,
                score: snapshot.score,
                pauseReasons: reasons
            )
            return [.pauseChanged(reasons.isEmpty == false)]
        case .finish:
            snapshot = Self.makeSnapshot(
                phase: .finished,
                lives: snapshot.lives,
                score: snapshot.score,
                pauseReasons: []
            )
            return [.finished]
        case .setDifficulty, .tick, .move, .resolveCollision, .restart, .setTrafficMode:
            return []
        }
    }

    private static func makeSnapshot(
        phase: GamePhase,
        lives: Int,
        score: Int,
        pauseReasons: Set<GamePauseReason>
    ) -> GameSnapshot {
        var grid = Array(
            repeating: Array(repeating: GameGridOccupant.empty, count: 3),
            count: 5
        )
        grid[0][0] = .rival
        grid[2][2] = .rival
        grid[4][1] = phase == .gameOver ? .crash : .player
        return GameSnapshot(
            phase: phase,
            grid: grid,
            playerColumn: 1,
            score: score,
            lives: lives,
            level: 3,
            roadPhase: 2,
            safetyMarkerRows: [1, 3],
            difficulty: .rapid,
            activePauseReasons: pauseReasons
        )
    }
}

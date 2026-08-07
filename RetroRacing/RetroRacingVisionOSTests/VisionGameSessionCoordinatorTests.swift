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

    func testGivenActiveRunWhenSurfaceBecomesReadyThenSnapshotIsPreservedAndConfirmationIsRequired() async {
        let scheduler = ManualGameLoopScheduler()
        let recorder = SpatialActionRecorder()
        let session = makeSession(scheduler: scheduler)
        session.play()
        session.moveLeft()
        scheduler.tick(1.3)
        let snapshotBeforeEntry = session.snapshot

        let transitionID = await enterAwaitingConfirmation(
            session: session,
            recorder: recorder
        )

        XCTAssertNotNil(transitionID)
        XCTAssertEqual(session.presentation, .spatial)
        XCTAssertEqual(session.spatialState, .awaitingConfirmation)
        XCTAssertEqual(session.snapshot.grid, snapshotBeforeEntry.grid)
        XCTAssertEqual(session.snapshot.score, snapshotBeforeEntry.score)
        XCTAssertTrue(session.snapshot.activePauseReasons.contains(.spatialPlacement))
        XCTAssertFalse(session.snapshot.activePauseReasons.contains(.presentationTransition))
        XCTAssertEqual(recorder.dismissedWindowIDs, [VisionSceneID.classic])
    }

    func testGivenReadySurfaceWhenUserConfirmsThenOnlyPlacementPauseClears() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = await enterAwaitingConfirmation(session: session, recorder: recorder)

        session.confirmSpatialPlacement()

        XCTAssertEqual(session.spatialState, .active)
        XCTAssertFalse(session.snapshot.activePauseReasons.contains(.spatialPlacement))
        XCTAssertEqual(session.snapshot.phase, .running)
    }

    func testGivenUserPausedRaceWhenSpatialPlacementIsConfirmedThenUserPauseRemains() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        session.togglePause()
        _ = await enterAwaitingConfirmation(session: session, recorder: recorder)

        session.confirmSpatialPlacement()

        XCTAssertEqual(session.snapshot.activePauseReasons, [.user])
        XCTAssertTrue(session.isUserPaused)
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

    func testGivenSpatialEntryWhenCancelledThenClassicAndExactRunAreRestored() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        let snapshot = session.snapshot
        _ = session.beginSpatialPresentation(using: recorder.actions)

        session.cancelSpatialPresentation(using: recorder.actions)
        await settleTasks()

        XCTAssertEqual(session.spatialState, .inactive)
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(session.snapshot.grid, snapshot.grid)
        XCTAssertEqual(session.snapshot.score, snapshot.score)
        XCTAssertFalse(session.snapshot.activePauseReasons.contains(.spatialPlacement))
        XCTAssertTrue(recorder.openedWindowIDs.contains(VisionSceneID.classic))
    }

    func testGivenStaleAnchorCallbackWhenNewEntryIsSearchingThenCallbackIsIgnored() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = session.beginSpatialPresentation(using: recorder.actions)
        let staleID = session.currentSpatialTransitionID()
        session.cancelSpatialPresentation(using: recorder.actions)
        _ = session.beginSpatialPresentation(using: recorder.actions)
        await settleTasks()
        let currentID = session.currentSpatialTransitionID()

        if let staleID {
            session.spatialAnchorDidChange(
                isAnchored: true,
                transitionID: staleID,
                using: recorder.actions
            )
        }

        XCTAssertNotEqual(staleID, currentID)
        XCTAssertEqual(session.spatialState, .searchingSurface(showTroubleshooting: false))
        XCTAssertEqual(session.presentation, .classic)
    }

    func testGivenImmersiveOpenCancellationThenTypedFailureRestoresClassic() async {
        let recorder = SpatialActionRecorder(openResult: .userCancelled)
        let session = makeSession()
        session.play()

        _ = session.beginSpatialPresentation(using: recorder.actions)
        await settleTasks()

        XCTAssertEqual(session.spatialState, .failure(.immersiveOpenCancelled))
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertFalse(session.snapshot.activePauseReasons.contains(.presentationTransition))
        XCTAssertFalse(session.snapshot.activePauseReasons.contains(.spatialPlacement))
    }

    func testGivenImmersiveOpenErrorThenTypedFailureRestoresClassic() async {
        let recorder = SpatialActionRecorder(openResult: .failed)
        let session = makeSession()
        session.play()

        _ = session.beginSpatialPresentation(using: recorder.actions)
        await settleTasks()

        XCTAssertEqual(session.spatialState, .failure(.immersiveOpenFailed))
        XCTAssertEqual(session.presentation, .classic)
    }

    func testGivenModelPreflightFailureThenImmersiveSpaceDoesNotOpen() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession(modelRepository: FailingModelRepository())
        session.play()

        _ = session.beginSpatialPresentation(using: recorder.actions)
        await settleTasks()

        XCTAssertEqual(session.spatialState, .failure(.modelUnavailable))
        XCTAssertEqual(recorder.openImmersiveCount, 0)
    }

    func testGivenSurfaceSearchAfterGuidanceDelayThenTroubleshootingAppearsWithoutFailure() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession(delayScheduler: ImmediateDelayScheduler())
        session.play()

        _ = session.beginSpatialPresentation(using: recorder.actions)
        await settleTasks()

        XCTAssertEqual(session.spatialState, .searchingSurface(showTroubleshooting: true))
        XCTAssertNil(session.spatialFailure)
    }

    func testGivenSurfaceSearchWithPendingDelayThenThereIsNoForcedTimeout() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession(delayScheduler: LongDelayScheduler())
        session.play()

        _ = session.beginSpatialPresentation(using: recorder.actions)
        await settleTasks()

        XCTAssertEqual(session.spatialState, .searchingSurface(showTroubleshooting: false))
        XCTAssertNil(session.spatialFailure)
    }

    func testGivenActiveSpatialRaceWhenAnchorIsLostThenInputPausesAndClassicReopens() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        let transitionID = await activateSpatial(session: session, recorder: recorder)

        if let transitionID {
            session.spatialAnchorDidChange(
                isAnchored: false,
                transitionID: transitionID,
                using: recorder.actions
            )
        }

        XCTAssertEqual(session.spatialState, .recoveringSurface(showTroubleshooting: false))
        XCTAssertTrue(session.snapshot.activePauseReasons.contains(.spatialPlacement))
        XCTAssertFalse(session.isSpatialLaneInputEnabled)
        XCTAssertTrue(recorder.openedWindowIDs.contains(VisionSceneID.classic))
    }

    func testGivenLostAnchorWhenSurfaceIsReacquiredThenConfirmationIsRequiredAgain() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        let transitionID = await activateSpatial(session: session, recorder: recorder)
        guard let transitionID else {
            XCTFail("Expected a spatial transition")
            return
        }
        session.spatialAnchorDidChange(
            isAnchored: false,
            transitionID: transitionID,
            using: recorder.actions
        )

        session.spatialAnchorDidChange(
            isAnchored: true,
            transitionID: transitionID,
            using: recorder.actions
        )

        XCTAssertEqual(session.spatialState, .awaitingConfirmation)
        XCTAssertTrue(session.snapshot.activePauseReasons.contains(.spatialPlacement))
        XCTAssertFalse(session.isSpatialLaneInputEnabled)
    }

    func testGivenSystemDismissalWhenSpatialIsActiveThenClassicRestoresWithTypedFailure() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = await activateSpatial(session: session, recorder: recorder)
        let snapshot = session.snapshot

        session.spatialSceneDidDisappear(using: recorder.actions)

        XCTAssertEqual(session.spatialState, .failure(.systemDismissed))
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(session.snapshot.grid, snapshot.grid)
        XCTAssertTrue(recorder.openedWindowIDs.contains(VisionSceneID.classic))
    }

    func testGivenAppBackgroundingWhenSpatialIsActiveThenReturnWaitsForClassicReadiness() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = await activateSpatial(session: session, recorder: recorder)

        session.spatialDidEnterBackground(using: recorder.actions)
        let stateBeforeClassicReady = session.spatialState
        session.classicDidBecomeReady(using: recorder.actions)
        await settleTasks()

        XCTAssertEqual(stateBeforeClassicReady, .returning)
        XCTAssertEqual(session.spatialState, .inactive)
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(recorder.dismissImmersiveCount, 1)
    }

    func testGivenRepeatedSpatialSwitchingThenEveryRunUsesANewTokenAndPreservesSnapshot() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        let snapshot = session.snapshot

        let firstID = await activateSpatial(session: session, recorder: recorder)
        _ = session.beginReturnToClassic(using: recorder.actions)
        session.classicDidBecomeReady(using: recorder.actions)
        await settleTasks()
        let secondID = await activateSpatial(session: session, recorder: recorder)

        XCTAssertNotEqual(firstID, secondID)
        XCTAssertEqual(session.snapshot.grid, snapshot.grid)
        XCTAssertEqual(session.spatialState, .active)
    }

    func testGivenIncomingSharePlayWhenSpatialIsActiveThenClassicHandoffPrecedesMatchState() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = await activateSpatial(session: session, recorder: recorder)

        session.applySharePlayState(
            SharePlayUIState(
                state: .waitingForFriend,
                localRole: .guest,
                opponentDisplayName: "Alex"
            )
        )
        let didBeginReturn = session.beginReturnToClassic(using: recorder.actions)
        session.classicDidBecomeReady(using: recorder.actions)

        XCTAssertTrue(didBeginReturn)
        XCTAssertFalse(session.requiresClassicForSharePlay)
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertTrue(session.snapshot.activePauseReasons.contains(.sharePlay))
    }

    func testGivenSharePlayArrivesDuringPreflightWhenEntryCancelsThenSharePlayAppliesInClassic() async {
        let recorder = SpatialActionRecorder()
        let session = makeSession()
        session.play()
        _ = session.beginSpatialPresentation(using: recorder.actions)
        session.applySharePlayState(
            SharePlayUIState(
                state: .waitingForFriend,
                localRole: .host,
                opponentDisplayName: "Alex"
            )
        )

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
        session.classicDidBecomeReady(using: recorder.actions)

        XCTAssertEqual(session.screen, .gameOver)
        XCTAssertEqual(session.snapshot, gameOverSnapshot)
        XCTAssertEqual(session.presentation, .classic)
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

    func testGivenSystemImmersiveRouterWhenOpeningAndDismissingThenActionsAreUsed() async throws {
        let recorder = SpatialActionRecorder()
        let router = VisionImmersiveSpaceRouter(immersiveSpaceID: VisionSceneID.spatial)

        try await router.open(using: recorder.actions)
        await router.dismiss(using: recorder.actions)

        XCTAssertEqual(recorder.openedImmersiveIDs, [VisionSceneID.spatial])
        XCTAssertEqual(recorder.dismissImmersiveCount, 1)
    }

    func testGivenFixedTestAnchorProviderWhenCreatingAnchorThenItNeverUsesPlaneFallbackGeometry() {
        let provider = FixedVisionSurfaceAnchorProvider()

        let placement = provider.makeHorizontalSurfacePlacement(
            minimumBounds: SIMD2(0.55, 0.75)
        )

        XCTAssertEqual(placement.anchor.name, "test-fixed-surface-anchor")
        XCTAssertTrue(placement.anchor === placement.contentParent)
        XCTAssertTrue(placement.anchor.children.isEmpty)
    }

    #if targetEnvironment(simulator) && DEBUG
    func testGivenDebugSimulatorWhenCreatingSurfacePlacementThenContentUsesStableHeadOffset() {
        let provider = VisionSurfaceAnchorProviderFactory.makeForCurrentEnvironment()

        let placement = provider.makeHorizontalSurfacePlacement(
            minimumBounds: SIMD2(0.55, 0.75)
        )

        XCTAssertTrue(provider is VisionSimulatorSurfaceAnchorProvider)
        XCTAssertEqual(
            placement.contentParent.position,
            VisionSimulatorSurfaceAnchorProvider.contentPosition
        )
        XCTAssertTrue(placement.contentParent.parent === placement.anchor)
        XCTAssertEqual(placement.anchor.name, "retrorapid-simulator-preview-anchor")
    }
    #endif

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
        delayScheduler: (any VisionDelayScheduling)? = nil,
        immersiveSpaceRouter: (any VisionImmersiveSpaceRouting)? = nil,
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
            delayScheduler: delayScheduler ?? LongDelayScheduler(),
            immersiveSpaceRouter: immersiveSpaceRouter
                ?? VisionImmersiveSpaceRouter(immersiveSpaceID: VisionSceneID.spatial),
            modelRepository: modelRepository,
            troubleshootingDelay: .seconds(10)
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
            surfaceAnchorProvider: FixedVisionSurfaceAnchorProvider(),
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

    private func enterAwaitingConfirmation(
        session: VisionGameSessionCoordinator,
        recorder: SpatialActionRecorder
    ) async -> VisionSpatialTransitionID? {
        if session.spatialState == .inactive {
            XCTAssertTrue(session.beginSpatialPresentation(using: recorder.actions))
        }
        await settleTasks()
        let transitionID = session.currentSpatialTransitionID()
        if let transitionID {
            session.spatialAnchorDidChange(
                isAnchored: true,
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
        let transitionID = await enterAwaitingConfirmation(
            session: session,
            recorder: recorder
        )
        session.confirmSpatialPlacement()
        return transitionID
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
private final class LongDelayScheduler: VisionDelayScheduling {
    func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: .seconds(3_600))
    }
}

@MainActor
private final class ImmediateDelayScheduler: VisionDelayScheduling {
    func sleep(for duration: Duration) async throws {}
}

@MainActor
private final class SpatialActionRecorder {
    private let openResult: VisionImmersiveSpaceOpenResult
    private(set) var openedImmersiveIDs = [String]()
    private(set) var dismissImmersiveCount = 0
    private(set) var openedWindowIDs = [String]()
    private(set) var dismissedWindowIDs = [String]()

    init(openResult: VisionImmersiveSpaceOpenResult = .opened) {
        self.openResult = openResult
    }

    var openImmersiveCount: Int { openedImmersiveIDs.count }

    var actions: VisionSpatialActions {
        VisionSpatialActions(
            openImmersiveSpace: { [weak self] id in
                self?.openedImmersiveIDs.append(id)
                return self?.openResult ?? .failed
            },
            dismissImmersiveSpace: { [weak self] in
                self?.dismissImmersiveCount += 1
            },
            openWindow: { [weak self] in self?.openedWindowIDs.append($0) },
            dismissWindow: { [weak self] in self?.dismissedWindowIDs.append($0) }
        )
    }
}

@MainActor
private final class FixedVisionSurfaceAnchorProvider: VisionSurfaceAnchorProviding {
    func makeHorizontalSurfacePlacement(
        minimumBounds: SIMD2<Float>
    ) -> VisionSurfaceAnchorPlacement {
        let anchor = AnchorEntity(world: .zero)
        anchor.name = "test-fixed-surface-anchor"
        return VisionSurfaceAnchorPlacement(
            anchor: anchor,
            contentParent: anchor
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
        case .setDifficulty, .tick, .move, .resolveCollision, .restart, .finish,
             .setTrafficMode:
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

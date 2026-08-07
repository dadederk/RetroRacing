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

    func testGivenSixtyFourBitThemeWhenResolvingClassicSpritesThenSharedBundleAssetsExist() {
        let theme = SixtyFourBitTheme()
        let bundle = VisionThemeSpriteAssets.bundle

        XCTAssertEqual(bundle.bundleURL, Bundle(for: GameScene.self).bundleURL)
        XCTAssertNotNil(UIImage(named: "playersCar-64Bit", in: bundle, compatibleWith: nil))
        XCTAssertNotNil(UIImage(named: "rivalsCar-64Bit", in: bundle, compatibleWith: nil))
        XCTAssertEqual(VisionThemeSpriteAssets.crashAssetName(for: theme), "crash-64Bit")
    }

    func testGivenFreshSessionWhenPlayIsRequestedThenEngineStartsAndSchedulerRuns() {
        // Given
        let scheduler = ManualGameLoopScheduler()
        let session = makeSession(scheduler: scheduler)
        let initialSnapshot = session.snapshot

        // When
        session.play()

        // Then
        XCTAssertEqual(initialSnapshot.phase, .ready)
        XCTAssertEqual(session.snapshot.phase, .running)
        XCTAssertEqual(session.screen, .playing)
        XCTAssertTrue(scheduler.isRunning)
    }

    func testGivenFreshSessionWhenPlayAndMovementOccurThenVisionGameplayUsesSharedAudio() {
        // Given
        let scheduler = ManualGameLoopScheduler()
        let soundPlayer = VisionTestSoundPlayer()
        let laneCuePlayer = VisionTestLaneCuePlayer()
        let session = makeSession(
            scheduler: scheduler,
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer
        )

        // When
        session.play()
        session.moveLeft()
        scheduler.tick(1.3)

        // Then
        XCTAssertTrue(soundPlayer.playedEffects.contains(.start))
        XCTAssertEqual(laneCuePlayer.moveCount, 1)
        XCTAssertGreaterThanOrEqual(laneCuePlayer.tickCount, 1)
    }

    func testGivenClassicPresentationWhenSharePlayRoundStartsThenSeededRoundAndGoCueStart() {
        // Given
        let soundPlayer = VisionTestSoundPlayer()
        let session = makeSession(soundPlayer: soundPlayer)
        let settings = SharePlayRoundSettings(difficulty: .fast, trafficSeed: 90210)

        // When
        session.applySharePlayState(
            SharePlayUIState(
                state: .inRound(
                    settings: settings,
                    localScore: 0,
                    remoteScore: 0,
                    remoteLives: 3
                ),
                localRole: .host,
                opponentDisplayName: "Alex"
            )
        )

        // Then
        XCTAssertEqual(session.screen, .playing)
        XCTAssertEqual(session.snapshot.phase, .running)
        XCTAssertEqual(session.snapshot.difficulty, .fast)
        XCTAssertTrue(soundPlayer.playedEffects.contains(.sharePlayCountdownGo))
        XCTAssertFalse(session.snapshot.activePauseReasons.contains(.sharePlay))
    }

    func testGivenTabletopPresentationWhenSharePlayArrivesThenClassicHandoffIsRequired() {
        // Given
        let session = makeSession()
        let recorder = WindowActionRecorder()
        moveToTabletop(session: session, actions: recorder.actions)

        // When
        session.applySharePlayState(
            SharePlayUIState(
                state: .waitingForFriend,
                localRole: .guest,
                opponentDisplayName: "Alex"
            )
        )
        let didBegin = session.beginPresentationTransition(
            to: .classic,
            using: recorder.actions
        )
        if let transitionID = session.currentTransitionID(for: .classic) {
            session.presentationDidBecomeReady(
                .classic,
                transitionID: transitionID,
                using: recorder.actions
            )
        }

        // Then
        XCTAssertTrue(didBegin)
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertFalse(session.requiresClassicForSharePlay)
        XCTAssertTrue(session.snapshot.activePauseReasons.contains(.sharePlay))
    }

    func testGivenSharePlayCountdownWhenTimelineRepeatsASecondThenCuePlaysOnlyOnce() {
        // Given
        let soundPlayer = VisionTestSoundPlayer()
        let session = makeSession(soundPlayer: soundPlayer)

        // When
        session.playSharePlayCountdownCue(displayValue: 3)
        session.playSharePlayCountdownCue(displayValue: 3)
        session.playSharePlayCountdownCue(displayValue: 2)
        session.playSharePlayCountdownCue(displayValue: 1)

        // Then
        XCTAssertEqual(
            soundPlayer.playedEffects,
            [.sharePlayCountdownLow, .sharePlayCountdownMid, .sharePlayCountdownHigh]
        )
    }

    func testGivenSettingsDifficultyWhenPlayIsRequestedThenEngineUsesCurrentPreference() {
        // Given
        var difficulty = GameDifficulty.cruise
        let session = makeSession(difficultyProvider: { difficulty })

        // When
        session.play()
        let firstDifficulty = session.snapshot.difficulty
        session.finish()
        difficulty = .fast
        session.play()

        // Then
        XCTAssertEqual(firstDifficulty, .cruise)
        XCTAssertEqual(session.snapshot.difficulty, .fast)
    }

    func testGivenSettingsOverlayAndUserPauseWhenSettingsClosesThenUserPauseRemains() {
        // Given
        let session = makeSession()
        session.play()

        // When
        session.setOverlayPresented(true)
        session.togglePause()
        session.setOverlayPresented(false)

        // Then
        XCTAssertEqual(session.snapshot.activePauseReasons, [.user])
    }

    func testGivenMenuScreenWhenMovementIsRequestedThenLaneDoesNotChange() {
        // Given
        let session = makeSession()
        let initialColumn = session.snapshot.playerColumn

        // When
        session.moveLeft()
        session.moveRight()
        session.selectLane(0)

        // Then
        XCTAssertEqual(session.snapshot.playerColumn, initialColumn)
    }

    func testGivenActiveRunWhenTabletopBecomesReadyThenGameplayStateIsPreserved() {
        // Given
        let scheduler = ManualGameLoopScheduler()
        let session = makeSession(scheduler: scheduler)
        let recorder = WindowActionRecorder()
        let actions = recorder.actions
        session.play()
        session.moveLeft()
        scheduler.tick(1.3)
        let beforeTransition = session.snapshot

        // When
        XCTAssertTrue(session.beginPresentationTransition(to: .tabletop, using: actions))
        let transitionID = session.currentTransitionID(for: .tabletop)
        XCTAssertNotNil(transitionID)
        if let transitionID {
            session.presentationDidBecomeReady(.tabletop, transitionID: transitionID, using: actions)
        }

        // Then
        XCTAssertEqual(session.presentation, .tabletop)
        XCTAssertEqual(session.snapshot.score, beforeTransition.score)
        XCTAssertEqual(session.snapshot.grid, beforeTransition.grid)
        XCTAssertEqual(session.snapshot.playerColumn, beforeTransition.playerColumn)
        XCTAssertFalse(session.snapshot.activePauseReasons.contains(.presentationTransition))
    }

    func testGivenTransitionInProgressWhenRequestingAgainThenDuplicateIsRejected() {
        // Given
        let session = makeSession()
        let recorder = WindowActionRecorder()
        let actions = recorder.actions
        session.play()

        // When
        let firstRequest = session.beginPresentationTransition(to: .tabletop, using: actions)
        let secondRequest = session.beginPresentationTransition(to: .tabletop, using: actions)

        // Then
        XCTAssertTrue(firstRequest)
        XCTAssertFalse(secondRequest)
    }

    func testGivenUserPausedRaceWhenHandoffCompletesThenUserPauseRemains() {
        // Given
        let session = makeSession()
        let recorder = WindowActionRecorder()
        let actions = recorder.actions
        session.play()
        session.togglePause()

        // When
        session.beginPresentationTransition(to: .tabletop, using: actions)
        let transitionID = session.currentTransitionID(for: .tabletop)
        if let transitionID {
            session.presentationDidBecomeReady(.tabletop, transitionID: transitionID, using: actions)
        }

        // Then
        XCTAssertTrue(session.isUserPaused)
        XCTAssertEqual(session.snapshot.activePauseReasons, [.user])
    }

    func testGivenStaleAcknowledgementWhenNewTransitionIsActiveThenItIsIgnored() {
        // Given
        let session = makeSession()
        let recorder = WindowActionRecorder()
        let actions = recorder.actions
        session.play()
        session.beginPresentationTransition(to: .tabletop, using: actions)
        let staleID = session.currentTransitionID(for: .tabletop)
        if let staleID {
            session.destinationDidFail(transitionID: staleID, failure: .modelUnavailable)
        }
        session.beginPresentationTransition(to: .tabletop, using: actions)
        let currentID = session.currentTransitionID(for: .tabletop)

        // When
        if let staleID {
            session.presentationDidBecomeReady(.tabletop, transitionID: staleID, using: actions)
        }

        // Then
        XCTAssertEqual(session.currentTransitionID(for: .tabletop), currentID)
        XCTAssertEqual(session.presentation, .classic)
    }

    func testGivenImmediateTimeoutWhenDestinationNeverAcknowledgesThenClassicIsRestored() async {
        // Given
        let recorder = WindowActionRecorder()
        let session = makeSession(delayScheduler: ImmediateDelayScheduler())
        session.play()

        // When
        session.beginPresentationTransition(to: .tabletop, using: recorder.actions)
        await settleTasks()

        // Then
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(session.presentationTransition, .idle)
        XCTAssertEqual(session.transitionFailure, .timedOut)
        XCTAssertFalse(session.snapshot.activePauseReasons.contains(.presentationTransition))
        XCTAssertTrue(recorder.dismissedSceneIDs.contains(VisionSceneID.tabletop))
    }

    func testGivenRoutingFailureWhenOpeningDestinationThenSourceIsRecovered() async {
        // Given
        let router = FailingWindowRouter()
        let session = makeSession(windowRouter: router)
        let recorder = WindowActionRecorder()
        session.play()

        // When
        session.beginPresentationTransition(to: .tabletop, using: recorder.actions)
        await settleTasks()

        // Then
        XCTAssertEqual(session.transitionFailure, .routingFailed)
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(router.cancelCount, 1)
    }

    func testGivenTabletopSystemCloseWhenNoTransitionThenClassicIsRestored() {
        // Given
        let session = makeSession()
        let recorder = WindowActionRecorder()
        moveToTabletop(session: session, actions: recorder.actions)

        // When
        session.tabletopDidDisappear(using: recorder.actions)

        // Then
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(session.presentationTransition, .idle)
    }

    func testGivenTabletopGameOverWhenReturningToClassicThenSnapshotIsPreserved() {
        // Given
        let engine = GameOverFixtureEngine()
        let recorder = WindowActionRecorder()
        let session = makeSession(engine: engine)
        session.play()
        XCTAssertEqual(session.screen, .gameOver)
        XCTAssertTrue(session.beginPresentationTransition(to: .tabletop, using: recorder.actions))
        if let transitionID = session.currentTransitionID(for: .tabletop) {
            session.presentationDidBecomeReady(
                .tabletop,
                transitionID: transitionID,
                using: recorder.actions
            )
        }
        let gameOverSnapshot = session.snapshot

        // When
        let didBeginReturn = session.beginPresentationTransition(
            to: .classic,
            using: recorder.actions
        )
        if let transitionID = session.currentTransitionID(for: .classic) {
            session.presentationDidBecomeReady(
                .classic,
                transitionID: transitionID,
                using: recorder.actions
            )
        }

        // Then
        XCTAssertTrue(didBeginReturn)
        XCTAssertEqual(session.presentation, .classic)
        XCTAssertEqual(session.screen, .gameOver)
        XCTAssertEqual(session.snapshot, gameOverSnapshot)
    }

    func testGivenBackgroundedRaceWhenSchedulerTicksThenElapsedTimeIsNotReplayed() {
        // Given
        let scheduler = ManualGameLoopScheduler()
        let session = makeSession(scheduler: scheduler)
        session.play()
        scheduler.tick(0.2)
        let beforeBackground = session.snapshot

        // When
        session.setPresentationActive(.classic, isActive: false)
        scheduler.tick(60)
        let whileInactive = session.snapshot
        session.setPresentationActive(.classic, isActive: true)

        // Then
        XCTAssertEqual(whileInactive.grid, beforeBackground.grid)
        XCTAssertEqual(whileInactive.score, beforeBackground.score)
        XCTAssertFalse(session.snapshot.activePauseReasons.contains(.appInactive))
        XCTAssertTrue(scheduler.isRunning)
    }

    func testGivenControllerActionsWhenRaceIsActiveThenTheyUseSharedCommands() {
        // Given
        let controller = RecordingControllerInputSource()
        let session = makeSession(controllerInputSource: controller)
        session.play()

        // When
        controller.send(.moveLeft)
        controller.send(.pauseResume)

        // Then
        XCTAssertEqual(session.snapshot.playerColumn, 0)
        XCTAssertTrue(session.isUserPaused)
    }

    func testGivenLaneSelectionsWhenTargetingCurrentOrAdjacentLaneThenOnlyAdjacentMoves() {
        // Given
        let session = makeSession()
        session.play()

        // When
        session.selectLane(1)
        let afterCurrentLane = session.snapshot.playerColumn
        session.selectLane(0)

        // Then
        XCTAssertEqual(afterCurrentLane, 1)
        XCTAssertEqual(session.snapshot.playerColumn, 0)
    }

    func testGivenClassicBoardTapLocationsWhenResolvingLanesThenBoundsMapToThreeLanes() {
        // Given
        let locations: [CGFloat] = [-20, 49, 50, 149, 299, 320]

        // When
        let lanes = locations.compactMap {
            VisionGameInteractionPolicy.lane(at: $0, width: 300, laneCount: 3)
        }

        // Then
        XCTAssertEqual(lanes, [0, 0, 0, 1, 2, 2])
        XCTAssertNil(VisionGameInteractionPolicy.lane(at: 10, width: 0, laneCount: 3))
    }

    func testGivenDirectTouchPreferenceWhenEvaluatingSurfacesThenOnlyRaceBoardsAreEligible() {
        // Given
        let surfaces = VisionDirectTouchSurface.allCases

        // When
        let enabledSurfaces = surfaces.filter {
            VisionGameInteractionPolicy.isDirectTouchEnabled(on: $0, userEnabled: true)
        }
        let disabledSurfaces = surfaces.filter {
            VisionGameInteractionPolicy.isDirectTouchEnabled(on: $0, userEnabled: false)
        }

        // Then
        XCTAssertEqual(enabledSurfaces, [.classicBoard, .tabletopRoad])
        XCTAssertTrue(disabledSurfaces.isEmpty)
    }

    func testGivenPushRouterWhenMovingForwardAndBackThenPushLifecycleActionsAreUsed() async throws {
        // Given
        let router = VisionWindowRouter(strategy: .push)
        let recorder = WindowActionRecorder()
        let forward = request(id: 1, source: .classic, destination: .tabletop)
        let back = request(id: 2, source: .tabletop, destination: .classic)

        // When
        try await router.present(forward, using: recorder.actions)
        try await router.present(back, using: recorder.actions)

        // Then
        XCTAssertEqual(recorder.pushedSceneIDs, [VisionSceneID.tabletop])
        XCTAssertEqual(recorder.dismissedSceneIDs, [VisionSceneID.tabletop])
    }

    func testGivenExplicitRouterWhenDestinationAcknowledgesThenSourceDismissesAfterOpen() async throws {
        // Given
        let router = VisionWindowRouter(strategy: .explicit)
        let recorder = WindowActionRecorder()
        let transition = request(id: 1, source: .classic, destination: .tabletop)

        // When
        try await router.present(transition, using: recorder.actions)
        let dismissedBeforeReady = recorder.dismissedSceneIDs
        router.complete(transition, using: recorder.actions)

        // Then
        XCTAssertEqual(recorder.openedSceneIDs, [VisionSceneID.tabletop])
        XCTAssertTrue(dismissedBeforeReady.isEmpty)
        XCTAssertEqual(recorder.dismissedSceneIDs, [VisionSceneID.classic])
    }

    func testGivenPackagedModelWhenLoadingTwiceThenRepositoryLoadsOnlyOnce() async throws {
        // Given
        let repository = TabletopModelRepository(
            playerResourceName: "player-car-64bit",
            rivalResourceName: "rival-car-64bit",
            bundle: .main
        )

        // When
        let first = try await repository.canonicalCars()
        let second = try await repository.canonicalCars()

        // Then
        XCTAssertTrue(first.player === second.player)
        XCTAssertTrue(first.rival === second.rival)
        XCTAssertFalse(first.player === first.rival)
        XCTAssertEqual(repository.loadCount, 2)
    }

    func testGivenInvalidModelResourceWhenLoadingThenTypedFailureIsThrown() async {
        // Given
        let repository = TabletopModelRepository(
            playerResourceName: "missing-player-car",
            rivalResourceName: "missing-rival-car",
            bundle: .main
        )

        // When / Then
        do {
            _ = try await repository.canonicalCars()
            XCTFail("Expected the invalid resource to fail")
        } catch let error as TabletopModelError {
            XCTAssertEqual(error, .resourceUnavailable)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGivenCanonicalModelWhenBuildingTabletopThenFixedPoolAndSemanticLanesExist() async throws {
        // Given
        let engine = GameEngine(randomSource: VisionTestRandomSource(), difficulty: .rapid)
        engine.handle(.start)
        let repository = TabletopModelRepository(
            playerResourceName: "player-car-64bit",
            rivalResourceName: "rival-car-64bit",
            bundle: .main
        )

        // When
        let scene = try await TabletopSceneFactory(modelRepository: repository)
            .makeScene(snapshot: engine.snapshot)

        // Then
        XCTAssertEqual(scene.rivals.count, TabletopScene.rivalCount)
        XCTAssertEqual(scene.laneTargets.count, 3)
        XCTAssertEqual(scene.laneTargets.compactMap(TabletopScene.lane(for:)), [0, 1, 2])
        for target in scene.laneTargets {
            XCTAssertNotNil(target.components[CollisionComponent.self])
            XCTAssertNotNil(target.components[InputTargetComponent.self])
            XCTAssertNotNil(target.components[HoverEffectComponent.self])
            XCTAssertNotNil(target.components[AccessibilityComponent.self])
        }
    }

    func testGivenCanonicalModelWhenCreatingRivalThenRivalIdentityIsApplied() async throws {
        // Given
        let repository = TabletopModelRepository(
            playerResourceName: "player-car-64bit",
            rivalResourceName: "rival-car-64bit",
            bundle: .main
        )
        let canonical = try await repository.canonicalCars()

        // When
        let scene = TabletopScene(
            canonicalPlayerCar: canonical.player,
            canonicalRivalCar: canonical.rival,
            snapshot: GameEngine(randomSource: VisionTestRandomSource(), difficulty: .rapid).snapshot
        )
        let playerMark = scene.player.findEntity(named: "Ivory_HelmetXLeft")
        let rivalMark = scene.rivals.first?.findEntity(named: "Ivory_HelmetXLeft")
        let playerLightStack = scene.player.findEntity(named: "Amber_RivalTailLightStackLeft")
        let rivalLightStack = scene.rivals.first?.findEntity(named: "Amber_RivalTailLightStackLeft")
        let playerSingleLight = scene.player.findEntity(named: "Amber_TailLightLeft")
        let rivalSingleLight = scene.rivals.first?.findEntity(named: "Amber_TailLightLeft")

        // Then
        XCTAssertNotNil(playerMark)
        XCTAssertNil(rivalMark)
        XCTAssertNil(playerLightStack)
        XCTAssertNotNil(rivalLightStack)
        XCTAssertNotNil(playerSingleLight)
        XCTAssertNil(rivalSingleLight)
        for exhaustIndex in 1...4 {
            XCTAssertEqual(
                scene.rivals.first?.findEntity(named: "Steel_Exhaust\(exhaustIndex)")?.isEnabled,
                true
            )
        }
    }

    func testGivenAccessibilityVisualPreferencesWhenBuildingTabletopThenStyleIsRetained() async throws {
        // Given
        let repository = TabletopModelRepository(
            playerResourceName: "player-car-64bit",
            rivalResourceName: "rival-car-64bit",
            bundle: .main
        )
        let style = TabletopSceneVisualStyle(
            increasedContrast: true,
            differentiateWithoutColor: true,
            reduceMotion: true
        )

        // When
        let scene = try await TabletopSceneFactory(modelRepository: repository).makeScene(
            snapshot: GameEngine(
                randomSource: VisionTestRandomSource(),
                difficulty: .rapid
            ).snapshot,
            visualStyle: style
        )

        // Then
        XCTAssertEqual(scene.visualStyle, style)
        XCTAssertNotNil(scene.root.findEntity(named: "tabletop-road"))
        XCTAssertNotNil(scene.root.findEntity(named: "tabletop-safety-marker-0"))
    }

    private func makeSession(
        engine: (any GameEngineProtocol)? = nil,
        scheduler: ManualGameLoopScheduler? = nil,
        delayScheduler: (any VisionDelayScheduling)? = nil,
        windowRouter: (any VisionWindowRouting)? = nil,
        controllerInputSource: (any GameControllerInputSource)? = nil,
        difficultyProvider: @escaping @MainActor () -> GameDifficulty = { .rapid },
        soundPlayer: VisionTestSoundPlayer = VisionTestSoundPlayer(),
        laneCuePlayer: VisionTestLaneCuePlayer = VisionTestLaneCuePlayer(),
        leaderboardService: VisionTestLeaderboardService = VisionTestLeaderboardService(),
        highestScoreStore: VisionTestHighestScoreStore = VisionTestHighestScoreStore()
    ) -> VisionGameSessionCoordinator {
        let scheduler = scheduler ?? ManualGameLoopScheduler()
        let delayScheduler = delayScheduler ?? LongDelayScheduler()
        let windowRouter = windowRouter ?? VisionWindowRouter(strategy: .push)
        let controllerInputSource = controllerInputSource ?? RecordingControllerInputSource()
        let audioFeedbackCoordinator = GameplayAudioFeedbackCoordinator(
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: nil,
            speedWarningPlayer: VisionTestSpeedWarningPlayer(),
            preferences: GameplayAudioFeedbackPreferences(
                volume: { 0.8 },
                mode: { .retro },
                laneMoveStyle: { .laneConfirmation },
                speedWarningMode: { .none }
            )
        )
        let session = VisionGameSessionCoordinator(
            engine: engine ?? GameEngine(
                randomSource: VisionTestRandomSource(),
                difficulty: .rapid,
                trafficMode: .seeded(64)
            ),
            scheduler: scheduler,
            delayScheduler: delayScheduler,
            windowRouter: windowRouter,
            tabletopModelRepository: StubModelRepository(),
            controllerInputSource: controllerInputSource,
            difficultyProvider: difficultyProvider,
            sharePlayMatchService: NoOpSharePlayMatchService(),
            audioFeedbackCoordinator: audioFeedbackCoordinator,
            leaderboardService: leaderboardService,
            highestScoreStore: highestScoreStore,
            announcementPoster: VisionTestAnnouncementPoster()
        )
        session.setPresentationActive(.classic, isActive: true)
        return session
    }

    private func moveToTabletop(
        session: VisionGameSessionCoordinator,
        actions: VisionWindowActions
    ) {
        session.play()
        session.beginPresentationTransition(to: .tabletop, using: actions)
        guard let transitionID = session.currentTransitionID(for: .tabletop) else { return }
        session.presentationDidBecomeReady(.tabletop, transitionID: transitionID, using: actions)
    }

    private func request(
        id: UInt64,
        source: VisionGamePresentation,
        destination: VisionGamePresentation
    ) -> VisionPresentationRequest {
        VisionPresentationRequest(
            id: VisionPresentationTransitionID(rawValue: id),
            source: source,
            destination: destination
        )
    }

    private func settleTasks() async {
        for _ in 0..<4 {
            await Task.yield()
        }
    }
}

@MainActor
private final class ManualGameLoopScheduler: GameLoopScheduling {
    private var tickHandler: (@MainActor (TimeInterval) -> Void)?
    private(set) var startCount = 0
    private(set) var stopCount = 0
    var isRunning: Bool { tickHandler != nil }

    func start(onTick: @escaping @MainActor (TimeInterval) -> Void) {
        startCount += 1
        tickHandler = onTick
    }

    func stop() {
        stopCount += 1
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
private final class WindowActionRecorder {
    private(set) var pushedSceneIDs = [String]()
    private(set) var openedSceneIDs = [String]()
    private(set) var dismissedSceneIDs = [String]()

    var actions: VisionWindowActions {
        VisionWindowActions(
            push: { [weak self] in self?.pushedSceneIDs.append($0) },
            open: { [weak self] in self?.openedSceneIDs.append($0) },
            dismiss: { [weak self] in self?.dismissedSceneIDs.append($0) }
        )
    }
}

@MainActor
private final class FailingWindowRouter: VisionWindowRouting {
    enum Failure: Error { case unavailable }

    let strategy = VisionWindowRoutingStrategy.push
    private(set) var cancelCount = 0

    func present(
        _ request: VisionPresentationRequest,
        using actions: VisionWindowActions
    ) async throws {
        throw Failure.unavailable
    }

    func complete(_ request: VisionPresentationRequest, using actions: VisionWindowActions) {}

    func cancel(_ request: VisionPresentationRequest, using actions: VisionWindowActions) {
        cancelCount += 1
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
        TabletopCanonicalCars(player: Entity(), rival: Entity())
    }
}

private final class VisionTestRandomSource: RandomSource {
    func nextInt(upperBound: Int) -> Int { 0 }
}

private final class VisionTestSoundPlayer: SoundEffectPlayer {
    private(set) var playedEffects = [SoundEffect]()

    func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        playedEffects.append(effect)
        completion?()
    }

    func stopAll(fadeDuration: TimeInterval) {}
    func setVolume(_ volume: Double) {}
}

private final class VisionTestLaneCuePlayer: LaneCuePlayer {
    private(set) var tickCount = 0
    private(set) var moveCount = 0

    func playTickCue(safeColumns: Set<CueColumn>, mode: AudioFeedbackMode) {
        tickCount += 1
    }

    func playMoveCue(
        column: CueColumn,
        isSafe: Bool,
        mode: AudioFeedbackMode,
        style: LaneMoveCueStyle
    ) {
        moveCount += 1
    }

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
    private(set) var submissions = [(score: Int, difficulty: GameDifficulty)]()

    func submitScore(_ score: Int, difficulty: GameDifficulty) {
        submissions.append((score, difficulty))
    }

    func isAuthenticated() -> Bool { true }
    func fetchLocalPlayerBestScore(for difficulty: GameDifficulty) async -> Int? { nil }
}

private final class VisionTestHighestScoreStore: HighestScoreStore {
    private var scores = [String: Int]()

    func currentBest(for difficulty: GameDifficulty) -> Int {
        scores[difficulty.rawValue, default: 0]
    }

    func updateIfHigher(_ score: Int, for difficulty: GameDifficulty) -> Bool {
        guard score > currentBest(for: difficulty) else { return false }
        scores[difficulty.rawValue] = score
        return true
    }

    func syncFromRemote(bestScore: Int, for difficulty: GameDifficulty) {
        _ = updateIfHigher(bestScore, for: difficulty)
    }
}

@MainActor
private final class GameOverFixtureEngine: GameEngineProtocol {
    private(set) var snapshot: GameSnapshot

    init() {
        snapshot = GameOverFixtureEngine.makeSnapshot(
            phase: .ready,
            lives: 3,
            score: 0,
            pauseReasons: [.startup]
        )
    }

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
            if isActive {
                reasons.insert(reason)
            } else {
                reasons.remove(reason)
            }
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

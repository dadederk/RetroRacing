//
//  RetroRacingVisionOSApp.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 01/02/2026.
//

import RetroRacingShared
import SwiftUI

enum VisionSceneID {
    static let classic = "classic-game"
    static let tabletop = "tabletop-game"
}

@main
struct RetroRacingVisionOSApp: App {
    private let dependencies: VisionAppDependencies
    private let sharePlayObservationTask: Task<Void, Never>
    @State private var session: VisionGameSessionCoordinator

    init() {
        let dependencies = VisionAppDependencies()
        let userDefaults = InfrastructureDefaults.userDefaults
        let engine = GameEngine(
            randomSource: SystemRandomSource(),
            difficulty: .systemDefault
        )
        let scheduler = TaskGameLoopScheduler(frameDuration: .milliseconds(16))
        let delayScheduler = TaskVisionDelayScheduler()
        let windowRouter = VisionWindowRouter(strategy: .push)
        let modelRepository = TabletopModelRepository(
            playerResourceName: "player-car-64bit",
            rivalResourceName: "rival-car-64bit",
            bundle: .main
        )
        let controllerInputSource: any GameControllerInputSource = if BuildConfiguration.isRunningTests {
            NoOpGameControllerInputSource()
        } else {
            SystemGameControllerInputSource(
                platformConfig: .standard,
                userDefaults: userDefaults
            )
        }
        let session = VisionGameSessionCoordinator(
            engine: engine,
            scheduler: scheduler,
            delayScheduler: delayScheduler,
            windowRouter: windowRouter,
            tabletopModelRepository: modelRepository,
            controllerInputSource: controllerInputSource,
            difficultyProvider: {
                GameDifficulty.currentSelection(from: userDefaults)
            },
            sharePlayMatchService: dependencies.sharePlayMatchService,
            audioFeedbackCoordinator: dependencies.gameplayAudioFeedbackCoordinator,
            leaderboardService: dependencies.gameCenterService,
            highestScoreStore: dependencies.highestScoreStore,
            announcementPoster: AccessibilityAnnouncementPoster()
        )
        _session = State(initialValue: session)
        sharePlayObservationTask = Task { @MainActor in
            await session.observeSharePlaySessions()
        }
        self.dependencies = dependencies
    }

    var body: some Scene {
        Window(GameLocalizedStrings.string("gameName"), id: VisionSceneID.classic) {
            ContentView(dependencies: dependencies)
                .environment(session)
                .environment(dependencies.themeManager)
                .environment(dependencies.storeKitService)
                .fontPreferenceStore(dependencies.fontPreferenceStore)
                .task {
                    await dependencies.storeKitService.loadProducts()
                }
        }
        .defaultSize(width: 980, height: 900)

        Window(GameLocalizedStrings.string("vision_tabletop_title"), id: VisionSceneID.tabletop) {
            TabletopGameView()
                .environment(session)
                .environment(dependencies.themeManager)
                .fontPreferenceStore(dependencies.fontPreferenceStore)
        }
        .windowStyle(.volumetric)
        .defaultSize(
            width: CGFloat(TabletopBoardLayout.standard.volumeSize.x),
            height: CGFloat(TabletopBoardLayout.standard.volumeSize.y),
            depth: CGFloat(TabletopBoardLayout.standard.volumeSize.z),
            in: .meters
        )
        .defaultLaunchBehavior(.suppressed)
    }
}

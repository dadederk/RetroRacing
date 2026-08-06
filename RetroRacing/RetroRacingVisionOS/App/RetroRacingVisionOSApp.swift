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
    @State private var session: VisionGameSessionCoordinator
    @State private var themeManager: ThemeManager

    init() {
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
        _session = State(initialValue: VisionGameSessionCoordinator(
            engine: engine,
            scheduler: scheduler,
            delayScheduler: delayScheduler,
            windowRouter: windowRouter,
            tabletopModelRepository: modelRepository,
            controllerInputSource: controllerInputSource
        ))
        _themeManager = State(initialValue: ThemeManager(
            configuration: .configuration(
                for: .visionOS,
                experimentalThemes: DebugGameplayStorageKeys.experimentalThemeConfiguration(
                    userDefaults: userDefaults,
                    debugFeaturesAllowed: BuildConfiguration.shouldShowDebugFeatures,
                    platform: .visionOS
                )
            ),
            userDefaults: userDefaults,
            hasPremiumAccess: false
        ))
    }

    var body: some Scene {
        Window(GameLocalizedStrings.string("gameName"), id: VisionSceneID.classic) {
            ContentView()
                .environment(session)
                .environment(themeManager)
        }
        .defaultSize(width: 980, height: 900)

        Window(GameLocalizedStrings.string("vision_tabletop_title"), id: VisionSceneID.tabletop) {
            TabletopGameView()
                .environment(session)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.82, height: 0.58, depth: 1.12, in: .meters)
        .defaultLaunchBehavior(.suppressed)
    }
}

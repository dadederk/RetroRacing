//
//  WatchScreenshotCaptureRootView.swift
//  RetroRacingWatchOS
//
//  Created by Dani Devesa on 24/07/2026.
//

import SwiftUI
import RetroRacingShared

struct WatchScreenshotCaptureDependencies {
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    let highestScoreStore: HighestScoreStore
    let achievementProgressService: AchievementProgressService
    let leaderboardService: LeaderboardService
    let watchBestScoreRelaySender: WatchBestScoreRelaySender
}

struct WatchScreenshotCaptureRootView: View {
    let configuration: WatchScreenshotCaptureConfiguration
    let dependencies: WatchScreenshotCaptureDependencies

    @State private var isLayoutReady = false
    @State private var isGameplayReady = false
    @State private var isSheetReady = false
    @State private var isSettingsSheetPresented = false

    var body: some View {
        layoutReadyContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .fontPreferenceStore(dependencies.fontPreferenceStore)
            .screenshotCaptureLocaleEnvironment()
            .screenshotCaptureColorScheme()
            .transaction { transaction in
                transaction.disablesAnimations = true
            }
            .onAppear {
                ScreenshotCaptureReadinessSignal.captureRootAppeared(
                    stagingDirectory: configuration.stagingDirectory,
                    slideIndex: configuration.slideIndex
                )
                if configuration.fixture.presentsSettingsSheet {
                    isSettingsSheetPresented = true
                }
            }
            .onChange(of: isLayoutReady) { _, isReady in
                guard isReady else { return }
                ScreenshotCaptureReadinessSignal.markReady(
                    stagingDirectory: configuration.stagingDirectory,
                    slideIndex: configuration.slideIndex
                )
            }
            .overlay(alignment: .topLeading) {
                if isLayoutReady {
                    ScreenshotCaptureReadinessMarker(identifier: configuration.readinessIdentifier)
                }
            }
            .sheet(isPresented: $isSettingsSheetPresented) {
                settingsView
            }
    }

    @ViewBuilder
    private var layoutReadyContent: some View {
        if isLayoutReady {
            captureContent
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(configuration.readinessIdentifier)
        } else {
            captureContent
        }
    }

    @ViewBuilder
    private var captureContent: some View {
        switch configuration.fixture.route {
        case .gameplay:
            gameplayCaptureView
        case .menu, .settings:
            menuCaptureView
        @unknown default:
            EmptyView()
        }
    }

    private var menuCaptureView: some View {
        ContentView(
            themeManager: dependencies.themeManager,
            fontPreferenceStore: dependencies.fontPreferenceStore,
            highestScoreStore: dependencies.highestScoreStore,
            achievementProgressService: dependencies.achievementProgressService,
            leaderboardService: dependencies.leaderboardService,
            watchBestScoreRelaySender: dependencies.watchBestScoreRelaySender,
            allowsGameLaunch: false,
            isGameCenterAuthenticatedOverride: true
        )
        .onAppear {
            if configuration.fixture.route == .menu {
                handleMenuLayoutReady()
            }
        }
    }

    private var gameplayCaptureView: some View {
        NavigationStack {
            WatchGameView(
                theme: gameplayTheme,
                fontPreferenceStore: dependencies.fontPreferenceStore,
                highestScoreStore: dependencies.highestScoreStore,
                achievementProgressService: dependencies.achievementProgressService,
                leaderboardService: dependencies.leaderboardService,
                watchBestScoreRelaySender: dependencies.watchBestScoreRelaySender,
                screenshotLayout: configuration.fixture.layout,
                screenshotReadinessIdentifier: configuration.readinessIdentifier,
                onScreenshotLayoutReady: handleGameplayLayoutReady
            )
        }
    }

    private var settingsView: some View {
        let settingsHapticController = WatchHapticFeedbackController(
            userDefaults: InfrastructureDefaults.userDefaults
        )
        let previewDependencies = settingsPreviewDependencyFactory.make(
            hapticController: settingsHapticController
        )
        return SettingsView(
            themeManager: dependencies.themeManager,
            fontPreferenceStore: dependencies.fontPreferenceStore,
            supportsHapticFeedback: true,
            hapticController: settingsHapticController,
            audioCueTutorialPreviewPlayer: previewDependencies.audioCueTutorialPreviewPlayer,
            speedWarningFeedbackPreviewPlayer: previewDependencies.speedWarningFeedbackPreviewPlayer,
            isGameCenterAuthenticated: true,
            achievementProgressService: dependencies.achievementProgressService,
            screenshotFocus: .themeAndFont,
            onScreenshotLayoutReady: handleSheetLayoutReady
        )
        .fontPreferenceStore(dependencies.fontPreferenceStore)
    }

    private var gameplayTheme: any GameTheme {
        let platformConfig = ThemePlatformConfig.watchOS
        return platformConfig.availableThemes.first {
            $0.id == configuration.fixture.themeID
        } ?? platformConfig.defaultTheme
    }

    private var settingsPreviewDependencyFactory: SettingsPreviewDependencyFactory {
        SettingsPreviewDependencyFactory(
            laneCuePlayerFactory: { PlatformFactories.makeLaneCuePlayer() },
            announcementPoster: AccessibilityAnnouncementPoster(),
            announcementTextProvider: {
                GameLocalizedStrings.string("speed_increase_announcement")
            },
            volumeProvider: {
                SoundEffectsVolumePreference.currentSelection(from: InfrastructureDefaults.userDefaults)
            }
        )
    }

    private func handleMenuLayoutReady() {
        isGameplayReady = true
        updateCaptureReadiness()
    }

    private func handleGameplayLayoutReady() {
        isGameplayReady = true
        updateCaptureReadiness()
    }

    private func handleSheetLayoutReady() {
        isSheetReady = true
        updateCaptureReadiness()
    }

    private func updateCaptureReadiness() {
        let shouldBeReady: Bool
        if configuration.fixture.presentsSettingsSheet {
            shouldBeReady = isSheetReady
        } else if configuration.fixture.route == .menu {
            shouldBeReady = isGameplayReady
        } else {
            shouldBeReady = isGameplayReady
        }
        if isLayoutReady != shouldBeReady {
            isLayoutReady = shouldBeReady
        }
    }
}

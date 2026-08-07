//
//  ContentView.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 01/02/2026.
//

import GroupActivities
import RetroRacingShared
import SwiftUI

struct ContentView: View {
    @Environment(VisionGameSessionCoordinator.self) private var session
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.pushWindow) private var pushWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSettingsPresented = false
    @State private var isFinishConfirmationPresented = false

    let dependencies: VisionAppDependencies

    var body: some View {
        rootContent
            .ornament(
                visibility: themeManager.currentTheme.id == .sixtyFourBit ? .visible : .hidden,
                attachmentAnchor: .scene(.top),
                contentAlignment: .center
            ) {
                Button(
                    GameLocalizedStrings.string("vision_play_in_3d"),
                    systemImage: "cube.transparent",
                    action: showTabletop
                )
                .labelStyle(.titleAndIcon)
                .opacity(session.screen == .playing ? 1 : 0)
                .disabled(
                    session.screen != .playing
                        || session.presentationTransition != .idle
                        || session.isSharePlayActive
                )
                .accessibilityHint(GameLocalizedStrings.string("vision_play_in_3d_hint"))
                .accessibilityInputLabels([
                    GameLocalizedStrings.string("vision_play_in_3d"),
                    GameLocalizedStrings.string("vision_tabletop_title")
                ])
            }
            .sheet(isPresented: $isSettingsPresented) {
                settingsView
                    .settingsSheetStyle()
            }
            .alert(
                GameLocalizedStrings.string("game_exit_confirmation_title"),
                isPresented: $isFinishConfirmationPresented
            ) {
                Button(GameLocalizedStrings.string("game_exit_confirmation_keep_playing"), role: .cancel) {}
                Button(
                    GameLocalizedStrings.string("game_exit_confirmation_finish"),
                    role: .destructive,
                    action: session.finish
                )
            } message: {
                Text(GameLocalizedStrings.string("game_exit_confirmation_message"))
            }
            .sheet(isPresented: sharePlayResultBinding) {
                sharePlayResultView
            }
            .onAppear {
                updateActivity()
                acknowledgeClassicIfNeeded()
            }
            .onDisappear {
                session.setPresentationActive(.classic, isActive: false)
            }
            .onChange(of: scenePhase) {
                updateActivity()
            }
            .onChange(of: session.presentationTransition) {
                acknowledgeClassicIfNeeded()
            }
            .onChange(of: isSettingsPresented) {
                updateOverlayPause()
            }
            .onChange(of: isFinishConfirmationPresented) {
                updateOverlayPause()
            }
            .onKeyPress(.leftArrow) {
                session.moveLeft()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                session.moveRight()
                return .handled
            }
            .onKeyPress(.space) {
                session.togglePause()
                return .handled
            }
            .accessibilityAction(.magicTap, session.togglePause)
            .alert(
                GameLocalizedStrings.string("vision_transition_alert_title"),
                isPresented: transitionFailureBinding
            ) {
                Button(GameLocalizedStrings.string("ok"), action: session.clearTransitionFailure)
            } message: {
                Text(session.transitionFailure?.message ?? "")
            }
            .alert(
                GameLocalizedStrings.string("menu_play_with_friends"),
                isPresented: sharePlayActivationFailureBinding
            ) {
                Button(
                    GameLocalizedStrings.string("ok"),
                    action: session.clearSharePlayActivationFailure
                )
            } message: {
                Text(GameLocalizedStrings.string("vision_shareplay_activation_failed"))
            }
            .groupActivityAssociation(
                .primary(RetroRacingGroupActivity.activityIdentifier)
            )
    }

    @ViewBuilder
    private var rootContent: some View {
        if session.screen == .menu {
            menuView
        } else {
            NavigationStack {
                ClassicGameView(imageLoader: dependencies.imageLoader)
                    .navigationTitle(GameLocalizedStrings.string("gameName"))
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: showFinishConfirmation) {
                                Label(GameLocalizedStrings.string("menu_button"), systemImage: "xmark")
                            }
                            .accessibilityLabel(GameLocalizedStrings.string("menu_button"))
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            if session.screen == .playing {
                                Button(action: session.togglePause) {
                                    Label(
                                        GameLocalizedStrings.string(session.isUserPaused ? "resume" : "pause"),
                                        systemImage: session.isUserPaused ? "play.fill" : "pause.fill"
                                    )
                                }
                                .accessibilityLabel(
                                    GameLocalizedStrings.string(session.isUserPaused ? "resume" : "pause")
                                )
                                .disabled(isPauseButtonDisabled)
                                .opacity(isPauseButtonDisabled ? 0.4 : 1)
                            }
                        }
                    }
            }
        }
    }

    private var menuView: some View {
        MenuView(
            leaderboardService: dependencies.gameCenterService,
            gameCenterService: dependencies.gameCenterService,
            ratingService: dependencies.ratingService,
            leaderboardConfiguration: dependencies.leaderboardConfiguration,
            authenticationPresenter: dependencies.authenticationPresenter,
            themeManager: dependencies.themeManager,
            fontPreferenceStore: dependencies.fontPreferenceStore,
            hapticController: dependencies.hapticController,
            supportsHapticFeedback: false,
            highestScoreStore: dependencies.highestScoreStore,
            achievementProgressService: dependencies.achievementProgressService,
            playLimitService: dependencies.playLimitService,
            specialEventService: dependencies.specialEventService,
            style: .universal,
            settingsStyle: .universal,
            gameViewStyle: .universal,
            controlsDescriptionKey: "settings_controls_visionos",
            showRateButton: true,
            inputAdapterFactory: TouchInputAdapterFactory(),
            onPlayRequest: session.play,
            onSettingsRequest: showSettings,
            onPlayWithFriendsRequest: session.requestSharePlay
        )
        .interactiveDismissDisabled(true)
    }

    private var settingsView: some View {
        let previewDependencies = SettingsPreviewDependencyFactory(
            laneCuePlayerFactory: { PlatformFactories.makeLaneCuePlayer() },
            announcementPoster: AccessibilityAnnouncementPoster(),
            announcementTextProvider: {
                GameLocalizedStrings.string("speed_increase_announcement")
            },
            volumeProvider: {
                SoundEffectsVolumePreference.currentSelection(
                    from: InfrastructureDefaults.userDefaults
                )
            }
        ).make(hapticController: dependencies.hapticController)

        return SettingsView(
            themeManager: dependencies.themeManager,
            fontPreferenceStore: dependencies.fontPreferenceStore,
            supportsHapticFeedback: false,
            hapticController: dependencies.hapticController,
            audioCueTutorialPreviewPlayer: previewDependencies.audioCueTutorialPreviewPlayer,
            speedWarningFeedbackPreviewPlayer: previewDependencies.speedWarningFeedbackPreviewPlayer,
            controlsDescriptionKey: "settings_controls_visionos",
            style: .universal,
            achievementProgressService: dependencies.achievementProgressService,
            isGameSessionInProgress: session.isPlaying,
            playLimitService: dependencies.playLimitService,
            specialEventService: dependencies.specialEventService
        )
        .fontPreferenceStore(dependencies.fontPreferenceStore)
    }

    private var transitionFailureBinding: Binding<Bool> {
        Binding(
            get: { session.transitionFailure != nil },
            set: { isPresented in
                if isPresented == false {
                    session.clearTransitionFailure()
                }
            }
        )
    }

    private var isPauseButtonDisabled: Bool {
        session.presentationTransition != .idle
            || (session.snapshot.phase != .running && session.isUserPaused == false)
    }

    private func showSettings() {
        isSettingsPresented = true
    }

    private func showFinishConfirmation() {
        isFinishConfirmationPresented = true
    }

    private func showTabletop() {
        _ = session.beginPresentationTransition(to: .tabletop, using: windowActions)
    }

    private var windowActions: VisionWindowActions {
        VisionWindowActions(
            pushWindow: pushWindow,
            openWindow: openWindow,
            dismissWindow: dismissWindow
        )
    }

    private func updateActivity() {
        session.setPresentationActive(.classic, isActive: scenePhase == .active)
    }

    private func updateOverlayPause() {
        session.setOverlayPresented(
            isSettingsPresented || isFinishConfirmationPresented
        )
    }

    private func acknowledgeClassicIfNeeded() {
        guard let transitionID = session.currentTransitionID(for: .classic) else { return }
        session.presentationDidBecomeReady(
            .classic,
            transitionID: transitionID,
            using: windowActions
        )
    }

    private var sharePlayResultBinding: Binding<Bool> {
        Binding(
            get: { session.shouldPresentSharePlayResult },
            set: { _ in }
        )
    }

    private var sharePlayActivationFailureBinding: Binding<Bool> {
        Binding(
            get: { session.isSharePlayActivationFailurePresented },
            set: { isPresented in
                if isPresented == false {
                    session.clearSharePlayActivationFailure()
                }
            }
        )
    }

    private var sharePlayResultView: some View {
        let summary = session.gameOverScoreSummary ?? GameOverScoreSummary(
            score: session.snapshot.score,
            bestScore: dependencies.highestScoreStore.currentBest(for: session.snapshot.difficulty),
            isNewRecord: false,
            previousBestScore: nil
        )
        return SharePlayResultView(
            state: session.sharePlayUIState.state,
            localRole: session.sharePlayUIState.localRole,
            opponentDisplayName: session.sharePlayUIState.opponentDisplayName,
            score: summary.score,
            bestScore: summary.bestScore,
            difficulty: session.snapshot.difficulty,
            isNewRecord: summary.isNewRecord,
            previousBestScore: summary.previousBestScore,
            nextFriendAhead: nil,
            overtakenFriends: [],
            newlyAchievedAchievementIDs: [],
            onRetry: session.retrySharePlay,
            onLeave: session.leaveSharePlay
        )
        .fontPreferenceStore(dependencies.fontPreferenceStore)
    }
}

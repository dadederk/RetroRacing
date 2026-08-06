//
//  ContentView.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 01/02/2026.
//

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
    @State private var preferencesStore: SettingsPreferencesStore

    init() {
        _preferencesStore = State(initialValue: SettingsPreferencesStore(
            userDefaults: InfrastructureDefaults.userDefaults,
            supportsHaptics: false,
            isVoiceOverRunningProvider: { VoiceOverStatus.isVoiceOverRunning }
        ))
    }

    var body: some View {
        gameContent
            .sheet(isPresented: $isSettingsPresented) {
                VisionSettingsView(preferencesStore: preferencesStore)
            }
    }

    private var gameContent: some View {
        NavigationStack {
            ClassicGameView(settingsAction: showSettings)
                .navigationTitle(GameLocalizedStrings.string("gameName"))
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: showSettings) {
                            Label(GameLocalizedStrings.string("settings"), systemImage: "gearshape")
                        }
                        .accessibilityLabel(GameLocalizedStrings.string("settings"))
                    }
                }
        }
        .ornament(
            visibility: themeManager.currentTheme.id == .sixtyFourBit ? .visible : .hidden,
            attachmentAnchor: .scene(.top),
            contentAlignment: .center
        ) {
            Button(GameLocalizedStrings.string("vision_play_in_3d"), systemImage: "cube.transparent", action: showTabletop)
                .labelStyle(.titleAndIcon)
                .opacity(session.screen == .playing ? 1 : 0)
                .disabled(session.screen != .playing || session.presentationTransition != .idle)
                .accessibilityHint(GameLocalizedStrings.string("vision_play_in_3d_hint"))
                .accessibilityInputLabels([
                    GameLocalizedStrings.string("vision_play_in_3d"),
                    GameLocalizedStrings.string("vision_tabletop_title")
                ])
        }
        .onAppear {
            preferencesStore.loadIfNeeded()
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

    private func showSettings() {
        isSettingsPresented = true
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

    private func acknowledgeClassicIfNeeded() {
        guard let transitionID = session.currentTransitionID(for: .classic) else { return }
        session.presentationDidBecomeReady(
            .classic,
            transitionID: transitionID,
            using: windowActions
        )
    }
}

private struct VisionSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(VisionGameSessionCoordinator.self) private var session
    @Environment(ThemeManager.self) private var themeManager
    @Bindable var preferencesStore: SettingsPreferencesStore
    @AppStorage(
        DebugGameplayStorageKeys.experimentalThirtyTwoBitThemeEnabled,
        store: InfrastructureDefaults.userDefaults
    ) private var debugExperimentalThirtyTwoBitThemeEnabled = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        GameLocalizedStrings.string("settings_theme_style"),
                        selection: Binding(
                            get: { themeManager.currentTheme.id },
                            set: selectTheme
                        )
                    ) {
                        ForEach(
                            themeManager.availableThemes.filter(themeManager.isThemeAvailable),
                            id: \.id
                        ) { theme in
                            Text(theme.name).tag(theme.id)
                        }
                    }
                    .disabled(session.screen == .playing)
                } header: {
                    Text(GameLocalizedStrings.string("settings_theme"))
                }

                Section {
                    Toggle(isOn: preferencesStore.directTouchSelection) {
                        Text(GameLocalizedStrings.string("settings_direct_touch"))
                    }
                } header: {
                    Text(GameLocalizedStrings.string("settings_accessibility"))
                }

                if BuildConfiguration.shouldShowDebugFeatures {
                    Section {
                        Toggle(isOn: $debugExperimentalThirtyTwoBitThemeEnabled) {
                            Text(GameLocalizedStrings.string("debug_enable_experimental_thirty_two_bit_theme"))
                        }
                        .disabled(session.screen == .playing)
                        .onChange(of: debugExperimentalThirtyTwoBitThemeEnabled) {
                            themeManager.applyExperimentalThemes(ExperimentalThemeConfiguration(
                                isThirtyTwoBitEnabled: debugExperimentalThirtyTwoBitThemeEnabled,
                                isSixtyFourBitEnabled: false
                            ))
                        }
                    } header: {
                        Text(GameLocalizedStrings.string("debug_section_title"))
                    }
                }
            }
            .navigationTitle(GameLocalizedStrings.string("settings"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(GameLocalizedStrings.string("done"), action: dismiss.callAsFunction)
                }
            }
        }
    }

    private func selectTheme(_ id: ThemeID) {
        guard let theme = themeManager.availableThemes.first(where: { $0.id == id }) else {
            return
        }
        themeManager.setTheme(theme)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(VisionGameSessionCoordinator(
            engine: GameEngine(randomSource: SystemRandomSource(), difficulty: .rapid),
            scheduler: TaskGameLoopScheduler(frameDuration: .milliseconds(16)),
            delayScheduler: TaskVisionDelayScheduler(),
            windowRouter: VisionWindowRouter(strategy: .push),
            tabletopModelRepository: TabletopModelRepository(
                playerResourceName: "player-car-64bit",
                rivalResourceName: "rival-car-64bit",
                bundle: .main
            ),
            controllerInputSource: NoOpGameControllerInputSource()
        ))
        .environment(ThemeManager(
            configuration: .visionOS,
            userDefaults: InfrastructureDefaults.userDefaults,
            hasPremiumAccess: false
        ))
}

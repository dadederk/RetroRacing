//
//  TabletopGameView.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 05/08/2026.
//

import RealityKit
import RetroRacingShared
import SwiftUI

struct TabletopGameView: View {
    @Environment(VisionGameSessionCoordinator.self) private var session
    @Environment(\.pushWindow) private var pushWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @AppStorage(DirectTouchSetting.conditionalDefaultStorageKey) private var directTouchData = Data()
    @AccessibilityFocusState private var isTrackAccessibilityFocused: Bool
    @State private var tabletopScene: TabletopScene?

    var body: some View {
        ZStack {
            tabletopRealityView
                .accessibilityDirectTouch(isDirectTouchEnabled)

            VStack(spacing: 16) {
                VisionGameHUD(snapshot: session.snapshot)
                Spacer()
                if session.screen == .gameOver {
                    VisionGameOverPanel(isTabletop: true)
                } else {
                    VisionGameControls()
                }
            }
            .padding(24)
        }
        .ornament(visibility: .visible, attachmentAnchor: .scene(.top), contentAlignment: .center) {
            Button(
                GameLocalizedStrings.string("vision_return_to_2d"),
                systemImage: "rectangle",
                action: returnToClassic
            )
            .disabled(session.presentationTransition != .idle)
            .accessibilityHint(GameLocalizedStrings.string("vision_return_to_2d_hint"))
            .accessibilityInputLabels([
                GameLocalizedStrings.string("vision_return_to_2d"),
                GameLocalizedStrings.string("vision_classic_title")
            ])
        }
        .onAppear(perform: updateActivity)
        .onDisappear {
            session.setPresentationActive(.tabletop, isActive: false)
            session.tabletopDidDisappear(using: windowActions)
        }
        .onChange(of: scenePhase, updateActivity)
        .onChange(of: session.focusRestorationSequence) {
            isTrackAccessibilityFocused = true
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

    private var tabletopRealityView: some View {
        RealityView { content in
            guard let transitionID = session.currentTransitionID(for: .tabletop) else { return }
            do {
                let factory = TabletopSceneFactory(
                    modelRepository: session.tabletopModelRepository
                )
                let scene = try await factory.makeScene(
                    snapshot: session.snapshot,
                    visualStyle: TabletopSceneVisualStyle(
                        increasedContrast: colorSchemeContrast == .increased,
                        differentiateWithoutColor: differentiateWithoutColor
                    )
                )
                tabletopScene = scene
                content.add(scene.root)
                session.presentationDidBecomeReady(
                    .tabletop,
                    transitionID: transitionID,
                    using: windowActions
                )
            } catch {
                session.destinationDidFail(
                    transitionID: transitionID,
                    failure: .modelUnavailable,
                    underlyingError: error
                )
            }
        } update: { _ in
            tabletopScene?.update(snapshot: session.snapshot)
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    guard let lane = TabletopScene.lane(for: value.entity) else { return }
                    session.selectLane(lane)
                }
        )
        .accessibilityLabel(GameLocalizedStrings.string("vision_tabletop_track"))
        .accessibilityValue(accessibilityValue)
        .accessibilityFocused($isTrackAccessibilityFocused)
        .accessibilityAction(named: GameLocalizedStrings.string("move_left"), session.moveLeft)
        .accessibilityAction(named: GameLocalizedStrings.string("move_right"), session.moveRight)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: session.moveRight()
            case .decrement: session.moveLeft()
            @unknown default: break
            }
        }
    }

    private var isDirectTouchEnabled: Bool {
        _ = directTouchData
        return VisionGameInteractionPolicy.isDirectTouchEnabled(
            on: .tabletopRoad,
            userEnabled: DirectTouchPreference.currentSelection(
                from: InfrastructureDefaults.userDefaults
            )
        )
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

    private var accessibilityValue: String {
        GameLocalizedStrings.format(
            "vision_race_status_format",
            session.snapshot.score,
            session.snapshot.lives,
            session.snapshot.playerColumn + 1,
            session.snapshot.numberOfColumns,
            phaseDescription
        )
    }

    private var phaseDescription: String {
        switch session.snapshot.phase {
        case .ready: GameLocalizedStrings.string("vision_state_ready")
        case .running: GameLocalizedStrings.string("vision_state_racing")
        case .paused: GameLocalizedStrings.string("vision_state_paused")
        case .collision: GameLocalizedStrings.string("vision_state_collision")
        case .gameOver: GameLocalizedStrings.string("vision_game_over")
        case .finished: GameLocalizedStrings.string("vision_state_finished")
        @unknown default: GameLocalizedStrings.string("vision_state_ready")
        }
    }

    private var windowActions: VisionWindowActions {
        VisionWindowActions(
            pushWindow: pushWindow,
            openWindow: openWindow,
            dismissWindow: dismissWindow
        )
    }

    private func returnToClassic() {
        _ = session.beginPresentationTransition(to: .classic, using: windowActions)
    }

    private func updateActivity() {
        session.setPresentationActive(.tabletop, isActive: scenePhase == .active)
    }
}

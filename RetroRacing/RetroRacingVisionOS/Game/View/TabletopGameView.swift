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
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @AppStorage(DirectTouchSetting.conditionalDefaultStorageKey) private var directTouchData = Data()
    @AccessibilityFocusState private var isTrackAccessibilityFocused: Bool
    @State private var tabletopScene: TabletopScene?
    @State private var surfaceAnchor: AnchorEntity?
    @State private var anchorSubscription: EventSubscription?

    var body: some View {
        tabletopRealityView
            .accessibilityDirectTouch(isDirectTouchEnabled && session.spatialState == .active)
            .onAppear(perform: updateActivity)
            .onDisappear {
                anchorSubscription = nil
                session.setPresentationActive(.spatial, isActive: false)
                session.spatialSceneDidDisappear(using: spatialActions)
            }
            .onChange(of: scenePhase) {
                updateActivity()
                if scenePhase == .background {
                    session.spatialDidEnterBackground(using: spatialActions)
                }
            }
            .onChange(of: session.focusRestorationSequence) {
                isTrackAccessibilityFocused = session.spatialState == .active
            }
            .onChange(of: session.requiresClassicForSharePlay, initial: true) {
                handOffToClassicForSharePlayIfNeeded()
            }
            .onKeyPress(.leftArrow) {
                guard session.isSpatialLaneInputEnabled else { return .ignored }
                session.moveLeft()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                guard session.isSpatialLaneInputEnabled else { return .ignored }
                session.moveRight()
                return .handled
            }
            .onKeyPress(.space) {
                guard session.spatialState == .active else { return .ignored }
                session.togglePause()
                return .handled
            }
            .accessibilityAction(.magicTap, togglePause)
    }

    private var tabletopRealityView: some View {
        RealityView { content in
            guard let transitionID = session.currentSpatialTransitionID() else { return }
            do {
                let scene = try await TabletopSceneFactory(
                    modelRepository: session.tabletopModelRepository
                ).makeScene(
                    snapshot: session.snapshot,
                    visualStyle: TabletopSceneVisualStyle(
                        increasedContrast: colorSchemeContrast == .increased,
                        differentiateWithoutColor: differentiateWithoutColor,
                        reduceMotion: reduceMotion
                    )
                )
                TabletopLaneGestureInstaller.install(in: scene) { lane in
                    guard session.isSpatialLaneInputEnabled else { return }
                    session.selectLane(lane)
                }
                scene.installHUD(
                    TabletopHUDPanel(
                        session: session,
                        resumeSpatialGame: session.confirmSpatialPlacement,
                        returnToClassic: returnToClassic,
                        finish: finish
                    )
                )

                let anchor = session.surfaceAnchorProvider.makeHorizontalSurfaceAnchor(
                    minimumBounds: scene.layout.minimumSurfaceBounds
                )
                anchor.name = "retrorapid-horizontal-surface"
                anchor.addChild(scene.root)
                tabletopScene = scene
                surfaceAnchor = anchor
                content.add(anchor)
                anchorSubscription = content.subscribe(
                    to: SceneEvents.AnchoredStateChanged.self,
                    on: anchor
                ) { event in
                    guard let changedAnchor = event.anchor as? AnchorEntity,
                          changedAnchor === anchor else {
                        return
                    }
                    session.spatialAnchorDidChange(
                        isAnchored: event.isAnchored,
                        transitionID: transitionID,
                        using: spatialActions
                    )
                }
                if anchor.isAnchored {
                    session.spatialAnchorDidChange(
                        isAnchored: true,
                        transitionID: transitionID,
                        using: spatialActions
                    )
                }
            } catch {
                session.spatialContentDidFail(
                    transitionID: transitionID,
                    underlyingError: error,
                    using: spatialActions
                )
            }
        } update: { _ in
            tabletopScene?.update(
                snapshot: session.snapshot,
                reduceMotion: reduceMotion,
                inputEnabled: session.isSpatialLaneInputEnabled
            )
        }
        .accessibilityLabel(GameLocalizedStrings.string("vision_tabletop_track"))
        .accessibilityValue(accessibilityValue)
        .accessibilityFocused($isTrackAccessibilityFocused)
        .accessibilityAction(named: GameLocalizedStrings.string("move_left")) {
            guard session.isSpatialLaneInputEnabled else { return }
            session.moveLeft()
        }
        .accessibilityAction(named: GameLocalizedStrings.string("move_right")) {
            guard session.isSpatialLaneInputEnabled else { return }
            session.moveRight()
        }
        .accessibilityAdjustableAction { direction in
            guard session.isSpatialLaneInputEnabled else { return }
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

    private var accessibilityValue: String {
        let raceStatus = GameLocalizedStrings.format(
            "vision_race_status_format",
            session.snapshot.score,
            session.snapshot.lives,
            session.snapshot.playerColumn + 1,
            session.snapshot.numberOfColumns,
            phaseDescription
        )
        let levelStatus = GameLocalizedStrings.format(
            "vision_level_format",
            session.snapshot.level
        )
        return "\(raceStatus), \(levelStatus)"
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

    private var spatialActions: VisionSpatialActions {
        VisionSpatialActions(
            openImmersiveSpace: openImmersiveSpace,
            dismissImmersiveSpace: dismissImmersiveSpace,
            openWindow: openWindow,
            dismissWindow: dismissWindow
        )
    }

    private func returnToClassic() {
        _ = session.beginReturnToClassic(using: spatialActions)
    }

    private func handOffToClassicForSharePlayIfNeeded() {
        guard session.requiresClassicForSharePlay else { return }
        _ = session.beginReturnToClassic(using: spatialActions)
    }

    private func finish() {
        session.finish()
        openWindow(id: VisionSceneID.classic)
        Task {
            await dismissImmersiveSpace()
        }
    }

    private func togglePause() {
        guard session.spatialState == .active else { return }
        session.togglePause()
    }

    private func updateActivity() {
        session.setPresentationActive(.spatial, isActive: scenePhase == .active)
    }
}

@MainActor
enum TabletopLaneGestureInstaller {
    static func install(
        in scene: TabletopScene,
        onSelection: @escaping (Int) -> Void
    ) {
        for (lane, target) in scene.laneTargets.enumerated() {
            let gesture = SpatialTapGesture().onEnded { _ in
                onSelection(lane)
            }
            target.components.set(GestureComponent(gesture))
        }
    }
}

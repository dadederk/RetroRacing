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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @AppStorage(DirectTouchSetting.conditionalDefaultStorageKey) private var directTouchData = Data()
    @AccessibilityFocusState private var isTrackAccessibilityFocused: Bool
    @State private var tabletopScene: TabletopScene?

    var body: some View {
        tabletopRealityView
            .ornament(
                visibility: .visible,
                attachmentAnchor: .scene(.back),
                contentAlignment: .front
            ) {
                TabletopHUDPanel(finish: finish)
            }
            .ornament(
                visibility: .visible,
                attachmentAnchor: .scene(.top),
                contentAlignment: .bottom
            ) {
                TabletopReturnToClassicButton(action: returnToClassic)
            }
            .supportedVolumeViewpoints(.front)
            .volumeBaseplateVisibility(.hidden)
            .accessibilityDirectTouch(isDirectTouchEnabled && session.spatialState == .active)
            .onAppear(perform: updateActivity)
            .onDisappear {
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
                togglePrimaryAction() ? .handled : .ignored
            }
            .accessibilityAction(.magicTap) {
                _ = togglePrimaryAction()
            }
            .accessibilityAction(.escape, returnToClassic)
    }

    private var tabletopRealityView: some View {
        GeometryReader3D { geometry in
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
                    positionBoard(scene.root, geometry: geometry, content: content)
                    tabletopScene = scene
                    content.add(scene.root)
                    session.spatialContentDidBecomeReady(
                        transitionID: transitionID,
                        using: spatialActions
                    )
                } catch {
                    session.spatialContentDidFail(
                        transitionID: transitionID,
                        underlyingError: error,
                        using: spatialActions
                    )
                }
            } update: { content in
                if let scene = tabletopScene {
                    positionBoard(scene.root, geometry: geometry, content: content)
                    scene.update(
                        snapshot: session.snapshot,
                        reduceMotion: reduceMotion,
                        inputEnabled: session.isSpatialLaneInputEnabled
                    )
                }
            }
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
            pushWindow: pushWindow,
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
        session.finishSpatialPresentation(using: spatialActions)
    }

    @discardableResult
    private func togglePrimaryAction() -> Bool {
        switch session.spatialState {
        case .ready:
            session.startSpatialGame()
            return true
        case .active:
            session.togglePause()
            return true
        case .inactive, .preflighting, .opening, .returning, .failure:
            return false
        }
    }

    private func updateActivity() {
        session.setPresentationActive(.spatial, isActive: scenePhase == .active)
    }

    private func positionBoard(
        _ root: Entity,
        geometry: GeometryProxy3D,
        content: RealityViewContent
    ) {
        let volumeBounds = content.convert(
            geometry.frame(in: .local),
            from: .local,
            to: .scene
        )
        root.position = TabletopVolumeLayout.boardRootPosition(
            volumeMinimum: volumeBounds.min,
            volumeMaximum: volumeBounds.max
        )
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

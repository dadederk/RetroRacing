//
//  ClassicRaceSpriteView.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import RetroRacingShared
import SpriteKit
import SwiftUI

struct ClassicRaceSpriteView: View {
    @Environment(VisionGameSessionCoordinator.self) private var session
    @AppStorage(DirectTouchSetting.conditionalDefaultStorageKey) private var directTouchData = Data()
    @AppStorage(BigCarsSetting.conditionalDefaultStorageKey) private var bigCarsData = Data()
    @AppStorage(RoadVisualStyle.storageKey) private var roadVisualStyleRawValue = RoadVisualStyle.defaultStyle.rawValue
    @AccessibilityFocusState private var isAccessibilityFocused: Bool
    @State private var scene: GameScene?

    let snapshot: GameSnapshot
    let theme: any GameTheme
    let imageLoader: any ImageLoader

    var body: some View {
        GeometryReader { geometry in
            raceScene
                .contentShape(.rect)
                .gesture(
                    SpatialTapGesture().onEnded { value in
                        selectLane(at: value.location.x, width: geometry.size.width)
                    }
                )
                .onAppear {
                    makeSceneIfNeeded(size: geometry.size)
                }
                .onChange(of: geometry.size) { _, newSize in
                    makeSceneIfNeeded(size: newSize)
                }
        }
        .compositingGroup()
        .clipShape(.rect(cornerRadius: 28))
        .accessibilityDirectTouch(isDirectTouchEnabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GameLocalizedStrings.string("vision_classic_track"))
        .accessibilityValue(accessibilityValue)
        .accessibilityInputLabels([
            GameLocalizedStrings.string("vision_classic_track"),
            GameLocalizedStrings.string("vision_race_track_input_label")
        ])
        .accessibilityAction(named: GameLocalizedStrings.string("move_left"), session.moveLeft)
        .accessibilityAction(named: GameLocalizedStrings.string("move_right"), session.moveRight)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: session.moveRight()
            case .decrement: session.moveLeft()
            @unknown default: break
            }
        }
        .accessibilityFocused($isAccessibilityFocused)
        .onChange(of: session.focusRestorationSequence) {
            isAccessibilityFocused = true
        }
        .onChange(of: snapshot) { _, newSnapshot in
            scene?.render(snapshot: newSnapshot)
        }
        .onChange(of: theme.id) {
            scene?.updateTheme(theme)
        }
        .onChange(of: bigCarsData) {
            scene?.setBigRivalCarsEnabled(usesBigCars)
        }
        .onChange(of: roadVisualStyleRawValue) {
            scene?.setRoadVisualStyle(roadVisualStyle)
        }
    }

    @ViewBuilder
    private var raceScene: some View {
        if let scene {
            SpriteView(scene: scene)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        } else {
            theme.gridCellColor()
        }
    }

    private var roadVisualStyle: RoadVisualStyle {
        RoadVisualStyle.fromStoredValue(roadVisualStyleRawValue)
    }

    private var usesBigCars: Bool {
        _ = bigCarsData
        return BigCarsPreference.currentSelection(from: InfrastructureDefaults.userDefaults)
    }

    private var isDirectTouchEnabled: Bool {
        _ = directTouchData
        return VisionGameInteractionPolicy.isDirectTouchEnabled(
            on: .classicBoard,
            userEnabled: DirectTouchPreference.currentSelection(
                from: InfrastructureDefaults.userDefaults
            )
        )
    }

    private var accessibilityValue: String {
        GameLocalizedStrings.format(
            "vision_race_status_format",
            snapshot.score,
            snapshot.lives,
            snapshot.playerColumn + 1,
            snapshot.numberOfColumns,
            phaseDescription
        )
    }

    private var phaseDescription: String {
        switch snapshot.phase {
        case .ready: GameLocalizedStrings.string("vision_state_ready")
        case .running: GameLocalizedStrings.string("vision_state_racing")
        case .paused: GameLocalizedStrings.string("vision_state_paused")
        case .collision: GameLocalizedStrings.string("vision_state_collision")
        case .gameOver: GameLocalizedStrings.string("vision_game_over")
        case .finished: GameLocalizedStrings.string("vision_state_finished")
        @unknown default: GameLocalizedStrings.string("vision_state_ready")
        }
    }

    private func makeSceneIfNeeded(size: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        guard let scene else {
            self.scene = GameScene.snapshotRenderingScene(
                size: size,
                snapshot: snapshot,
                theme: theme,
                imageLoader: imageLoader,
                bigRivalCarsEnabled: usesBigCars,
                roadVisualStyle: roadVisualStyle
            )
            return
        }
        scene.resizeScene(to: size)
    }

    private func selectLane(at horizontalLocation: CGFloat, width: CGFloat) {
        guard let lane = VisionGameInteractionPolicy.lane(
            at: horizontalLocation,
            width: width,
            laneCount: snapshot.numberOfColumns
        ) else { return }
        session.selectLane(lane)
    }
}

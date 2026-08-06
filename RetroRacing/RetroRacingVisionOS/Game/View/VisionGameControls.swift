//
//  VisionGameControls.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 05/08/2026.
//

import RetroRacingShared
import SwiftUI

struct VisionGameControls: View {
    @Environment(VisionGameSessionCoordinator.self) private var session

    var body: some View {
        ViewThatFits {
            HStack(spacing: 18) { controlButtons }
            VStack(spacing: 14) { controlButtons }
        }
        .buttonStyle(.bordered)
        .controlSize(.extraLarge)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(GameLocalizedStrings.string("vision_race_controls"))
    }

    @ViewBuilder
    private var controlButtons: some View {
        Button(GameLocalizedStrings.string("move_left"), systemImage: "arrow.left", action: session.moveLeft)
            .labelStyle(.iconOnly)
            .disabled(session.snapshot.phase != .running)
            .accessibilityLabel(GameLocalizedStrings.string("move_left"))
            .accessibilityInputLabels([GameLocalizedStrings.string("move_left")])

        Button(
            session.isUserPaused
                ? GameLocalizedStrings.string("resume")
                : GameLocalizedStrings.string("pause"),
            systemImage: session.isUserPaused ? "play.fill" : "pause.fill",
            action: session.togglePause
        )
        .labelStyle(.iconOnly)
        .accessibilityLabel(
            session.isUserPaused
                ? GameLocalizedStrings.string("resume")
                : GameLocalizedStrings.string("pause")
        )
        .accessibilityInputLabels([
            session.isUserPaused
                ? GameLocalizedStrings.string("resume")
                : GameLocalizedStrings.string("pause")
        ])

        Button(GameLocalizedStrings.string("move_right"), systemImage: "arrow.right", action: session.moveRight)
            .labelStyle(.iconOnly)
            .disabled(session.snapshot.phase != .running)
            .accessibilityLabel(GameLocalizedStrings.string("move_right"))
            .accessibilityInputLabels([GameLocalizedStrings.string("move_right")])
    }
}

struct VisionGameOverPanel: View {
    @Environment(VisionGameSessionCoordinator.self) private var session
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    let isTabletop: Bool

    var body: some View {
        VStack(spacing: 14) {
            Text(GameLocalizedStrings.string("vision_game_over"))
                .font(.title)
                .bold()
            Text(GameLocalizedStrings.format("score %lld", session.snapshot.score))
                .font(.title3.monospacedDigit())
            ViewThatFits {
                HStack(spacing: 12) { gameOverButtons }
                VStack(spacing: 10) { gameOverButtons }
            }
        }
        .padding(24)
        .background(.regularMaterial, in: .rect(cornerRadius: 24))
    }

    @ViewBuilder
    private var gameOverButtons: some View {
        Button(GameLocalizedStrings.string("restart"), systemImage: "arrow.clockwise", action: session.restart)
            .buttonStyle(.borderedProminent)
        Button(GameLocalizedStrings.string("finish"), action: finish)
            .buttonStyle(.bordered)
    }

    private func finish() {
        session.finish()
        guard isTabletop else { return }
        if session.windowRoutingStrategy == .push {
            dismissWindow(id: VisionSceneID.tabletop)
            return
        }
        Task {
            await Task.yield()
            openWindow(id: VisionSceneID.classic)
            dismissWindow(id: VisionSceneID.tabletop)
        }
    }
}

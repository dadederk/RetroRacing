//
//  TabletopHUDPanel.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import RetroRacingShared
import SwiftUI

struct TabletopHUDPanel: View {
    @Environment(VisionGameSessionCoordinator.self) private var session

    let returnToClassic: () -> Void
    let finish: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text(statusText)
            .font(.title2.bold().monospacedDigit())
            .lineLimit(2)
            .minimumScaleFactor(0.72)
            .multilineTextAlignment(.center)
            .accessibilityLabel(GameLocalizedStrings.string("vision_race_status"))
            .accessibilityValue(statusText)

            Divider()

            if session.screen == .gameOver {
                gameOverContent
            } else {
                activeGameControls
            }
        }
        .frame(width: 600)
        .padding(24)
        .foregroundStyle(.white)
        .tint(.white)
        .background(Color.black.opacity(0.82), in: .rect(cornerRadius: 30))
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .stroke(.white.opacity(0.35), lineWidth: 2)
        }
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .contain)
    }

    private var statusText: String {
        GameLocalizedStrings.format(
            "vision_hud_status_format",
            session.snapshot.score,
            session.snapshot.lives,
            session.snapshot.level
        )
    }

    private var activeGameControls: some View {
        adaptiveButtonLayout {
            Button(
                session.isUserPaused
                    ? GameLocalizedStrings.string("resume")
                    : GameLocalizedStrings.string("pause"),
                systemImage: session.isUserPaused ? "play.fill" : "pause.fill",
                action: session.togglePause
            )
            .accessibilityInputLabels([
                session.isUserPaused
                    ? GameLocalizedStrings.string("resume")
                    : GameLocalizedStrings.string("pause")
            ])

            returnButton
        }
    }

    private var gameOverContent: some View {
        VStack(spacing: 12) {
            Text(GameLocalizedStrings.string("vision_game_over"))
                .font(.title.bold())

            adaptiveButtonLayout {
                Button(
                    GameLocalizedStrings.string("restart"),
                    systemImage: "arrow.clockwise",
                    action: session.restart
                )
                .buttonStyle(.borderedProminent)

                Button(GameLocalizedStrings.string("finish"), action: finish)

                returnButton
            }
        }
    }

    private var returnButton: some View {
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

    private func adaptiveButtonLayout<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12, content: content)
            VStack(spacing: 10, content: content)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

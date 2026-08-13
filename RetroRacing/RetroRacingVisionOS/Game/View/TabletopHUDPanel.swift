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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var focusedElement: FocusedElement?
    @ScaledMetric(relativeTo: .title2) private var lifeIconHeight: CGFloat = 42

    let finish: () -> Void

    private enum FocusedElement: Hashable {
        case primaryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            raceStatus
            Divider()
            stateControls
        }
        .frame(minWidth: 320, idealWidth: 440, maxWidth: 560)
        .padding(24)
        .glassBackgroundEffect()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(GameLocalizedStrings.string("vision_race_status"))
        .accessibilityValue(accessibilityStatusValue)
        .onAppear(perform: restoreFocus)
        .onChange(of: session.focusRestorationSequence) { restoreFocus() }
        .onChange(of: session.spatialState) { restoreFocus() }
    }

    private var raceStatus: some View {
        VStack(spacing: 8) {
            GameScoreStatusView(
                score: session.snapshot.score,
                textStyle: .largeTitle
            )
            .accessibilityAddTraits(.updatesFrequently)

            GameLivesStatusView(
                lives: session.snapshot.lives,
                lifeAssetName: SixtyFourBitTheme().lifeSprite() ?? "life-64Bit",
                bundle: VisionThemeSpriteAssets.bundle,
                visibleHeight: lifeIconHeight,
                spacing: 8
            )

            Text(GameLocalizedStrings.format("vision_level_format", session.snapshot.level))
                .appFont(.headline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var stateControls: some View {
        switch session.spatialState {
        case .ready:
            readyControls
        case .active:
            if session.screen == .gameOver {
                gameOverControls
            } else {
                racingControls
            }
        case .preflighting, .opening:
            ProgressView()
                .controlSize(.large)
        case .returning:
            ProgressView(GameLocalizedStrings.string("vision_return_to_2d"))
                .appFont(.body)
                .controlSize(.large)
        case .inactive, .failure:
            EmptyView()
        }
    }

    private var readyControls: some View {
        VStack(spacing: 12) {
            Label(
                GameLocalizedStrings.string("vision_surface_ready"),
                systemImage: "checkmark.circle.fill"
            )
            .appFont(.title2)

            SpatialActionButton(
                title: GameLocalizedStrings.string(session.isUserPaused ? "resume" : "play"),
                systemImage: "play.fill",
                textStyle: .headline,
                action: session.startSpatialGame
            )
            .accessibilityFocused($focusedElement, equals: .primaryAction)
        }
    }

    private var racingControls: some View {
        SpatialActionButton(
            title: GameLocalizedStrings.string(session.isUserPaused ? "resume" : "pause"),
            systemImage: session.isUserPaused ? "play.fill" : "pause.fill",
            textStyle: .headline,
            action: session.togglePause
        )
        .disabled(session.snapshot.phase != .running && session.isUserPaused == false)
        .accessibilityFocused($focusedElement, equals: .primaryAction)
    }

    private var gameOverControls: some View {
        VStack(spacing: 12) {
            Text(GameLocalizedStrings.string("vision_game_over"))
                .appFont(.title2)

            adaptiveButtonLayout {
                SpatialActionButton(
                    title: GameLocalizedStrings.string("restart"),
                    systemImage: "arrow.clockwise",
                    textStyle: .headline,
                    action: session.restart
                )
                .accessibilityFocused($focusedElement, equals: .primaryAction)

                SpatialActionButton(
                    title: GameLocalizedStrings.string("finish"),
                    systemImage: "flag.checkered",
                    textStyle: .headline,
                    action: finish
                )
            }
        }
    }

    private var accessibilityStatusValue: String {
        GameLocalizedStrings.format(
            "vision_hud_status_format",
            session.snapshot.score,
            session.snapshot.lives,
            session.snapshot.level
        )
    }

    @ViewBuilder
    private func adaptiveButtonLayout<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 10, content: content)
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12, content: content)
                VStack(spacing: 10, content: content)
            }
        }
    }

    private func restoreFocus() {
        switch session.spatialState {
        case .ready, .active:
            focusedElement = .primaryAction
        case .inactive, .preflighting, .opening, .returning, .failure:
            focusedElement = nil
        }
    }
}

private struct SpatialActionButton: View {
    let title: String
    let systemImage: String
    let textStyle: Font.TextStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .appFont(textStyle)
                .foregroundStyle(Color.accentColor)
        }
        .retroRacingSecondaryButtonStyle()
        .controlSize(.extraLarge)
        .accessibilityLabel(title)
        .accessibilityInputLabels([title])
    }
}

struct TabletopReturnToClassicButton: View {
    let action: () -> Void

    var body: some View {
        Button(
            GameLocalizedStrings.string("vision_return_to_2d"),
            systemImage: "rectangle",
            action: action
        )
        .labelStyle(.titleAndIcon)
        .accessibilityHint(GameLocalizedStrings.string("vision_return_to_2d_hint"))
        .accessibilityInputLabels([
            GameLocalizedStrings.string("vision_return_to_2d"),
            GameLocalizedStrings.string("vision_classic_title")
        ])
    }
}

//
//  TabletopHUDPanel.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import RetroRacingShared
import SwiftUI

struct TabletopHUDPanel: View {
    let session: VisionGameSessionCoordinator
    let resumeSpatialGame: () -> Void
    let returnToClassic: () -> Void
    let finish: () -> Void

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var focusedElement: FocusedElement?

    private enum FocusedElement: Hashable {
        case resume
        case recovery
    }

    var body: some View {
        VStack(spacing: 16) {
            scoreContent
            Divider()
            stateContent
        }
        .frame(minWidth: 360, idealWidth: 540, maxWidth: 640)
        .padding(24)
        .foregroundStyle(.white)
        .tint(.white)
        .background(
            Color.black.opacity(reduceTransparency ? 1 : 0.86),
            in: .rect(cornerRadius: 30)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .stroke(
                    colorSchemeContrast == .increased ? .white : .white.opacity(0.4),
                    lineWidth: colorSchemeContrast == .increased ? 4 : 2
                )
        }
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(GameLocalizedStrings.string("vision_race_status"))
        .accessibilityValue(accessibilityStatusValue)
        .onAppear(perform: restoreFocus)
        .onChange(of: session.focusRestorationSequence) { restoreFocus() }
        .onChange(of: session.spatialState) { restoreFocus() }
    }

    private var scoreContent: some View {
        VStack(spacing: 8) {
            Text(GameLocalizedStrings.string("score"))
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(session.snapshot.score, format: .number)
                .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                .contentTransition(.numericText())
                .accessibilityAddTraits(.updatesFrequently)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) { livesContent; levelContent }
                VStack(spacing: 8) { livesContent; levelContent }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var livesContent: some View {
        Label {
            Text(GameLocalizedStrings.format("lives_count", session.snapshot.lives))
                .font(.title3.bold().monospacedDigit())
        } icon: {
            Image(
                decorative: SixtyFourBitTheme().lifeSprite() ?? "playersCar-life-64Bit",
                bundle: VisionThemeSpriteAssets.bundle
            )
            .resizable()
            .scaledToFit()
            .frame(width: 42, height: 42)
        }
    }

    private var levelContent: some View {
        Text(GameLocalizedStrings.format("vision_level_format", session.snapshot.level))
            .font(.headline.monospacedDigit())
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var stateContent: some View {
        switch session.spatialState {
        case .awaitingConfirmation:
            placementControls
        case .active:
            if session.screen == .gameOver {
                gameOverControls
            } else {
                racingControls
            }
        case .recoveringSurface:
            recoveryContent
        case .preflighting, .opening, .searchingSurface:
            placementStatus
        case .returning:
            ProgressView(GameLocalizedStrings.string("vision_return_to_2d"))
                .controlSize(.large)
        case .inactive, .failure:
            returnButton
        }
    }

    private var placementControls: some View {
        VStack(spacing: 12) {
            Label(
                GameLocalizedStrings.string("vision_surface_ready"),
                systemImage: "checkmark.circle.fill"
            )
            .font(.title2.bold())

            Text(GameLocalizedStrings.string("vision_surface_confirmation_instructions"))
                .font(.body)
                .multilineTextAlignment(.center)

            adaptiveButtonLayout {
                Button(
                    GameLocalizedStrings.string("vision_resume_in_3d"),
                    systemImage: "play.fill",
                    action: resumeSpatialGame
                )
                .buttonStyle(.borderedProminent)
                .accessibilityFocused($focusedElement, equals: .resume)

                returnButton
            }
        }
    }

    private var racingControls: some View {
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
            .disabled(
                session.snapshot.phase != .running
                    && session.isUserPaused == false
            )

            returnButton
        }
    }

    private var gameOverControls: some View {
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

    private var recoveryContent: some View {
        VStack(spacing: 10) {
            Label(
                GameLocalizedStrings.string("vision_surface_recovering"),
                systemImage: differentiateWithoutColor
                    ? "exclamationmark.triangle.fill"
                    : "viewfinder"
            )
            .font(.title2.bold())
            .accessibilityFocused($focusedElement, equals: .recovery)

            Text(GameLocalizedStrings.string("vision_surface_recovery_instructions"))
                .font(.body)
                .multilineTextAlignment(.center)

            returnButton
        }
    }

    private var placementStatus: some View {
        VStack(spacing: 10) {
            ProgressView()
                .controlSize(.large)
            Text(GameLocalizedStrings.string("vision_surface_searching"))
                .font(.headline)
            returnButton
        }
    }

    private var returnButton: some View {
        Button(
            GameLocalizedStrings.string("vision_return_to_2d"),
            systemImage: "rectangle",
            action: returnToClassic
        )
        .disabled(session.spatialState == .returning)
        .accessibilityHint(GameLocalizedStrings.string("vision_return_to_2d_hint"))
        .accessibilityInputLabels([
            GameLocalizedStrings.string("vision_return_to_2d"),
            GameLocalizedStrings.string("vision_classic_title")
        ])
    }

    private var accessibilityStatusValue: String {
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

    private func adaptiveButtonLayout<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10, content: content)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12, content: content)
                    VStack(spacing: 10, content: content)
                }
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.extraLarge)
    }

    private func restoreFocus() {
        switch session.spatialState {
        case .awaitingConfirmation:
            focusedElement = .resume
        case .recoveringSurface:
            focusedElement = .recovery
        case .inactive, .preflighting, .opening, .searchingSurface,
             .active, .returning, .failure:
            focusedElement = nil
        }
    }
}

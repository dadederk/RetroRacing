//
//  ClassicGameView.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 05/08/2026.
//

import RetroRacingShared
import SwiftUI

struct ClassicGameView: View {
    @Environment(VisionGameSessionCoordinator.self) private var session
    @Environment(ThemeManager.self) private var themeManager
    let settingsAction: () -> Void

    var body: some View {
        switch session.screen {
        case .menu:
            VisionPlayView(
                theme: themeManager.currentTheme,
                playAction: session.play,
                settingsAction: settingsAction
            )
        case .playing:
            ScrollView {
                VStack(spacing: 18) {
                    VisionGameHUD(snapshot: session.snapshot)
                    ClassicRaceCanvas(snapshot: session.snapshot, theme: themeManager.currentTheme)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 720, minHeight: 320, maxHeight: 720)
                    VisionGameControls()
                }
                .padding(24)
            }
        case .gameOver:
            ScrollView {
                VStack(spacing: 18) {
                    VisionGameHUD(snapshot: session.snapshot)
                    ClassicRaceCanvas(snapshot: session.snapshot, theme: themeManager.currentTheme)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 720, minHeight: 320, maxHeight: 720)
                    VisionGameOverPanel(isTabletop: false)
                }
                .padding(24)
            }
        }
    }
}

private struct VisionPlayView: View {
    let theme: any GameTheme
    let playAction: () -> Void
    let settingsAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(
                theme.playerCarSprite() ?? "playersCar-LCD",
                bundle: VisionThemeSpriteAssets.bundle(for: theme)
            )
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 460, maxHeight: 300)
                .accessibilityHidden(true)

            Text(theme.name)
                .font(.largeTitle)
                .bold()

            Text(GameLocalizedStrings.string("vision_play_description"))
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 560)

            ViewThatFits {
                HStack(spacing: 16) {
                    playButton
                    settingsButton
                }
                VStack(spacing: 12) {
                    playButton
                    settingsButton
                }
            }
        }
        .padding(40)
    }

    private var playButton: some View {
        Button(GameLocalizedStrings.string("play"), systemImage: "play.fill", action: playAction)
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .accessibilityInputLabels([GameLocalizedStrings.string("play")])
    }

    private var settingsButton: some View {
        Button(GameLocalizedStrings.string("settings"), systemImage: "gearshape", action: settingsAction)
            .controlSize(.extraLarge)
            .accessibilityInputLabels([GameLocalizedStrings.string("settings")])
    }
}

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

    let imageLoader: any ImageLoader

    var body: some View {
        ZStack {
            switch session.screen {
            case .menu:
                EmptyView()
            case .playing:
                VStack(spacing: 18) {
                    VisionGameHUD(snapshot: session.snapshot)
                    sharePlayLiveScoreRows
                    raceSquare
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            case .gameOver:
                ScrollView {
                    VStack(spacing: 18) {
                        VisionGameHUD(snapshot: session.snapshot)
                        raceSquare
                        VisionGameOverPanel()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 56)
                }
            }

            SharePlayOverlayView(
                state: session.sharePlayUIState.state,
                opponentDisplayName: session.sharePlayUIState.opponentDisplayName,
                onCountdownSecondChanged: session.playSharePlayCountdownCue
            )
            .padding(28)
        }
    }

    @ViewBuilder
    private var sharePlayLiveScoreRows: some View {
        if let remoteScore = session.sharePlayRemoteScore {
            SharePlayScoreComparisonRows(
                localLabel: GameLocalizedStrings.string("shareplay_local_player_name"),
                localScore: session.snapshot.score,
                opponentLabel: resolvedOpponentLabel,
                opponentScore: remoteScore,
                scoreFont: .headline
            )
        }
    }

    private var resolvedOpponentLabel: String {
        let name = session.sharePlayUIState.opponentDisplayName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let name, name.isEmpty == false else {
            return GameLocalizedStrings.string("shareplay_opponent_score_fallback_label")
        }
        return name
    }

    private var raceSquare: some View {
        ClassicRaceSpriteView(
            snapshot: session.snapshot,
            theme: themeManager.currentTheme,
            imageLoader: imageLoader
        )
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 720, minHeight: 320, maxHeight: 720)
    }
}

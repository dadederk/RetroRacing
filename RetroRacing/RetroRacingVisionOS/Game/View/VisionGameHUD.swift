//
//  VisionGameHUD.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 05/08/2026.
//

import RetroRacingShared
import SwiftUI

struct VisionGameHUD: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title) private var lifeIconHeight: CGFloat = 28

    let snapshot: GameSnapshot

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) { statusContent }
            } else {
                HStack(alignment: .center, spacing: 18) { statusContent }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GameLocalizedStrings.string("vision_race_status"))
        .accessibilityValue(
            GameLocalizedStrings.format(
                "vision_hud_status_format",
                snapshot.score,
                snapshot.lives,
                snapshot.level
            )
        )
    }

    @ViewBuilder
    private var statusContent: some View {
        GameScoreStatusView(score: snapshot.score, textStyle: .title)
            .layoutPriority(1)

        if !dynamicTypeSize.isAccessibilitySize {
            Spacer(minLength: 16)
        }

        GameLivesStatusView(
            lives: snapshot.lives,
            lifeAssetName: themeManager.currentTheme.lifeSprite() ?? "life-LCD",
            bundle: VisionThemeSpriteAssets.bundle,
            visibleHeight: lifeIconHeight
        )
        .layoutPriority(2)
    }
}

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
    @Environment(\.fontPreferenceStore) private var fontPreferenceStore
    @ScaledMetric(relativeTo: .title) private var lifeIconHeight: CGFloat = 28

    let snapshot: GameSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            GameScoreStatusView(
                score: snapshot.score,
                font: fontPreferenceStore?.font(textStyle: .title) ?? .title
            )
            .layoutPriority(1)

            Spacer(minLength: 16)

            GameLivesStatusView(
                lives: snapshot.lives,
                lifeAssetName: themeManager.currentTheme.lifeSprite() ?? "life-LCD",
                bundle: VisionThemeSpriteAssets.bundle,
                visibleHeight: lifeIconHeight
            )
            .layoutPriority(2)
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
}

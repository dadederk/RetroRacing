//
//  GameSpeedAlertView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/08/2026.
//

import SwiftUI

struct GameSpeedAlertView: View {
    let input: GameHUDInput
    let usesCompactLandscapeLayout: Bool

    @ScaledMetric(relativeTo: .body) private var iconMinimumHeight: CGFloat = 56

    var body: some View {
        Group {
            if usesCompactLandscapeLayout {
                VStack(alignment: .leading, spacing: 8) {
                    alertImage
                    alertText
                }
            } else {
                HStack(alignment: .center, spacing: 8) {
                    alertImage
                    alertText
                }
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(GameLocalizedStrings.string("speed_increase_announcement"))
        .accessibilityRespondsToUserInteraction(false)
        .accessibilityHidden(input.hidesFromAccessibility)
    }

    private var alertImage: some View {
        Image("HeyHo", bundle: input.bundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: iconMinimumHeight)
            .accessibilityLabel(GameLocalizedStrings.string("speed_alert_hey_ho"))
    }

    private var alertText: some View {
        Text(GameLocalizedStrings.string("speed_increasing_alert"))
            .font(input.speedAlertFont)
            .foregroundStyle(.primary)
            .shadow(color: Color.primary.opacity(0.35), radius: 0.5)
    }
}

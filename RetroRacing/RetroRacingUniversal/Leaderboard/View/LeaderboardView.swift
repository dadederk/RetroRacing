//
//  LeaderboardView.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
import RetroRacingShared

#if canImport(UIKit)
import GameKit

/// Presents Game Center leaderboard via GKAccessPoint (replacement for deprecated GKGameCenterViewController). App targets iOS 26+.
struct LeaderboardView: View {
    let leaderboardID: String
    let onDismiss: () -> Void

    var body: some View {
        Color.clear
            .onAppear {
                GKAccessPoint.shared.trigger(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime) {
                    onDismiss()
                }
            }
    }
}
#else
/// Placeholder when UIKit/GameKit is not available (e.g. macOS).
struct LeaderboardView: View {
    let leaderboardID: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(GameLocalizedStrings.string("leaderboard"))
            Text(GameLocalizedStrings.string("Game Center leaderboard is available on iOS and tvOS."))
            Button(GameLocalizedStrings.string("Close"), action: onDismiss)
        }
        .padding()
    }
}
#endif

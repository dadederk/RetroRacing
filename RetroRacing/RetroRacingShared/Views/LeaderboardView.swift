//
//  LeaderboardView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI

#if os(iOS) || os(tvOS)
import GameKit

/// Presents Game Center leaderboard via GKAccessPoint (replacement for deprecated GKGameCenterViewController) on iOS/tvOS.
public struct LeaderboardView: View {
    public let leaderboardID: String
    public let onDismiss: () -> Void

    public init(leaderboardID: String, onDismiss: @escaping () -> Void) {
        self.leaderboardID = leaderboardID
        self.onDismiss = onDismiss
    }

    public var body: some View {
        Color.clear
            .onAppear {
                GKAccessPoint.shared.trigger(
                    leaderboardID: leaderboardID,
                    playerScope: .global,
                    timeScope: .allTime
                ) {
                    onDismiss()
                }
            }
    }
}
#elseif os(macOS)
import GameKit

/// Presents Game Center leaderboard via GKAccessPoint on macOS.
public struct LeaderboardView: View {
    public let leaderboardID: String
    public let onDismiss: () -> Void

    public init(leaderboardID: String, onDismiss: @escaping () -> Void) {
        self.leaderboardID = leaderboardID
        self.onDismiss = onDismiss
    }

    public var body: some View {
        Color.clear
            .onAppear {
                GKAccessPoint.shared.trigger(
                    leaderboardID: leaderboardID,
                    playerScope: .global,
                    timeScope: .allTime
                ) {
                    onDismiss()
                }
            }
    }
}
#else
/// Placeholder when Game Center leaderboard UI is not available on the current platform.
public struct LeaderboardView: View {
    public let leaderboardID: String
    public let onDismiss: () -> Void

    public init(leaderboardID: String, onDismiss: @escaping () -> Void) {
        self.leaderboardID = leaderboardID
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text(GameLocalizedStrings.string("leaderboard"))
            Text(GameLocalizedStrings.string("Game Center leaderboard is not available on this device."))
            Button(GameLocalizedStrings.string("Close"), action: onDismiss)
        }
        .padding()
    }
}
#endif

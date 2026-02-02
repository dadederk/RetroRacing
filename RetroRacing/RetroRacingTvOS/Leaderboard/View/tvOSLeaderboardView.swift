import SwiftUI
import GameKit
import RetroRacingShared

/// Presents Game Center leaderboard via GKAccessPoint (replacement for deprecated GKGameCenterViewController). App targets tvOS 26+.
struct tvOSLeaderboardView: View {
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

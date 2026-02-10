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

/// macOS leaderboard using `GKGameCenterViewController` wrapped in SwiftUI so the sheet can be dismissed cleanly.
public struct LeaderboardView: NSViewControllerRepresentable {
    public let leaderboardID: String
    public let onDismiss: () -> Void

    public init(leaderboardID: String, onDismiss: @escaping () -> Void) {
        self.leaderboardID = leaderboardID
        self.onDismiss = onDismiss
    }

    public func makeNSViewController(context: Context) -> GKGameCenterViewController {
        AppLog.info(AppLog.game, "🎮 Creating GKGameCenterViewController for leaderboardID=\(leaderboardID)")
        let controller = GKGameCenterViewController(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        controller.gameCenterDelegate = context.coordinator
        return controller
    }

    public func updateNSViewController(_ nsViewController: GKGameCenterViewController, context: Context) {
        // No dynamic updates required.
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    public final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        private let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        public func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            AppLog.info(AppLog.game, "🎮 macOS Game Center controller finished, dismissing sheet")
            onDismiss()
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

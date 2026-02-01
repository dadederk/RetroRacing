import SwiftUI
import RetroRacingShared

#if canImport(UIKit)
import GameKit

/// Wraps GKGameCenterViewController for SwiftUI presentation.
/// Note: GKGameCenterViewController is deprecated in iOS 26; consider migrating to the new Games app APIs when documented.
struct LeaderboardView: UIViewControllerRepresentable {
    let leaderboardID: String
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc = GKGameCenterViewController(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        vc.gameCenterDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
            onDismiss()
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
            Text(String(localized: "leaderboard"))
            Text(String(localized: "Game Center leaderboard is available on iOS and tvOS."))
            Button(String(localized: "Close"), action: onDismiss)
        }
        .padding()
    }
}
#endif

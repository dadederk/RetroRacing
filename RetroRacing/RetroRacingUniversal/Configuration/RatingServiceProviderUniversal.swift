import Foundation
import RetroRacingShared
import StoreKit

#if canImport(UIKit)
import UIKit

/// Presents the in-app review UI on iOS/iPadOS using StoreKit.AppStore.requestReview (modern API).
final class RatingServiceProviderUniversal: RatingServiceProvider {
    func presentRatingRequest() {
        Task { @MainActor in
            if let windowScene = findActiveWindowScene() {
                AppStore.requestReview(in: windowScene)
            }
        }
    }

    private func findActiveWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}
#else
/// No-op when UIKit is not available (macOS). In-app review is not presented.
final class RatingServiceProviderMac: RatingServiceProvider {
    func presentRatingRequest() {}
}
#endif

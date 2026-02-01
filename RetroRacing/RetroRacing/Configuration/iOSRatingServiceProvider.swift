import Foundation
import RetroRacingShared
import StoreKit

#if canImport(UIKit)
import UIKit
#if canImport(AppStore)
import AppStore
#endif

/// Presents the in-app review UI on iOS using AppStore.requestReview when available.
final class iOSRatingServiceProvider: RatingServiceProvider {
    func presentRatingRequest() {
        Task { @MainActor in
            if let windowScene = findActiveWindowScene() {
                #if canImport(AppStore)
                await AppStore.requestReview(in: windowScene)
                #else
                if let windowScene = windowScene as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
                #endif
            }
        }
    }

    private func findActiveWindowScene() -> Any? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }
}
#else
/// No-op when UIKit is not available (e.g. macOS). In-app review is not presented.
final class MacRatingServiceProvider: RatingServiceProvider {
    func presentRatingRequest() {}
}
#endif

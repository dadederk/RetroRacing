import Foundation
import RetroRacingShared

/// tvOS does not support in-app review; no-op implementation.
final class tvOSRatingServiceProvider: RatingServiceProvider {
    func presentRatingRequest() {
        // App Store reviews are not supported on tvOS
    }
}

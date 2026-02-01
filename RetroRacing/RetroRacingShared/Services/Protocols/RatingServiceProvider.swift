import Foundation

/// Platform-specific implementation for presenting the app store review UI.
public protocol RatingServiceProvider {
    func presentRatingRequest()
}

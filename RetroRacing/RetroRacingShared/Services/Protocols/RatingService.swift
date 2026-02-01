import Foundation

public protocol RatingService {
    /// Request app rating from the user (typically from a button)
    func requestRating()

    /// Check if user qualifies for rating prompt and request if appropriate
    /// - Parameter score: The user's final score
    func checkAndRequestRating(score: Int)
}

import Foundation

/// Cross-platform random source for game logic. Use `SystemRandomSource()` on all platforms.
public protocol RandomSource: AnyObject {
    func nextInt(upperBound: Int) -> Int
}

/// Uses Swift's system random number generator. Available on all platforms including watchOS.
public final class SystemRandomSource: RandomSource {
    public init() {}

    public func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int.random(in: 0..<upperBound)
    }
}

import Foundation
@testable import RetroRacingShared

final class MockLeaderboardService: LeaderboardService {
    var submittedScores: [Int] = []
    var authenticated = true

    func submitScore(_ score: Int) {
        submittedScores.append(score)
    }

    func isAuthenticated() -> Bool {
        authenticated
    }
}

final class MockRandomSource: RandomSource {
    private var values: [Int]

    init(values: [Int] = []) {
        self.values = values
    }

    func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        guard values.isEmpty == false else { return 0 }
        let value = values.removeFirst()
        return value % upperBound
    }
}

final class MockHapticFeedbackController: HapticFeedbackController {
    private(set) var crashCount = 0
    private(set) var updateCount = 0

    func triggerCrashHaptic() { crashCount += 1 }
    func triggerGridUpdateHaptic() { updateCount += 1 }
}

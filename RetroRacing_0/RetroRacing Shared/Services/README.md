# Services

Service layer implementations following dependency injection and platform-agnostic design principles.

## Architecture

### LeaderboardService Protocol

Minimal interface for score submission across all platforms:

```swift
protocol LeaderboardService {
    func submitScore(_ score: Int)
    func isAuthenticated() -> Bool
}
```

### GameCenterService

Concrete Game Center implementation with **zero platform-specific code in view controllers**:

- **Platform-Specific Leaderboard IDs**: Automatically selects correct leaderboard based on platform
  - iOS: `bestios001test`
  - tvOS: `besttvos001`
  - watchOS: `bestwatchos001test`
- **Encapsulated Authentication**: Handles all Game Center authentication flow internally
- **Encapsulated Presentation**: Manages view controller creation, delegation, and dismissal
- **100% Reusable View Controllers**: iOS and tvOS MenuViewController share identical code

### RatingService Protocol

Minimal interface for app rating functionality:

```swift
protocol RatingService {
    func requestRating()  // Manual request (e.g., from button)
    func checkAndRequestRating(score: Int)  // Automatic check with intelligent prompting
}
```

### RatingServiceProvider Protocol

Platform-specific presentation abstraction:

```swift
protocol RatingServiceProvider {
    func presentRatingRequest()  // Platform-specific implementation
}
```

Platform implementations:
- **iOSRatingServiceProvider**: Uses `SKStoreReviewController.requestReview(in:)`
- **tvOSRatingServiceProvider**: No-op (reviews not supported on tvOS)
- **macOSRatingServiceProvider**: Uses `SKStoreReviewController.requestReview()`

### StoreReviewService

Native StoreKit implementation with intelligent prompting logic:

- **Zero Compilation Flags**: Uses injected `RatingServiceProvider` for platform differences
- **Encapsulated Logic**: All best score tracking and prompt rules handled internally
- **Respectful Prompting**: Only prompts once per app version
- **Achievement-Based**: Triggers on high scores (200+) and personal bests
- **Frequency Control**: Minimum 90 days between prompts
- **Experience Threshold**: Requires 3 games played before prompting
- **Platform Support**: iOS 14+, tvOS (no-op), macOS 10.14+
- **Native UI**: Uses system review dialog that respects user preferences

## Benefits

1. **Maximum Code Reuse**: View controllers are identical across iOS/tvOS
2. **Zero GameKit/StoreKit Knowledge**: View controllers don't import platform frameworks
3. **Platform Awareness**: Services automatically handle platform differences
4. **Simple View Controllers**: Just call service methods, no complex logic
5. **Testability**: Protocol-based design enables easy mocking

## Usage

### MenuViewController (Identical on iOS/tvOS)

```swift
import UIKit  // No GameKit import!

final class MenuViewController: UIViewController {
    private let gameCenterService: GameCenterService
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gameCenterService.authenticate(presentingViewController: self)
    }
    
    @IBAction private func leaderboardButtonPressed(_ sender: Any) {
        gameCenterService.createLeaderboardViewController(delegate: self)?.present(from: self)
    }
}

extension MenuViewController: AuthenticationViewController {
    func presentAuthenticationUI(_ viewController: UIViewController) {
        present(viewController, animated: true)
    }
}

extension MenuViewController: LeaderboardViewControllerDelegate {
    func leaderboardViewControllerDidFinish() { }
}
```

### GameViewController (Score Submission & Rating)

```swift
private let leaderboardService: LeaderboardService
private let ratingService: RatingService

init(leaderboardService: LeaderboardService = GameCenterService(configuration: iOSLeaderboardConfiguration()),
     ratingService: RatingService = StoreReviewService(provider: iOSRatingServiceProvider())) {
    self.leaderboardService = leaderboardService
    self.ratingService = ratingService
    super.init(nibName: nil, bundle: nil)
}

func gameOver(score: Int) {
    leaderboardService.submitScore(score)
    ratingService.checkAndRequestRating(score: score)  // Service handles all logic
}
```

### MenuViewController (Manual Rating)

```swift
init(ratingService: RatingService = StoreReviewService(provider: iOSRatingServiceProvider())) {
    self.ratingService = ratingService
    super.init(nibName: nil, bundle: nil)
}

@IBAction private func rateAppButtonPressed(_ sender: Any) {
    ratingService.requestRating()  // Direct request from button
}
```

### Testing

```swift
final class MockLeaderboardService: LeaderboardService {
    var submittedScores: [Int] = []
    
    func submitScore(_ score: Int) {
        submittedScores.append(score)
    }
    
    func isAuthenticated() -> Bool { true }
}

final class MockRatingService: RatingService {
    var ratingRequested = false
    var lastCheckedScore: Int?
    
    func requestRating() {
        ratingRequested = true
    }
    
    func checkAndRequestRating(score: Int) {
        lastCheckedScore = score
        if score >= 200 {
            ratingRequested = true
        }
    }
}
```

## Design Principles Applied

✅ **Simple**: View controllers are thin UI layers  
✅ **Clear**: Method names express intent (`authenticate`, `submitScore`)  
✅ **Maintainable**: All Game Center logic in one service  
✅ **DI-Friendly**: Protocol + concrete implementation  
✅ **Self-Documenting**: Code structure explains itself  
✅ **Platform-Agnostic**: Maximum reuse across iOS/tvOS/watchOS

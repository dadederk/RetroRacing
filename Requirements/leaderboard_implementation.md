# Leaderboard Implementation

## Overview

Game Center leaderboard system with dependency injection, zero compiler flags in services, and maximum code reuse across platforms.

## Architecture

### Configuration Layer

**`LeaderboardConfiguration` Protocol**
```swift
protocol LeaderboardConfiguration {
    var leaderboardID: String { get }
}
```

**Platform Implementations:**
- `iOSLeaderboardConfiguration` → `"bestios001test"`
- `tvOSLeaderboardConfiguration` → `"besttvos001"`  
- `watchOSLeaderboardConfiguration` → `"bestwatchos001test"`
- `macOSLeaderboardConfiguration` → TBD
- `visionOSLeaderboardConfiguration` → TBD

### Service Layer

**`LeaderboardService` Protocol**
```swift
protocol LeaderboardService {
    func submitScore(_ score: Int)
    func isAuthenticated() -> Bool
}
```

**`GameCenterService` Implementation**
- Accepts `LeaderboardConfiguration` via initializer
- **No compiler flags** for platform detection
- Handles all Game Center authentication and presentation
- Manages view controller lifecycle and delegation

### View Controller/View Layer

**Platform Integration:**
- iOS/tvOS: `MenuViewController` (UIKit)
- watchOS: `MenuView` (SwiftUI)
- macOS: TBD
- visionOS: TBD

View layer characteristics:
- Zero GameKit imports in view layer
- Only calls service methods
- Conforms to simple protocols for callbacks

## Known Issues

### Game Center View Controller Deprecations

```
'viewState' was deprecated in iOS 14.0
'leaderboardIdentifier' was deprecated in iOS 14.0
```

**Status:** ⚠️ **Safe to Ignore**
- Apple has NOT provided replacement API (as of iOS 18)
- Properties continue to work correctly
- Only way to configure `GKGameCenterViewController`
- Documented in `GameCenterService.swift`

**Alternative Considered:**
- Build custom leaderboard UI using `GKLeaderboard` API directly
- **Rejected**: Significantly more complex, loses native Game Center UI/UX

## Testing Strategy

### Unit Tests (Priority)

**Configuration Tests:**
```swift
func testConfigurationReturnsCorrectLeaderboardID() {
    let config = iOSLeaderboardConfiguration()
    XCTAssertEqual(config.leaderboardID, "bestios001test")
}
```

**Service Tests with Mock Configuration:**
```swift
struct MockLeaderboardConfiguration: LeaderboardConfiguration {
    let leaderboardID: String
}

func testServiceUsesInjectedConfiguration() {
    let mockConfig = MockLeaderboardConfiguration(leaderboardID: "test123")
    let service = GameCenterService(configuration: mockConfig)
    // Test service behavior
}
```

**View Controller Tests with Mock Service:**
```swift
final class MockLeaderboardService: LeaderboardService {
    var submittedScores: [Int] = []
    var authenticated = true
    
    func submitScore(_ score: Int) {
        submittedScores.append(score)
    }
    
    func isAuthenticated() -> Bool {
        return authenticated
    }
}

func testScoreSubmission() {
    let mockService = MockLeaderboardService()
    let viewController = GameViewController(leaderboardService: mockService)
    
    viewController.gameOver(score: 100)
    
    XCTAssertEqual(mockService.submittedScores, [100])
}
```

## Migration Guide

To add a new platform:

1. **Create Configuration**
```swift
// RetroRacing macOS/Configuration/macOSLeaderboardConfiguration.swift
struct macOSLeaderboardConfiguration: LeaderboardConfiguration {
    let leaderboardID = "bestmacos001"
}
```

2. **Update View Layer**
```swift
// Inject platform-specific configuration
init(gameCenterService: GameCenterService) {
    self.gameCenterService = gameCenterService
    super.init(nibName: nil, bundle: nil)
}

// In app delegate or parent view:
let config = macOSLeaderboardConfiguration()
let service = GameCenterService(configuration: config)
let viewController = MenuViewController(gameCenterService: service)
```

3. **Done!** No changes to `GameCenterService` required.

## Benefits Achieved

✅ **Dependency Injection**: All dependencies passed explicitly, no hidden globals  
✅ **Zero Compiler Flags**: Configuration injected, service platform-agnostic  
✅ **Maximum Code Reuse**: View controllers/views share identical logic  
✅ **Testability**: Easy to mock with protocol-based design  
✅ **Clear Separation**: Configuration → Service → View layer  
✅ **Self-Documenting**: Code structure is clear and intentional

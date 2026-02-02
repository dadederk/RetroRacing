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
- `LeaderboardConfigurationUniversal` (iOS/iPadOS/macOS) → `"bestios001test"`
- `LeaderboardConfigurationTvOS` → `"besttvos001"`  
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

### View Layer (SwiftUI)

**Platform Integration:**
- iOS/macOS: `MenuView` (SwiftUI) in main app target; composition root in `RetroRacingApp.swift` injects `GameCenterService` and `LeaderboardConfiguration`.
- tvOS: `tvOSMenuView` (SwiftUI) in tvOS target; composition root in `RetroRacingTvOSApp.swift`.
- watchOS: `ContentView` (SwiftUI) as main menu; `RetroRacingWatchOSApp.swift` as composition root.
- visionOS: TBD

View layer characteristics:
- Zero GameKit imports in view layer
- Only calls service methods (`leaderboardService.submitScore`, `gameCenterService.isAuthenticated`, etc.)
- Leaderboard presentation via `LeaderboardView` / `tvOSLeaderboardView` using `GKAccessPoint.shared.trigger(leaderboardID:...)` (iOS 26+ / tvOS 26+).

## Known Issues

### Game Center (iOS 26 / tvOS 26)

**Resolved:** `GKGameCenterViewController` and `GKGameCenterControllerDelegate` were deprecated in iOS 26 / tvOS 26 with replacement **GKAccessPoint**. The app now uses `GKAccessPoint.shared.trigger(leaderboardID:playerScope:timeScope:handler:)` to present the leaderboard (see `LeaderboardView.swift`, `tvOSLeaderboardView.swift`). No deprecated Game Center APIs are used on iOS/tvOS 26+.

## Testing Strategy

### Unit Tests (Priority)

**Configuration Tests:**
```swift
func testConfigurationReturnsCorrectLeaderboardID() {
    let config = LeaderboardConfigurationUniversal()
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

**View/Integration Tests with Mock Service:**
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
    // Inject into MenuView/GameView or game-over flow; assert mockService.submittedScores
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
// In app entry (e.g. RetroRacingApp or platform App struct):
let config = macOSLeaderboardConfiguration()
let service = GameCenterService(configuration: config)
MenuView(
    leaderboardService: service,
    gameCenterService: service,
    // ... other injected dependencies
)
```

3. **Done!** No changes to `GameCenterService` required.

## Benefits Achieved

✅ **Dependency Injection**: All dependencies passed explicitly, no hidden globals  
✅ **Zero Compiler Flags**: Configuration injected, service platform-agnostic  
✅ **Maximum Code Reuse**: View controllers/views share identical logic  
✅ **Testability**: Easy to mock with protocol-based design  
✅ **Clear Separation**: Configuration → Service → View layer  
✅ **Self-Documenting**: Code structure is clear and intentional

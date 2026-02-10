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

**Platform Implementations (sandbox IDs):**
- `LeaderboardConfigurationUniversal` (iPhone) → `"bestios001test"`
- `LeaderboardConfigurationIPad` (iPadOS) → `"bestipad001test"`
- `LeaderboardConfigurationMac` (macOS) → `"bestmacos001test"`  
- `LeaderboardConfigurationTvOS` → `"besttvos001"`  
- `watchOSLeaderboardConfiguration` → `"bestwatchos001test"`
- `visionOSLeaderboardConfiguration` → `"bestvision001test"` (optional)

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
- watchOS: `ContentView` (SwiftUI) as main menu; `RetroRacingWatchOSApp.swift` as composition root. `GameCenterService` is injected with `LeaderboardConfigurationWatchOS`; `WatchGameView` calls `leaderboardService.submitScore(score)` on game over so watch scores appear on the watch leaderboard in App Store Connect. No Leaderboard button on menu; leaderboard info is in Settings.
- visionOS: TBD

View layer characteristics:
- Zero GameKit imports in most of the view layer (except the dedicated shared `LeaderboardView` wrapper)
- Only calls service methods (`leaderboardService.submitScore`, `gameCenterService.isAuthenticated`, etc.)
- Leaderboard presentation:
  - iOS / tvOS: via `LeaderboardView` using `GKAccessPoint.shared.trigger(leaderboardID:...)` (iOS 26+ / tvOS 26+)
  - macOS: via `LeaderboardView` wrapping `GKGameCenterViewController` in `NSViewControllerRepresentable` so the sheet dismisses cleanly
  - watchOS: no in-app leaderboard UI (Apple does not provide a watch-appropriate leaderboard sheet). Scores are submitted to Game Center via the same `GameCenterService` and `LeaderboardConfiguration` (watch ID `bestwatchos001test`). Users see “Scores are submitted to Game Center. View leaderboards on iPhone or iPad.” in Settings.

## Known Issues

### Game Center (iOS 26 / tvOS 26)

**Resolved:** `GKGameCenterViewController` and `GKGameCenterControllerDelegate` were deprecated in iOS 26 / tvOS 26 with replacement **GKAccessPoint**. The app now uses `GKAccessPoint.shared.trigger(leaderboardID:playerScope:timeScope:handler:)` to present the leaderboard on iOS/tvOS (see `LeaderboardView.swift`, `tvOSLeaderboardView.swift`). On macOS, the app uses `GKGameCenterViewController` wrapped in SwiftUI, which remains supported.

### Localization for Score Units

- English-only for sandbox: score suffix singular `overtake`, plural `Overtakes`. Applied to every leaderboard localization in App Store Connect (set + boards). Add ES/CA later for production.

### Debugging score submission

- All leaderboard/Game Center logs use the 🏆 emoji (and `AppLog.leaderboard`). Filter console or logs by `🏆` to see: score submit attempts, “player not authenticated” skips, success, or failure with error message. Useful for diagnosing watch scores not appearing on the leaderboard.

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

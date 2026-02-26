# Leaderboard Implementation

## Overview

Game Center leaderboard system with dependency injection, zero compiler flags in services, and maximum code reuse across platforms.

**Scope:** Leaderboards are **per platform** (iOS, iPad, macOS, tvOS, watchOS) and **per level** (Cruise, Fast, Rapid). We do not use separate leaderboards for assistive technologies (e.g. VoiceOver); all users compete on the same per-platform, per-level leaderboards.

**Speed pacing mapping (current):**
- `Rapid` (default): baseline game speed (`initialInterval: 0.6`)
- `Fast`: middle pace between Rapid and Cruise (`initialInterval: 0.96`)
- `Cruise`: slowest pace (`initialInterval: 1.44`)

**App Store Connect status:** Leaderboards are created for **iPhone, iPad, macOS, watchOS** (three per platform: Cruise, Fast, Rapid). **tvOS** and **visionOS** leaderboards are deferred for a later release; the app still has configuration for those platforms (IDs in code), so when you create those leaderboards in ASC later, no code change is needed.

## Architecture

### Configuration Layer

**`LeaderboardConfiguration` Protocol**
```swift
protocol LeaderboardConfiguration {
    func leaderboardID(for difficulty: GameDifficulty) -> String
}
```

**Platform Implementations (sandbox IDs per speed):**
- iPhone (`LeaderboardConfigurationUniversal`)
  - Cruise → `bestios001cruise`
  - Fast → `bestios001fast`
  - Rapid → `bestios001test`
- iPad (`LeaderboardConfigurationIPad`)
  - Cruise → `bestipad001cruise`
  - Fast → `bestipad001fast`
  - Rapid → `bestipad001test`
- macOS (`LeaderboardConfigurationMac`)
  - Cruise → `bestmacos001cruise`
  - Fast → `bestmacos001fast`
  - Rapid → `bestmacos001test`
- tvOS (`LeaderboardConfigurationTvOS`)
  - Cruise → `besttvos001cruise`
  - Fast → `besttvos001fast`
  - Rapid → `besttvos001`
- watchOS (`LeaderboardConfigurationWatchOS`)
  - Cruise → `bestwatchos001cruise`
  - Fast → `bestwatchos001fast`
  - Rapid → `bestwatchos001test`

### Service Layer

**`LeaderboardService` Protocol**
```swift
protocol LeaderboardService {
    func submitScore(_ score: Int, difficulty: GameDifficulty)
    func isAuthenticated() -> Bool
    func fetchLocalPlayerBestScore(for difficulty: GameDifficulty) async -> Int?
}
```

**`GameCenterService` Implementation**
- Accepts `LeaderboardConfiguration` via initializer
- Accepts injected build-mode flag (`isDebugBuild`) via initializer
- **No compiler flags** for platform detection
- Handles all Game Center authentication and presentation
- Manages view controller lifecycle and delegation
- Fetches and submits against the leaderboard mapped to the selected speed level
- Skips `submitScore(_:difficulty:)` in debug builds so sandbox/development runs do not post scores

### Best-Score Sync

- `BestScoreSyncService` syncs local best score from Game Center when available:
  - Resolves the currently selected speed (`selectedDifficulty`)
  - Calls `leaderboardService.fetchLocalPlayerBestScore(for:)`
  - Calls `highestScoreStore.syncFromRemote(bestScore:for:)` when a remote value exists
- Sync timing:
  - On app startup (`.task`)
  - On Game Center authentication state change callbacks
- Scope:
  - Leaderboards remain **per platform + speed** (Cruise/Fast/Rapid for each platform)
  - Best score sync is per active platform/speed leaderboard, not cross-platform-global

### View Layer (SwiftUI)

**Platform Integration:**
- iOS/macOS: `MenuView` (SwiftUI) in main app target; composition root in `RetroRacingApp.swift` injects `GameCenterService` and `LeaderboardConfiguration`.
- tvOS: `tvOSMenuView` (SwiftUI) in tvOS target; composition root in `RetroRacingTvOSApp.swift`.
- watchOS: `ContentView` (SwiftUI) as main menu; `RetroRacingWatchOSApp.swift` as composition root. `GameCenterService` is injected with `LeaderboardConfigurationWatchOS`; `WatchGameView` calls `leaderboardService.submitScore(score, difficulty:)` on game over so scores land on the selected speed leaderboard. No Leaderboard button on menu; leaderboard info is in Settings.
- visionOS: TBD

View layer characteristics:
- Zero GameKit imports in most of the view layer (exceptions: leaderboard presentation surfaces such as `LeaderboardView` and macOS menu trigger).
- Only calls service methods (`leaderboardService.submitScore(_:difficulty:)`, `gameCenterService.isAuthenticated`, etc.)
- `MenuAuthModel.startAuthentication(startedByUser:)` runs on macOS as well (not only UIKit platforms) so `GKLocalPlayer.authenticateHandler` is registered and shared score submit/best-sync paths can observe authenticated state.
- Leaderboard presentation:
  - iOS / tvOS / macOS leaderboard button resolves the selected speed and opens that leaderboard ID
  - iOS / tvOS: via `LeaderboardView` using `GKAccessPoint.shared.trigger(leaderboardID:...)` (iOS 26+ / tvOS 26+)
  - macOS: direct `GKAccessPoint.shared.trigger(leaderboardID:...)` call from menu action (no placeholder SwiftUI sheet wrapper)
  - watchOS: no in-app leaderboard UI (Apple does not provide a watch-appropriate leaderboard sheet). Scores are submitted to Game Center via the same `GameCenterService` and `LeaderboardConfiguration` (watch ID `bestwatchos001test`). Users see “Scores are submitted to Game Center. View leaderboards on iPhone or iPad.” in Settings.

## App Store Connect: Create leaderboards

Create one Classic leaderboard in App Store Connect for each **Leaderboard ID** the app uses. The app submits scores to the ID returned by `LeaderboardConfiguration.leaderboardID(for: difficulty)` per platform. IDs are **case-sensitive** and must match exactly.

### Steps

1. **App Store Connect** → [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps** → your app.
2. **Game Center** → In the app's sidebar: **Services** → **Game Center** (or **App** → **Game Center**).
3. **Leaderboards** → Under Game Center, open **Leaderboards**.
4. **Leaderboard Set (optional)**  
   Create a **Leaderboard Set** (e.g. "RetroRacing Leaderboards") if you want one entry that groups Cruise / Fast / Rapid. Add leaderboards to the set. Otherwise create **Classic Leaderboards** directly.
5. **Create each leaderboard**  
   For each ID below (or each platform × difficulty you ship):
   - Click **+** / **Add Leaderboard**.
   - **Type:** Classic.
   - **Reference Name:** Internal only (e.g. "iOS Cruise", "watchOS Rapid").
   - **Leaderboard ID:** Copy exactly from the table below (e.g. `bestios001cruise`). Do not change case or spelling.
   - **Score format:** Integer; submission type **Best** (highest score wins).
   - **Localization:** Add at least one language; set **Display Name** (e.g. "Cruise", "Fast", "Rapid") and **Score Format** (e.g. "%d Overtakes").
6. **Version / build**  
   Ensure the build is attached to a version with **Game Center** enabled and the correct leaderboard set selected (if using a set).

### Leaderboard IDs (must match app config)

| Platform | Cruise | Fast | Rapid |
| -------- | ------ | ---- | ----- |
| iPhone | `bestios001cruise` | `bestios001fast` | `bestios001test` |
| iPad | `bestipad001cruise` | `bestipad001fast` | `bestipad001test` |
| macOS | `bestmacos001cruise` | `bestmacos001fast` | `bestmacos001test` |
| tvOS | `besttvos001cruise` | `besttvos001fast` | `besttvos001` |
| watchOS | `bestwatchos001cruise` | `bestwatchos001fast` | `bestwatchos001test` |

Create only the leaderboards for platforms you ship (e.g. if you ship iPhone + watchOS, create the six IDs for those two rows). If you change an ID in the app's `LeaderboardConfiguration`, create a new leaderboard in App Store Connect with that ID and retire or leave the old one unused.

## Known Issues

### Game Center (iOS 26 / tvOS 26)

**Resolved:** `GKGameCenterViewController` and `GKGameCenterControllerDelegate` were deprecated in iOS 26 / tvOS 26 with replacement **GKAccessPoint**. The app now uses `GKAccessPoint.shared.trigger(leaderboardID:playerScope:timeScope:handler:)` to present leaderboards on iOS/tvOS and macOS.

### Localization for Score Units

- English-only for sandbox: score suffix singular `overtake`, plural `Overtakes`. Applied to every leaderboard localization in App Store Connect (set + boards). Add ES/CA later for production.

### Debugging score submission

- All leaderboard/Game Center logs use the 🏆 emoji (and `AppLog.leaderboard`). Filter console or logs by `🏆` to see: score submit attempts, “player not authenticated” skips, success, or failure with error message. Useful for diagnosing watch scores not appearing on the leaderboard.
- On successful submit, `GameCenterService` performs a read-after-write verification (`fetchLocalPlayerBestScore(for:)`) and logs the verified remote best value when available.
- Leaderboard load logs now include metadata (`releaseState`, `isHidden`, `activityIdentifier`) to diagnose App Store Connect visibility/configuration mismatches.
- Debug builds intentionally log `Skipped score submit ... debug build` and do not post scores to Game Center.

## Testing Strategy

### Unit Tests (Priority)

**Configuration Tests:**
```swift
func testConfigurationReturnsCorrectLeaderboardID() {
    let config = LeaderboardConfigurationUniversal()
    XCTAssertEqual(config.leaderboardID(for: .cruise), "bestios001cruise")
    XCTAssertEqual(config.leaderboardID(for: .fast), "bestios001fast")
    XCTAssertEqual(config.leaderboardID(for: .rapid), "bestios001test")
}
```

**Service Tests with Mock Configuration:**
```swift
struct MockLeaderboardConfiguration: LeaderboardConfiguration {
    func leaderboardID(for difficulty: GameDifficulty) -> String {
        switch difficulty {
        case .cruise: return "test_cruise"
        case .fast: return "test_fast"
        case .rapid: return "test_rapid"
        }
    }
}

func testServiceUsesInjectedConfiguration() {
    let mockConfig = MockLeaderboardConfiguration()
    let service = GameCenterService(configuration: mockConfig)
    // Test service behavior
}
```

**View/Integration Tests with Mock Service:**
```swift
final class MockLeaderboardService: LeaderboardService {
    var submittedScores: [Int] = []
    var authenticated = true
    
    func submitScore(_ score: Int, difficulty: GameDifficulty) {
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

## watchOS Implementation

watchOS uses Game Center but has critical platform-specific differences:

```swift
// RetroRacingWatchOSApp.swift
@main
struct RetroRacingWatchOSApp: App {
    private let leaderboardService: GameCenterService
    
    init() {
        // Initialize service with no authentication presenter (watchOS has no UI for this)
        let configuration = LeaderboardConfigurationWatchOS()
        leaderboardService = GameCenterService(
            configuration: configuration,
            authenticationPresenter: nil,
            authenticateHandlerSetter: nil
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(leaderboardService: leaderboardService, ...)
                .onAppear {
                    setupGameCenterAuthentication {
                        Task { await bestScoreSyncService.syncIfPossible() }
                    }
                    Task { await bestScoreSyncService.syncIfPossible() }
                }
        }
    }
    
    private func setupGameCenterAuthentication(onAuthStateChanged: @escaping () -> Void) {
        // CRITICAL: watchOS authenticateHandler signature differs from iOS/tvOS/macOS
        // iOS/tvOS/macOS: (UIViewController?, Error?) -> Void
        // watchOS:        (Error?) -> Void (no view controller parameter)
        GKLocalPlayer.local.authenticateHandler = { error in
            if let error = error {
                AppLog.error(AppLog.game + AppLog.leaderboard, "🏆 watchOS Game Center authentication error: \(error.localizedDescription)")
                onAuthStateChanged()
                return
            }
            if GKLocalPlayer.local.isAuthenticated {
                AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS Game Center authenticated successfully - player: \(GKLocalPlayer.local.displayName)")
            } else {
                AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS Game Center authentication handler called, but player not authenticated")
            }
            onAuthStateChanged()
        }
    }
}

// WatchGameView.swift  
func handleGameOver() {
    let finalScore = gameScene?.gameState.score ?? 0
    leaderboardService.submitScore(finalScore, difficulty: selectedDifficulty)
}
```

**Key watchOS differences:**
- **Authentication handler signature**: watchOS only takes `Error?` (no view controller parameter)
- Authentication setup happens in `onAppear` rather than via `authenticateHandlerSetter` closure
- Best-score sync is triggered from auth-state callbacks and `GKPlayerAuthenticationDidChangeNotificationName` updates so late auth transitions still refresh local best.
- On `GKErrorGameUnrecognized` (code 15), watchOS performs bounded retry attempts with delay before giving up, because this error can occur transiently at launch.
- No in-app leaderboard UI (users view leaderboards on iPhone/iPad)
- Settings view displays conditional text based on authentication status
- Score submission happens automatically on game over

**Debugging score submission:**

Use the 🏆 emoji to filter logs:
```bash
# Watch logs for authentication
log stream --predicate 'eventMessage CONTAINS "🏆"' --level debug

# Common issues:
# - "player not authenticated" → User must sign in to Game Center on paired iPhone
# - "authentication error" → Check Game Center capability in Xcode project
```

## Migration Guide

To add a new platform:

1. **Create Configuration**
```swift
// RetroRacing macOS/Configuration/macOSLeaderboardConfiguration.swift
struct macOSLeaderboardConfiguration: LeaderboardConfiguration {
    func leaderboardID(for difficulty: GameDifficulty) -> String {
        switch difficulty {
        case .cruise: return "bestmacos001cruise"
        case .fast: return "bestmacos001fast"
        case .rapid: return "bestmacos001test"
        }
    }
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

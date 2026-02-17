# Testing Requirements

## Testing Philosophy

RetroRacing follows a **unit-test-first** approach with comprehensive coverage of business logic, models, and services.

## Testing Strategy

### Unit Tests (Priority)

**Target:** ⚠️ **ALWAYS run unit tests after code changes** — tests must pass

**Build flags:** All schemes compile with `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor` and `SWIFT_STRICT_CONCURRENCY=targeted`. Keep tests green under these flags; raise to `complete` once warnings are zero.

```bash
cd RetroRacing && xcrun xcodebuild test -scheme RetroRacingSharedTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```
For app-level tests (RetroRacingUniversal): `-scheme RetroRacingUniversalTests`

**Focus Areas:**
- Game logic (`GridStateCalculator`, `GameState`, `GridState`)
- Services (mocked protocol implementations)
- Configuration objects
- Utilities and extensions
- Accessibility audio behavior (retro vs cue-mode routing, move-cue style routing, conditional-default overrides)
- Difficulty timing behavior (clear pacing separation for cruise/fast/rapid and conditional-default wiring)

### UI Tests (Future)

Not implemented yet. Focus on unit tests for now.

### Integration Tests (Future)

Not implemented yet. Consider for:
- Game Center sandbox testing
- StoreKit sandbox testing

## Testing Conventions

### Test Naming Convention

Use `testGivenWhenThen` format in **camelCase** (no underscores):

- **Given** describes the initial state/context
- **When** describes the action/trigger
- **Then** describes the **specific expected outcome** (be concrete, not generic)

❌ **Avoid generic outcomes**: `returnsTheExpectedValue`, `isCorrect`, `worksAsExpected`  
✅ **Use specific outcomes**: `scoreIsSentToLeaderboard`, `playerMovesLeft`, `sectionIsHidden`

### Test Structure

Use `// Given`, `// When`, `// Then` comments with **no extra explanations**:

```swift
func testGivenUserIsAuthenticatedWhenSubmittingScoreThenScoreIsSentToLeaderboard() {
    // Given
    let mockLeaderboard = MockLeaderboardService()
    mockLeaderboard.authenticated = true
    let viewController = GameViewController(leaderboardService: mockLeaderboard)
    
    // When
    viewController.gameOver(score: 150)
    
    // Then
    XCTAssertEqual(mockLeaderboard.submittedScores, [150])
}
```

## Testing Patterns

### Protocol-Based Mocking

All services use protocols for easy mocking:

```swift
final class MockLeaderboardService: LeaderboardService {
    var submittedScores: [Int] = []
    var authenticated = true
    
    func submitScore(_ score: Int) {
        if authenticated {
            submittedScores.append(score)
        }
    }
    
    func isAuthenticated() -> Bool {
        return authenticated
    }
}
```

### Testing Game Logic

Game logic should be pure and deterministic:

```swift
func testGivenPlayerInCenterWhenMovingLeftThenPlayerMovesToLeftColumn() {
    // Given
    let calculator = GridStateCalculator()
    let initialState = GridState(numberOfRows: 5, numberOfColumns: 3)
    
    // When
    let (newState, effects) = calculator.nextGrid(
        previousGrid: initialState,
        actions: [.moveCar(direction: .left)]
    )
    
    // Then
    XCTAssertEqual(newState.playerColumn, initialState.playerColumn - 1)
    XCTAssertEqual(effects, [])
}

func testGivenPlayerInSameColumnAsCarWhenUpdatingGridThenCrashEffectIsTriggered() {
    // Given
    let calculator = GridStateCalculator()
    var state = GridState(numberOfRows: 5, numberOfColumns: 3)
    state.grid[0][1] = .Player
    state.grid[1][1] = .Car
    
    // When
    let (newState, effects) = calculator.nextGrid(
        previousGrid: state,
        actions: [.update]
    )
    
    // Then
    XCTAssertTrue(effects.contains(where: { 
        if case .crashed = $0 { return true }
        return false
    }))
}
```

### Testing Configuration

```swift
func testGivenUniversalConfigurationWhenAccessingLeaderboardIDThenReturnsIOSLeaderboardID() {
    // Given
    let config = LeaderboardConfigurationUniversal()
    
    // When
    let leaderboardID = config.leaderboardID
    
    // Then
    XCTAssertEqual(leaderboardID, "bestios001test")
}

func testGivenTvOSConfigurationWhenAccessingLeaderboardIDThenReturnsTvOSLeaderboardID() {
    // Given
    let config = LeaderboardConfigurationTvOS()
    
    // When
    let leaderboardID = config.leaderboardID
    
    // Then
    XCTAssertEqual(leaderboardID, "besttvos001")
}
```

### Testing Theme System (Future)

```swift
func testGivenPocketThemeWhenGettingColorsForStateThenReturnsPocketPalette() {
    // Given
    let pocketTheme = PocketTheme()
    let state = GameState()
    
    // When
    let colors = pocketTheme.colors(for: state)
    
    // Then
    XCTAssertEqual(colors.background, Color(red: 0.608, green: 0.737, blue: 0.059))
    XCTAssertEqual(colors.foreground, Color(red: 0.059, green: 0.220, blue: 0.059))
}

func testGivenLockedPremiumThemeWhenUnlockingThemeThenThemeBecomesAvailable() {
    // Given
    let manager = ThemeManager()
    XCTAssertFalse(manager.isThemeAvailable(.lcd))
    
    // When
    manager.unlockTheme(.lcd)
    
    // Then
    XCTAssertTrue(manager.isThemeAvailable(.lcd))
}
```

## Test Organization

```
RetroRacingTests/
├── GameLogic/
│   ├── GridStateCalculatorTests.swift
│   ├── GameStateTests.swift
│   └── GridStateTests.swift
├── Services/
│   ├── LeaderboardServiceTests.swift
│   ├── RatingServiceTests.swift
│   └── ThemeManagerTests.swift
├── Configuration/
│   ├── LeaderboardConfigurationTests.swift
│   └── ThemeConfigurationTests.swift
├── Utilities/
│   └── ExtensionTests.swift
└── Mocks/
    ├── MockLeaderboardService.swift
    ├── MockRatingService.swift
    └── MockThemeManager.swift
```

## Coverage Goals

**Target Coverage:**
- Game logic: 90%+ (critical path)
- Services: 80%+ (business logic)
- Configuration: 100% (simple validation)
- UI layers: Not measured (focus on unit tests)

## Testing Anti-Patterns to Avoid

❌ **Don't test private implementation details** — test public API  
❌ **Don't test UI layout** — use preview snapshots for visual regression  
❌ **Don't use real services in unit tests** — always mock protocols  
❌ **Don't write flaky tests** — avoid timing, threading, randomness  
❌ **Don't skip tests** — if a test is flaky, fix it or delete it  

## Pre-Commit Checklist

Before committing code:

1. ✅ All unit tests pass
2. ✅ New code has corresponding tests
3. ✅ Mocks are updated if protocols changed
4. ✅ No tests are disabled/skipped
5. ✅ Test names follow `testGivenWhenThen` convention (camelCase, specific outcomes)
6. ✅ Test structure uses `// Given`, `// When`, `// Then` comments

## Continuous Integration (Future)

Consider GitHub Actions or Xcode Cloud for:
- Run tests on every PR
- Test on multiple simulator versions
- Generate coverage reports
- Block merges if tests fail

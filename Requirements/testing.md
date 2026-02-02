# Testing Requirements

## Testing Philosophy

RetroRacing follows a **unit-test-first** approach with comprehensive coverage of business logic, models, and services.

## Testing Strategy

### Unit Tests (Priority)

**Target:** ⚠️ **ALWAYS run unit tests after code changes** — tests must pass

```bash
cd RetroRacing && xcrun xcodebuild test -scheme RetroRacingSharedTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```
For app-level tests (RetroRacingUniversal): `-scheme RetroRacingUniversalTests`

**Focus Areas:**
- Game logic (`GridStateCalculator`, `GameState`, `GridState`)
- Services (mocked protocol implementations)
- Configuration objects
- Utilities and extensions

### UI Tests (Future)

Not implemented yet. Focus on unit tests for now.

### Integration Tests (Future)

Not implemented yet. Consider for:
- Game Center sandbox testing
- StoreKit sandbox testing

## Testing Patterns

### Protocol-Based Mocking

All services use protocols for easy mocking:

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
```

### Dependency Injection for Testing

Services are injected, making view controllers easy to test:

```swift
func testGameOverSubmitsScore() {
    let mockLeaderboard = MockLeaderboardService()
    let mockRating = MockRatingService()
    let viewController = GameViewController(
        leaderboardService: mockLeaderboard,
        ratingService: mockRating
    )
    
    viewController.gameOver(score: 150)
    
    XCTAssertEqual(mockLeaderboard.submittedScores, [150])
}
```

### Testing Game Logic

Game logic should be pure and deterministic:

```swift
func testPlayerMovesLeft() {
    let calculator = GridStateCalculator()
    let initialState = GridState(numberOfRows: 5, numberOfColumns: 3)
    
    let (newState, effects) = calculator.nextGrid(
        previousGrid: initialState,
        actions: [.moveCar(direction: .left)]
    )
    
    // Assert player position changed
    XCTAssertEqual(newState.playerColumn, initialState.playerColumn - 1)
    XCTAssertEqual(effects, [])
}

func testCollisionDetection() {
    let calculator = GridStateCalculator()
    var state = GridState(numberOfRows: 5, numberOfColumns: 3)
    // Set up collision scenario
    state.grid[0][1] = .Player
    state.grid[1][1] = .Car
    
    let (newState, effects) = calculator.nextGrid(
        previousGrid: state,
        actions: [.update]
    )
    
    XCTAssertTrue(effects.contains(where: { 
        if case .crashed = $0 { return true }
        return false
    }))
}
```

### Testing Configuration

```swift
func testUniversalLeaderboardConfiguration() {
    let config = LeaderboardConfigurationUniversal()
    XCTAssertEqual(config.leaderboardID, "bestios001test")
}

func testTvOSLeaderboardConfiguration() {
    let config = LeaderboardConfigurationTvOS()
    XCTAssertEqual(config.leaderboardID, "besttvos001")
}
```

### Testing Theme System (Future)

```swift
func testThemeApplication() {
    let gameBoyTheme = GameBoyTheme()
    let state = GameState()
    
    let colors = gameBoyTheme.colors(for: state)
    
    XCTAssertEqual(colors.background, Color(red: 0.608, green: 0.737, blue: 0.059))
    XCTAssertEqual(colors.foreground, Color(red: 0.059, green: 0.220, blue: 0.059))
}

func testThemeSubscription() {
    let manager = ThemeManager()
    
    XCTAssertTrue(manager.isThemeAvailable(.gameBoy))
    XCTAssertFalse(manager.isThemeAvailable(.lcd)) // Premium theme
    
    // Simulate purchase
    manager.unlockTheme(.lcd)
    
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
5. ✅ Test names are descriptive and follow convention: `test[Scenario][ExpectedBehavior]`

## Continuous Integration (Future)

Consider GitHub Actions or Xcode Cloud for:
- Run tests on every PR
- Test on multiple simulator versions
- Generate coverage reports
- Block merges if tests fail

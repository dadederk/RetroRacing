# AGENTS.md

AI Agent development guidelines for RetroRacing — A cross-platform retro racing game for all Apple platforms.

## Quick Start

**Role**: Senior iOS/Cross-Platform Engineer specializing in SwiftUI, SpriteKit, accessibility, and multi-platform development  
**Target**: iOS 26.0+, watchOS 26.0+, tvOS 26.0+, macOS 26.0+, visionOS 26.0+  
**Key Tech**: SwiftUI, SpriteKit, Game Center, StoreKit, protocol-driven architecture

### Critical Rules ⚠️

1. **ALWAYS** read requirement files in `/Requirements/` before implementing features
2. **ALWAYS** ensure the app compiles — the app must ALWAYS compile without errors
3. **ALWAYS** run unit tests after code changes — unit tests must pass
4. **ALWAYS** update/create requirement docs after changing features
5. **ALWAYS** use protocol-based dependency injection — no default instantiations in init
6. **ALWAYS** maximize code reuse — shared logic goes in `RetroRacing Shared/`
7. **NEVER** use `#if os()` flags in service layer — use configuration injection
8. **NEVER** duplicate logic between platforms — refactor to shared module
9. **NEVER** force unwrap optionals — use safe unwrapping patterns
10. **ALWAYS** use standard file headers for new Swift source files with `Created by Dani Devesa`

### Clarity & Readability ✅

- **Code should read as a sequence of instructions** — top-level methods are short and descriptive, then delegate to well-named helpers
- **Self-documenting structure** — the first screen of a method should read like a table of contents
- **Short, single-purpose functions** — prefer small units with explicit intent and outcome
- **Clear separation of concerns** — views orchestrate, services own business logic, models store state
- **Testable by design** — dependency injection, deterministic inputs/outputs, protocol-based mocking

## Project Overview

RetroRacing is a retro-style racing game built for **all Apple platforms** with a focus on:
- **True cross-platform support**: Single codebase, platform-appropriate UIs
- **Accessibility first**: Full VoiceOver support, Dynamic Type, alternative input methods
- **User customization**: Rich settings, multiple control schemes, visual themes
- **Modern Swift**: Swift 6+, latest Apple APIs, strict concurrency

### Requirements Documentation 📋

**IMPORTANT**: Before implementing any feature, read the relevant requirement files in `/Requirements/`:

- **leaderboard_implementation.md** - Game Center integration architecture
- **testing.md** - Testing strategy and requirements
- **theming_system.md** - Visual theme system and monetization
- **[Future]** game_logic.md - Core game mechanics and rules
- **accessibility.md** - Accessibility requirements per platform (Reduce Motion, VoiceOver, SpriteKit labels)
- **[Future]** input_handling.md - Control schemes per platform
- **[Future]** settings.md** - User customization options

These files contain detailed specifications, edge cases, and design decisions. **Always consult them before starting work on a feature.**

**Documentation Maintenance**: After implementing or modifying features:
- Update the relevant requirement file(s) to reflect changes
- Create new requirement files for new features
- Keep specs in sync with implementation reality
- Document any design decisions or edge cases discovered during development

### Core Architecture

```
RetroRacing/
├── RetroRacing Shared/     # Cross-platform game logic
│   ├── GameScene.swift     # SpriteKit game scene
│   ├── GameState.swift     # Game state model
│   ├── GridState.swift     # Grid logic
│   ├── GridStateCalculator.swift
│   ├── Services/           # Protocol-based services
│   │   ├── LeaderboardService.swift
│   │   ├── GameCenterService.swift
│   │   ├── RatingService.swift
│   │   └── StoreReviewService.swift
│   └── Extensions/         # Shared utilities
├── RetroRacing iOS/        # iOS-specific UI (SwiftUI)
│   ├── Views/ (GameView, MenuView, LeaderboardView)
│   └── Configuration/
│       └── LeaderboardConfigurationUniversal.swift
├── RetroRacing watchOS/    # watchOS-specific UI (SwiftUI)
│   ├── WatchGameView, ContentView
│   └── MenuView
├── RetroRacing tvOS/       # tvOS-specific UI (SwiftUI)
├── RetroRacing macOS/      # macOS-specific UI (AppKit/SwiftUI)
└── RetroRacing visionOS/   # visionOS-specific UI (SwiftUI)
```

### Key Principles

- **SwiftUI first**: Prefer SwiftUI over UIKit; avoid UIKit in shared code and in platform UI where SwiftUI is sufficient. Migration goal: use and reuse SwiftUI.
- **Protocol-Driven Design**: Abstract platform differences behind protocols
- **Configuration Injection**: Platform differences via configuration objects
- **Dependency Injection**: All dependencies passed explicitly, no defaults in init
- **Maximum Code Reuse**: Share everything possible in `RetroRacing Shared/`
- **Platform-Specific UI Only**: UI layer handles platform differences, logic is shared
- **Accessibility First**: Every feature should aim for best-effort accessibility on every platform

## Architecture Patterns

### Protocol-Based Services

Define cross-platform interfaces as protocols:

```swift
protocol LeaderboardService {
    func submitScore(_ score: Int)
    func isAuthenticated() -> Bool
}

protocol GameController {
    func moveLeft()
    func moveRight()
}
```

**Benefits:**
- Views remain platform-agnostic
- No `#if os()` compilation flags in UI layer
- Easy testing with mock implementations
- Clear separation of concerns

### Configuration Injection Pattern

Platform differences handled via configuration objects:

```swift
// Protocol defines the interface
protocol LeaderboardConfiguration {
    var leaderboardID: String { get }
}

// Universal (iOS/iPadOS/macOS) and per-platform (TvOS) configurations
struct LeaderboardConfigurationUniversal: LeaderboardConfiguration {
    let leaderboardID = "bestios001test"
}

// Service uses injected configuration (NO compiler flags)
class GameCenterService: LeaderboardService {
    private let configuration: LeaderboardConfiguration
    
    init(configuration: LeaderboardConfiguration) {
        self.configuration = configuration
    }
}
```

### Dependency Injection (No Defaults)

Services are **always injected**, never instantiated with defaults:

```swift
// ❌ BAD - Creates hidden dependency
init(leaderboardService: LeaderboardService = GameCenterService(
    configuration: LeaderboardConfigurationUniversal()
)) {
    self.leaderboardService = leaderboardService
}

// ✅ GOOD - Explicit dependency, injected from outside
init(leaderboardService: LeaderboardService) {
    self.leaderboardService = leaderboardService
}

// Instantiation happens at composition root (app delegate, scene):
let config = LeaderboardConfigurationUniversal()
let service = GameCenterService(configuration: config)
let viewController = GameViewController(leaderboardService: service)
```

**Infrastructure defaults:** For testability and clarity, **infrastructure** dependencies may use a single default when they are process-wide singletons (e.g. `UserDefaults.standard`, `SystemRandomSource()`). Business dependencies (e.g. `LeaderboardService`, `RatingService`, `GameTheme`) must always be injected with no default. Document any allowed default in the type’s doc comment.

### SpriteKit + SwiftUI Integration

Game logic lives in shared `GameScene.swift` (SpriteKit), UI wraps it per platform:

**Shared Game Scene:**
```swift
class GameScene: SKScene {
    weak var gameDelegate: GameSceneDelegate?
    private(set) var gameState = GameState()
    
    // Platform-agnostic game logic
    func start() { }
    func resume() { }
}

extension GameScene: GameController {
    func moveLeft() { /* shared logic */ }
    func moveRight() { /* shared logic */ }
}
```

**Platform Integration:**

iOS/tvOS (UIKit):
```swift
class GameViewController: UIViewController {
    private var gameScene: GameScene!
    private let leaderboardService: LeaderboardService
    
    init(leaderboardService: LeaderboardService) {
        self.leaderboardService = leaderboardService
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let skView = SKView(frame: view.bounds)
        gameScene = GameScene.newGameScene()
        gameScene.gameDelegate = self
        skView.presentScene(gameScene)
    }
}
```

watchOS (SwiftUI):
```swift
struct GameView: View {
    @State private var gameScene = GameScene(size: CGSize(width: 800, height: 600))
    @State private var rotationValue: Double = 0.0
    let leaderboardService: LeaderboardService
    
    var body: some View {
        SpriteView(scene: gameScene)
            .digitalCrownRotation($rotationValue, ...) { oldValue, newValue in
                if newValue > oldValue {
                    gameScene.moveRight()
                } else {
                    gameScene.moveLeft()
                }
            }
    }
}
```

## Input Handling Strategy

Each platform has unique input methods. **Handle at the UI layer** (SwiftUI where possible), pass commands to shared `GameController` protocol:

| Platform | Primary Input | Implementation |
|----------|---------------|----------------|
| iOS/iPadOS | Touch, Swipe, Tap | SwiftUI: transparent overlay on `SpriteView` with `DragGesture` and `onTapGesture`; no UIKit touch handling in shared `GameScene` |
| watchOS | Digital Crown, Tap, Swipe | `digitalCrownRotation`, `TapGesture`, `DragGesture` |
| tvOS | Siri Remote (swipe, click) | Focus engine, SwiftUI gestures |
| macOS | Keyboard, Mouse, Trackpad | `keyDown`, `mouseDown`, `NSGestureRecognizer` |
| visionOS | Gaze, Hand Gestures, Voice | `SpatialTapGesture`, `LookAtComponent`, accessibility actions |

**Pattern:**
- UI layer captures platform-specific input (SwiftUI-first; avoid UIKit in shared layer)
- Translates to `GameController` protocol calls (`moveLeft()`, `moveRight()`)
- `GameScene` implements `GameController` with shared logic; no platform touch/gesture code in the scene

## Swift & SwiftUI Patterns

### Modern Swift (6.2+)

- **Strict Concurrency**: Use `@MainActor`, `Sendable`, async/await
- **Value Types**: Prefer structs for models
- **Protocol Extensions**: Provide default implementations
- **Avoid Force Unwraps**: Use `guard`, `if let`, or `??`

### SwiftUI Best Practices

- **`@Observable` not `ObservableObject`**: Use new observation framework
- **Environment for DI**: Pass services via environment when appropriate
- **Semantic font consistency**: Shared SwiftUI modals and overlays must use `FontPreferenceStore` semantic fonts from environment (no hardcoded `.title`/`.body` defaults in final UI)
- **State Management**: `@State` for local, `@Environment` for shared
- **Minimal `GeometryReader`**: Use `containerRelativeFrame()` when possible

### SpriteKit Optimization

- **Texture Atlases**: Batch sprites into atlases
- **Node Reuse**: Reuse nodes instead of creating/destroying
- **Minimal `update()` Work**: Keep frame logic fast
- **Throttle Updates**: Adjust game speed based on device

## Code Organization

### Keep Files Under 200 Lines

Break complex views/services into smaller, focused pieces:

```swift
// Instead of 500-line GameViewController:
GameViewController.swift          // 150 lines - main logic
GameViewController+Input.swift    // 80 lines - input handling
GameViewController+Delegates.swift // 60 lines - delegate conformances
```

### Naming & Documentation

- **Self-documenting names**: `startGame()` not `start()`, `isGameActive` not `active`
- **Name by intent and outcome**: `submitScore()`, `authenticatePlayer()` — not implementation details
- **Avoid abbreviations** unless universally understood (e.g., URL, ID, UI)
- **Comments explain WHY, not WHAT**: `// Using SpriteKit for hardware acceleration` not `// Start game`
- Only comment when reasoning isn't obvious from code

### File Organization Pattern

```swift
// 1. Imports
import SpriteKit

// 2. Protocols
protocol GameController {
    func moveLeft()
    func moveRight()
}

// 3. Main Type
class GameScene: SKScene {
    // Properties
    private let gridCalculator = GridStateCalculator()
    weak var gameDelegate: GameSceneDelegate?
    
    // Lifecycle
    override func didMove(to view: SKView) { }
    
    // Public API
    func start() { }
    
    // Private Implementation
    private func initialiseGame() { }
}

// 4. Extensions
extension GameScene: GameController {
    func moveLeft() { }
    func moveRight() { }
}

// 5. Platform-specific extensions (ONLY when unavoidable)
#if os(iOS) || os(tvOS)
extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { }
}
#endif
```

## Accessibility Requirements

### Best-Effort Adaptability ⚠️

The game **should** aim to be as adaptive as possible across ALL dimensions (best effort):
- **Screen Sizes**: iPhone SE → iPad Pro, split-screen, slide-over
- **Dynamic Type**: XS → XXXL with layout adjustments
- **Orientation**: Portrait and landscape
- **Platform**: Native behavior per platform (iPhone, iPad, Watch, TV, Mac, Vision Pro)
- **Reduce Motion**: Respect motion preferences
- **High Contrast**: Support increased contrast modes

### Accessibility Guidelines

- **VoiceOver Labels**: All UI elements must have descriptive labels
- **VoiceOver Hints**: Only add when they provide meaningful context beyond the label
- **Dynamic Type**: Text scales with system settings, layouts adapt
- **Alternative Input**: Support switches, voice control, assistive devices
- **Visual + Audio Feedback**: Never rely on color/sound alone

### Example Patterns

```swift
// Accessibility labels for sprites
let playerSprite = SKSpriteNode(imageNamed: "playersCar")
playerSprite.accessibilityLabel = NSLocalizedString("player_car", comment: "Player's car")

// Announce score changes
func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
    scoreLabel.text = "\(score)"
    UIAccessibility.post(notification: .announcement, 
                         argument: String(localized: "score_announcement \(score)"))
}

// Respect reduced motion
if UIAccessibility.isReduceMotionEnabled {
    sprite.run(SKAction.fadeIn(withDuration: 0.2)) // Simple fade
} else {
    sprite.run(complexBouncingAnimation) // Full animation
}
```

## Theming System

RetroRacing features interchangeable visual themes. See `/Requirements/theming_system.md` for details.

**Key Points:**
- Protocol-based theme system
- Free themes: Classic, Pocket
- Premium themes: LCD, 8-Bit, Neon (IAP)
- Platform-specific recommendations (Pocket on watchOS, 8-Bit on iPad, etc.)
- Accessibility overrides for high contrast

**Implementation:**
```swift
protocol GameTheme {
    var id: String { get }
    var isPremium: Bool { get }
    func backgroundColor(for state: GameState) -> Color
    func playerCarColor() -> Color
    // ...
}

class GameScene: SKScene {
    var theme: GameTheme = ClassicTheme()
}
```

## Testing Requirements

**Full testing guidelines**: See `/Requirements/testing.md`

### Unit Tests (Priority)

⚠️ **ALWAYS run unit tests after code changes** — tests must pass

**Shared logic and services** (game logic, GameCenterService, mocks):
```bash
cd RetroRacing && xcrun xcodebuild test -scheme RetroRacingSharedTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

**App-level tests** (RetroRacingUniversal target):
```bash
cd RetroRacing && xcrun xcodebuild test -scheme RetroRacingUniversalTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

**Focus Areas:**
- Game logic (`GridStateCalculator`, `GameState`)
- Services (with mock implementations)
- Configuration objects
- Theme system

### Testing Conventions

**Test Naming:** Use `testGivenWhenThen` format in camelCase (no underscores):
- **Given** describes the initial state/context
- **When** describes the action/trigger
- **Then** describes the specific expected outcome (be concrete, not generic)

**Test Structure:** Use `// Given`, `// When`, `// Then` comments with no extra explanations:

```swift
func testGivenUserIsNotAuthenticatedWhenSubmittingScoreThenScoreIsNotSent() {
    // Given
    let mockService = MockLeaderboardService()
    mockService.authenticated = false
    let viewController = GameViewController(leaderboardService: mockService)
    
    // When
    viewController.gameOver(score: 150)
    
    // Then
    XCTAssertTrue(mockService.submittedScores.isEmpty)
}

func testGivenUserIsAuthenticatedWhenSubmittingScoreThenScoreIsSentToLeaderboard() {
    // Given
    let mockService = MockLeaderboardService()
    mockService.authenticated = true
    let viewController = GameViewController(leaderboardService: mockService)
    
    // When
    viewController.gameOver(score: 150)
    
    // Then
    XCTAssertEqual(mockService.submittedScores, [150])
}
```

### Testing Pattern: Protocol Mocking

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

### Coverage Goals

- Game logic: 90%+ (critical path)
- Services: 80%+ (business logic)
- Configuration: 100% (simple validation)
- UI layers: Not measured (focus on unit tests)

## Localization

### String Management

- **ALL user-facing text** in `Localizable.xcstrings`
- **Supported Languages**: English, Spanish (Spain), Catalan (Valencian Meridional)
- **Spanish/Catalan**: Use present perfect tense for error messages
- **Catalan dialect**: Follow Valencian Meridional (valencià meridional) guidelines

```swift
// Code
Text("game_over_title")
Button("start_game") { }

// Localizable.xcstrings
{
  "game_over_title": {
    "en": "Game Over",
    "es": "Fin del Juego",
    "ca": "Joc Finalitzat"
  }
}
```

## Performance Considerations

### SpriteKit Optimization

```swift
// ❌ BAD: Creating nodes every frame
private func updateGrid() {
    let sprite = SKSpriteNode(imageNamed: "playersCar")
    addChild(sprite)
}

// ✅ GOOD: Reuse node pool
private var spritePool = [SKSpriteNode]()

private func updateGrid() {
    let sprite = spritePool.popLast() ?? SKSpriteNode(imageNamed: "playersCar")
    addChild(sprite)
}
```

### Platform-Specific

- **watchOS**: Minimize CPU usage, respect battery constraints
- **tvOS**: Optimize for 4K rendering
- **visionOS**: Balance 3D rendering with thermal limits

## Common Patterns to Follow

### ✅ DO

- **Share code aggressively**: If logic is platform-agnostic, put it in `Shared/`
- **Use protocols for abstraction**: Services, delegates, configurations
- **Inject dependencies explicitly**: No defaults in init parameters
- **Test with mocks**: Protocol-based design enables easy testing
- **Handle errors gracefully**: Log, report to user, don't crash
- **Log with emoji prefixes**: Use `AppLog` (🖼️ assets, 🔊 sound, 🔤 font, 🌐 localization, 🎨 theme, 🎮 game); concatenate when a log touches multiple features (e.g. `AppLog.assets + AppLog.sound`) so logs are easy to filter and visualise
- **Respect user preferences**: Accessibility, motion, sound
- **Document non-obvious code**: Explain "why", not "what"
- **Run tests after changes**: Unit tests must always pass

### ❌ DON'T

- **Duplicate logic**: If copying code between platforms, refactor to `Shared/`
- **Hardcode platform differences**: Use configuration injection instead
- **Use force unwraps**: Always safely unwrap optionals
- **Ignore accessibility**: Every feature should aim for best-effort accessibility
- **Skip platform testing**: Test on physical devices when possible
- **Hardcode strings**: Use localization from day one
- **Overuse `#if os()`**: Minimize compilation flags (only for fundamentally different APIs)
- **Add defaults to init**: Pass dependencies explicitly from composition root
- **Skip tests**: Tests must pass before committing

## Things to Avoid ❌

1. Default parameters in initializers — inject dependencies explicitly
2. Keyword-based platform detection — use configuration injection
3. Force unwraps — use safe unwrapping
4. Conditional statements in core code for platform differences — use protocols
5. Calculating the same thing multiple times — single source of truth
6. Skipping tests — they must pass
7. Views over 200 lines — split into smaller pieces
8. `ObservableObject` — use `@Observable` instead
9. Custom solutions when native APIs exist — use Apple frameworks first

## File Locations Reference

- **Requirements**: `/Requirements/` directory (detailed specs for each feature)
- **Shared Code**: `RetroRacing/RetroRacing Shared/`
- **Services**: `RetroRacing/RetroRacing Shared/Services/`
- **Platform UIs**: `RetroRacing/RetroRacing [Platform]/`
- **Tests**: `RetroRacing/RetroRacingUniversalTests/`, `RetroRacing/RetroRacingSharedTests/`
- **Localization**: `RetroRacing/RetroRacing Shared/Localizable.xcstrings`

## Getting Started Checklist

When working on this project:

1. ✅ **Read the relevant requirement files** in `/Requirements/` FIRST
   - These contain detailed specs, edge cases, and design decisions
2. ✅ Check if code can be shared — put in `RetroRacing Shared/` if platform-agnostic
3. ✅ Follow architecture principles above
4. ✅ Ensure best-effort accessibility and adaptability
5. ✅ Write unit tests for new functionality
6. ✅ Run tests after changes — they must pass
7. ✅ Use protocol-based dependency injection (no defaults)
8. ✅ Minimize `#if os()` flags (configuration injection instead)
9. ✅ Add SwiftUI previews for all views
10. ✅ Verify adaptability across all dimensions
11. ✅ **Update or create requirement files** after making changes

## Key Technologies

- **SwiftUI**: Modern declarative UI (watchOS, visionOS, macOS, iOS/tvOS optional)
- **UIKit**: iOS/tvOS view controllers (legacy, but works)
- **AppKit**: macOS (if not using SwiftUI)
- **SpriteKit**: Game rendering (shared across all platforms)
- **Game Center**: Leaderboards and achievements
- **StoreKit**: In-app purchases (theme unlocks)
- **Swift 6+**: Latest language features, strict concurrency

## Example Workflow: Adding a New Feature

**Feature:** Add power-up system

### 1. Create Requirement Document

Create `/Requirements/power_ups.md` with:
- Feature overview
- Power-up types
- Game logic changes
- UI requirements per platform
- Testing strategy

### 2. Define Shared Logic

```swift
// RetroRacing Shared/PowerUp.swift
enum PowerUpType {
    case speedBoost
    case shield
    case extraLife
}

struct PowerUp {
    let type: PowerUpType
    let position: GridPosition
}

protocol PowerUpDelegate: AnyObject {
    func didCollectPowerUp(_ powerUp: PowerUp)
}
```

### 3. Update GameScene (Shared)

```swift
class GameScene: SKScene {
    weak var powerUpDelegate: PowerUpDelegate?
    
    private func handlePowerUpCollection(_ powerUp: PowerUp) {
        powerUpDelegate?.didCollectPowerUp(powerUp)
        
        switch powerUp.type {
        case .speedBoost: gameState.speed *= 1.5
        case .shield: gameState.hasShield = true
        case .extraLife: gameState.lives += 1
        }
    }
}
```

### 4. Platform UI Updates

**iOS/tvOS:**
```swift
extension GameViewController: PowerUpDelegate {
    func didCollectPowerUp(_ powerUp: PowerUp) {
        showPowerUpIndicator(powerUp.type)
        UIAccessibility.post(notification: .announcement, 
                             argument: String(localized: "collected_\(powerUp.type)"))
    }
}
```

**watchOS:**
```swift
struct GameView: View {
    @State private var activePowerUps: [PowerUpType] = []
    
    var body: some View {
        VStack {
            SpriteView(scene: gameScene)
            PowerUpIndicatorView(powerUps: activePowerUps)
        }
    }
}
```

### 5. Write Tests

```swift
func testGivenPowerUpOnGridWhenUpdatingThenPowerUpIsCollected() {
    // Given
    let calculator = GridStateCalculator()
    var state = GridState(numberOfRows: 5, numberOfColumns: 3)
    state.addPowerUp(.extraLife, at: GridPosition(row: 2, column: 1))
    
    // When
    let (newState, effects) = calculator.nextGrid(previousGrid: state, actions: [.update])
    
    // Then
    XCTAssertTrue(effects.contains(where: { 
        if case .collectedPowerUp(.extraLife) = $0 { return true }
        return false
    }))
}
```

### 6. Update Requirement Doc

Document implementation decisions, edge cases discovered, testing results.

---

**Version**: 1.1  
**Last Updated**: 2026-02-03  
**References**: Apple HIG, Swift 6.2 docs, Xarra AGENTS.md, Requirements/concurrency.md

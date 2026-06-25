# Agent Pattern Examples

## Purpose

Optional examples for RetroRapid architecture patterns that are easy to get wrong. Requirement contracts and nearby code take precedence; do not load this file for routine changes.

## Protocol-Based Services

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

## Configuration Injection

```swift
protocol LeaderboardConfiguration {
    var leaderboardID: String { get }
}

struct LeaderboardConfigurationUniversal: LeaderboardConfiguration {
    let leaderboardID = "bestios001test"
}

class GameCenterService: LeaderboardService {
    private let configuration: LeaderboardConfiguration

    init(configuration: LeaderboardConfiguration) {
        self.configuration = configuration
    }
}
```

## Dependency Injection (No Defaults)

```swift
// BAD — hidden dependency
init(leaderboardService: LeaderboardService = GameCenterService(
    configuration: LeaderboardConfigurationUniversal()
)) {
    self.leaderboardService = leaderboardService
}

// GOOD — explicit dependency from composition root
init(leaderboardService: LeaderboardService) {
    self.leaderboardService = leaderboardService
}

let config = LeaderboardConfigurationUniversal()
let service = GameCenterService(configuration: config)
let viewController = GameViewController(leaderboardService: service)
```

Infrastructure singletons (`UserDefaults.standard`, `SystemRandomSource()`) may use a documented default when process-wide.

## SpriteKit + SwiftUI Integration

**Shared game scene:**

```swift
class GameScene: SKScene {
    weak var gameDelegate: GameSceneDelegate?
    private(set) var gameState = GameState()

    func start() { }
    func resume() { }
}

extension GameScene: GameController {
    func moveLeft() { /* shared logic */ }
    func moveRight() { /* shared logic */ }
}
```

**watchOS (SwiftUI):**

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

Input is captured in the UI layer and translated to `GameController` calls — no platform touch code in the shared scene.

## Theming Protocol

```swift
protocol GameTheme {
    var id: String { get }
    var isPremium: Bool { get }
    func backgroundColor(for state: GameState) -> Color
    func playerCarColor() -> Color
}

class GameScene: SKScene {
    var theme: GameTheme = ClassicTheme()
}
```

See `Requirements/theming_system.md` for shipped behavior.

## Testing Pattern: Protocol Mocking

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

## Example Workflow: Adding a Feature

**Feature:** Power-up system

1. Create `Requirements/power_ups.md` with overview, types, logic changes, per-platform UI, and testing strategy.
2. Define shared types in `RetroRacingShared/`:

```swift
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

3. Update `GameScene` with shared collection logic.
4. Platform UI announces collection (e.g. `UIAccessibility.post` on iOS).
5. Write `testGivenWhenThen` unit tests for grid/collection behavior.
6. Update the requirement doc with implementation decisions and edge cases.

## SpriteKit Node Reuse

```swift
// BAD — creating nodes every frame
private func updateGrid() {
    let sprite = SKSpriteNode(imageNamed: "playersCar")
    addChild(sprite)
}

// GOOD — reuse node pool
private var spritePool = [SKSpriteNode]()

private func updateGrid() {
    let sprite = spritePool.popLast() ?? SKSpriteNode(imageNamed: "playersCar")
    addChild(sprite)
}
```

## File Organization Pattern

```swift
// 1. Imports
import SpriteKit

// 2. Protocols
protocol GameController {
    func moveLeft()
    func moveRight()
}

// 3. Main type
class GameScene: SKScene {
    private let gridCalculator = GridStateCalculator()
    weak var gameDelegate: GameSceneDelegate?

    override func didMove(to view: SKView) { }
    func start() { }
    private func initialiseGame() { }
}

// 4. Extensions
extension GameScene: GameController {
    func moveLeft() { }
    func moveRight() { }
}

// 5. Platform extensions only at boundaries
#if os(iOS) || os(tvOS)
extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { }
}
#endif
```

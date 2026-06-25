---
name: retrorapid-conventions
description: >-
  Project conventions and architecture for RetroRapid (RetroRacing repo) —
  cross-platform SwiftUI + SpriteKit game. Use when writing, reviewing, or
  refactoring shared or platform UI code; when adding services, themes, or
  input handling; or when asked about DI, logging, localization, or repository
  scripts in `Scripts/`. For SwiftUI, concurrency, accessibility, or testing
  use the dedicated skills instead.
disable-model-invocation: true
---

# RetroRapid Project Conventions

## Project Context

- **Product**: RetroRapid! (repo folder: `RetroRacing`).
- **Platforms**: iPhone/iPad/macOS and Watch shipping; tvOS/visionOS built with different public status.
- **Stack**: SwiftUI, SpriteKit, Game Center, StoreKit, protocol-driven architecture.
- **Shared code**: `RetroRacing/RetroRacingShared/`.

### Module layout

```
RetroRacing/
├── RetroRacingShared/        # Cross-platform game logic
│   ├── GameScene.swift       # SpriteKit game scene
│   ├── GameState.swift       # Game state model
│   ├── GridState.swift       # Grid logic
│   ├── Services/             # Protocol-based services
│   └── Extensions/
├── RetroRacingUniversal/     # iOS, iPadOS, macOS UI (SwiftUI)
├── RetroRacingWatchOS/       # watchOS UI (SwiftUI)
├── RetroRacingTvOS/          # tvOS UI (SwiftUI)
├── RetroRacingVisionOS/      # visionOS UI (SwiftUI)
└── Scripts/                  # Repository automation (Swift package)
```

### Key principles

- **SwiftUI first** — prefer SwiftUI over UIKit; avoid UIKit in shared code.
- **Protocol-driven design** — abstract platform differences behind protocols.
- **Configuration injection** — platform differences via configuration objects.
- **Dependency injection** — all business dependencies passed explicitly.
- **Maximum code reuse** — share everything possible in `RetroRacingShared/`.
- **Platform-specific UI only** — UI handles platform differences; logic is shared.
- **Accessibility first** — best-effort accessibility on every platform.

---

## Requirements And Plans

- Route behavior through `Requirements/INDEX.md` before implementing features.
- Update requirement docs when behavior changes.
- Key contracts: `accessibility.md`, `testing.md`, `theming_system.md`, `input_handling.md`, `leaderboard_implementation.md`.

---

## Critical Architecture Rules

1. **Protocol-based dependency injection** — no default instantiations in `init` for business dependencies.
2. **Configuration injection** — no `#if os()` in service layer; inject platform config objects.
3. **Maximum code reuse** — platform-agnostic logic belongs in `RetroRacingShared/`.
4. **Never force-unwrap** — guard and fail safely.
5. **SwiftUI first** — prefer SwiftUI over UIKit in platform UI where sufficient.
6. **Use `@Observable`** — not `ObservableObject`, for new observation code.

Infrastructure singletons (`UserDefaults.standard`, `SystemRandomSource()`) may use a documented default when process-wide.

Code examples: `AGENTS_EXAMPLES.md` (optional; do not load routinely).

---

## Input Handling

Each platform has unique input methods. Handle at the **UI layer** (SwiftUI where possible); pass commands to shared `GameController`:

| Platform | Primary input | Implementation |
|---|---|---|
| iOS/iPadOS | Touch, swipe, tap | SwiftUI overlay on `SpriteView` with `DragGesture` / `onTapGesture` |
| watchOS | Digital Crown, tap, swipe | `digitalCrownRotation`, `TapGesture`, `DragGesture` |
| tvOS | Siri Remote | Focus engine, SwiftUI gestures |
| macOS | Keyboard, mouse, trackpad | `keyDown`, `NSGestureRecognizer` |
| visionOS | Gaze, hand gestures, voice | `SpatialTapGesture`, accessibility actions |

Pattern: UI captures input → `GameController` calls → `GameScene` implements shared logic.

See `Requirements/input_handling.md` and `Requirements/controller_input.md`.

---

## Swift & SwiftUI Patterns

- **Strict concurrency**: `@MainActor`, `Sendable`, async/await.
- **Value types**: prefer structs for models.
- **`@Observable` not `ObservableObject`** for new observation code.
- **Semantic fonts**: shared SwiftUI modals use `FontPreferenceStore` from environment — no hardcoded `.title`/`.body` defaults.
- **SpriteKit**: texture atlases, node reuse, minimal `update()` work, throttle for device class.

---

## SpriteKit + SwiftUI Integration

- Game logic lives in shared `GameScene.swift`; platform UI wraps `SpriteView` or view controllers.
- Input is captured in the UI layer and translated to `GameController` protocol calls (`moveLeft()`, `moveRight()`).
- No platform touch/gesture code in the shared scene except unavoidable platform extensions at boundaries.

---

## Theming

Protocol-based theme system. Free: Classic, Pocket. Premium (IAP): LCD, 8-Bit, Neon. Platform recommendations and accessibility overrides in `Requirements/theming_system.md`.

---

## Logging

Use structured `AppLog` events: `<emoji> <DOMAIN> <EVENT_NAME>: outcome=<state> key=value ...`

Domains include assets, sound, font, localization, theme, game, leaderboard, achievement, monetization, input, accessibility, lifecycle, store, rating. Concatenate two domains only when a log truly crosses boundaries.

---

## Localization

All user-facing text in `RetroRacingShared/Localizable.xcstrings`. Supported: English, Spanish (Spain), Catalan (Valencian Meridional). Spanish/Catalan error messages use present perfect tense.

---

## File Organization

- ~200 lines of production code per file (guideline; exclude `#Preview` blocks).
- Split by responsibility: `GameViewController+Input.swift`, etc.
- Self-documenting names; comments explain why, not what.
- Standard Swift file header with `Created by Dani Devesa` for new source files.

---

## Accessibility Conventions

Best-effort adaptability: screen sizes, Dynamic Type, orientation, Reduce Motion, high contrast.

Accessibility patterns follow the **ios-accessibility** skill. Project overlays: `.agents/skills/ios-accessibility/references/retrorapid-patterns.md`. Shipped requirements: `Requirements/accessibility.md`.

---

## Testing Conventions

- App tests (`RetroRacingShared`, `RetroRacingUniversal`): XCTest today.
- Scripts package: Swift Testing — follow **swift-testing-expert** for new script tests.
- Run after changes:

```bash
swift run --package-path Scripts run-tests
```

Test naming: `testGivenWhenThen` in camelCase with `// Given`, `// When`, `// Then` comments.

Coverage goals: game logic 90%+, services 80%+, configuration 100%. UI layers not measured.

See `Requirements/testing.md`.

---

## Do / Don't

**Do:** share code aggressively; use protocols; inject dependencies; test with mocks; log with `AppLog`; respect accessibility and user preferences; run tests after changes.

**Don't:** duplicate logic; hardcode platform differences; force unwrap; skip accessibility; hardcode strings; overuse `#if os()`; add init defaults for business deps; use `ObservableObject` for new code.

---

## Brand Mark

User-facing name is **RetroRapid!** Installed app display name is **RetroRapid!** (`CFBundleDisplayName`). App Store listing and bundle IDs omit `!`. Implementation: `RetroRacingShared/Utilities/BrandMark.swift`.

---

## Script Engineering

Repository automation: `Scripts/` Swift package. See `Scripts/README.md` and `Scripts/CONVENTIONS.md`.

App Store metadata pipeline (`generate-metadata-docs`, `apply-retrorapid-metadata`) is canonical; the Python script in `.agents/skills/app-store-aso/scripts/` is secondary.

---

## Validation

```bash
swift test --package-path Scripts
swift run --package-path Scripts run-tests
```

Documentation checks: `swift run --package-path Scripts check-documentation`

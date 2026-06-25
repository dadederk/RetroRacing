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

---

## Requirements And Plans

- Route behavior through `Requirements/INDEX.md` before implementing features.
- Update requirement docs when behavior changes.
- Shipped accessibility contract: `Requirements/accessibility.md`.

---

## Critical Architecture Rules

1. **Protocol-based dependency injection** — no default instantiations in `init` for business dependencies.
2. **Configuration injection** — no `#if os()` in service layer; inject platform config objects.
3. **Maximum code reuse** — platform-agnostic logic belongs in `RetroRacingShared/`.
4. **Never force-unwrap** — guard and fail safely.
5. **SwiftUI first** — prefer SwiftUI over UIKit in platform UI where sufficient.
6. **Use `@Observable`** — not `ObservableObject`, for new observation code.

Infrastructure singletons (`UserDefaults.standard`, `SystemRandomSource()`) may use a documented default when process-wide.

---

## SpriteKit + SwiftUI Integration

- Game logic lives in shared `GameScene.swift`; platform UI wraps `SpriteView` or view controllers.
- Input is captured in the UI layer and translated to `GameController` protocol calls (`moveLeft()`, `moveRight()`).
- No platform touch/gesture code in the shared scene except unavoidable platform extensions at boundaries.

---

## Logging

Use structured `AppLog` events: `<emoji> <DOMAIN> <EVENT_NAME>: outcome=<state> key=value ...`

Domains include assets, sound, font, localization, theme, game, leaderboard, achievement, monetization, input, accessibility, lifecycle, store, rating. Concatenate two domains only when a log truly crosses boundaries.

---

## Localization

All user-facing text in `RetroRacingShared/Localizable.xcstrings`. Supported: English, Spanish (Spain), Catalan (Valencian Meridional).

---

## File Organization

- ~200 lines of production code per file (guideline; exclude `#Preview` blocks).
- Split by responsibility: `GameViewController+Input.swift`, etc.
- Standard Swift file header with `Created by Dani Devesa` for new source files.

---

## Accessibility Conventions

Accessibility patterns follow the **ios-accessibility** skill (`.agents/skills/ios-accessibility/`). Project-specific patterns: `.agents/skills/ios-accessibility/references/retrorapid-patterns.md`. Shipped requirements: `Requirements/accessibility.md`.

---

## Testing Conventions

- App tests (RetroRacingShared): XCTest today.
- Scripts package: Swift Testing — follow **swift-testing-expert** for new script tests.
- Run after changes:

```bash
swift run --package-path Scripts run-tests
```

Test naming: `testGivenWhenThen` in camelCase with `// Given`, `// When`, `// Then` comments.

---

## Brand Mark

User-facing name is **RetroRapid!** App Store listing and bundle IDs omit `!`. Implementation: `RetroRacingShared/Utilities/BrandMark.swift`.

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

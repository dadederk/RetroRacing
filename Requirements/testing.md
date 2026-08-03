# Testing

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Validation commands, test naming, unit-test priorities, screenshot automation, and manual-QA boundaries.
- **Must not break:** Unit tests pass after code changes; tests use `testGivenWhenThen` naming with Given/When/Then comments; mocks use protocol implementations.
- **Key files:** `RetroRacingSharedTests/`, `RetroRacingUniversalTests/`, `Scripts/`, `./retrorapid`.

## Required Validation

Run the relevant smallest validation after a change, and the full app validation before shipping-risk changes:

```bash
./retrorapid test package
./retrorapid assets optimize --check
./retrorapid assets audit --check
./retrorapid check
./retrorapid test
```

- `./retrorapid test package` validates the Scripts Swift package.
- `./retrorapid assets optimize --check` regenerates into temporary storage and compares pixels and catalog JSON without mutating tracked files.
- `./retrorapid assets audit --check` validates runtime asset idioms, pixel caps, forbidden shipping resources, and compiled catalog byte ceilings.
- `./retrorapid check` verifies asset footprint, generated assets/docs/metadata, and other non-mutating checks.
- `./retrorapid test` runs shared and universal app unit tests through the Scripts runner.
- Use `./retrorapid test --dry-run` to inspect resolved commands.
- If signing blocks local verification, use the documented CI-like no-signing flags only for compile/test validation.

## Unit-Test Priorities

- Prefer pure, deterministic tests for shared game logic, services, settings stores, configuration, accessibility defaults, audio recipes, and state machines.
- Mock through protocols rather than concrete service substitution.
- Keep platform-agnostic behavior in `RetroRacingSharedTests`.
- Keep app-target integration behavior in `RetroRacingUniversalTests`.
- Add regression tests when fixing bugs in play limits, StoreKit gating, Game Center reporting, achievements, SharePlay, accessibility defaults, generated audio, runtime asset packaging, screenshot fixtures, or localization routing.

## Naming and Structure

- Test names use camelCase `testGivenWhenThen`.
- The “Then” phrase must name the concrete outcome, not “works” or “is correct”.
- Test bodies use exactly these section comments when helpful:

```swift
// Given
// When
// Then
```

- Keep helper names specific to behavior, and avoid hidden global state.
- Tests under Swift’s main-actor defaults must stay explicit about async boundaries and actor isolation.

## Screenshot Capture Tests

- App Store screenshot capture uses `RetroRacingUniversalUITests/AppStoreScreenshotTests`.
- Screenshot UI tests require `RETRORAPID_SCREENSHOT_CAPTURE=1` and skip themselves during regular Xcode scheme runs.
- `./retrorapid test` remains limited to shared and universal unit tests; run localized, multi-platform screenshot capture manually when preparing a release after significant UI changes.
- Fixtures live under `RetroRacingShared/ScreenshotCapture/`; behavior contract lives in [screenshot_capture.md](screenshot_capture.md).
- Common commands:

```bash
./retrorapid screenshots capture --dry-run
./retrorapid screenshots capture --platform ipad --locales en-US --slides 2,5
./retrorapid screenshots capture --all-platforms --locales en-US,de-DE,es-MX,ja --slides 0 --dry-run
./retrorapid screenshots sync --check
```

## Manual QA Boundary

Keep manual QA focused on behavior that cannot be proven by unit tests:

- real Game Center sandbox visibility, auth, leaderboard/achievement ASC configuration
- StoreKit sandbox purchase, restore, refund/revocation, and App Review fresh-install path
- real GroupActivities SharePlay transport across two devices/Macs
- platform accessibility smoke tests with VoiceOver, Switch Control, Dynamic Type, keyboard, remote, controller, and Digital Crown
- App Store screenshots and TestFlight/App Review submission flows

Manual checklists belong in the relevant operational hub or feature contract, not in this general testing file.

## Parallel Canary

Use the parallel canary only when auditing test isolation or preparing to change defaults:

```bash
./retrorapid test parallel-canary --workers 2,4
```

The stable recipe remains serial unless the canary proves the relevant targets are isolated.

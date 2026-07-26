# App Store Screenshot Capture Mode

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Deterministic in-app screenshot capture mode for App Store base images; env-gated, fixture-driven, UI-test orchestrated.
- **Must not break:** Capture mode is **DEBUG-only** (ignored in Release/App Store binaries); fixtures must be deterministic; readiness markers must appear before UI tests capture.
- **Key files:** `RetroRacingShared/ScreenshotCapture/`, `RetroRacingUniversal/ScreenshotCapture/`, `RetroRacingWatchOS/ScreenshotCapture/`, `RetroRacingUniversalUITests/AppStoreScreenshotTests.swift`, `RetroRacingWatchOSUITests/AppStoreScreenshotTests.swift`, `Scripts/Sources/RetroRacingAutomationCore/AppStoreScreenshotCaptureWorkflow.swift`.
- **App Store ops:** [Add language / refresh screenshots](../AppStore/docs/08-locale-expansion.md) · [Storyboard](../AppStore/docs/06-screenshots.md) · [testing.md](testing.md)

## Purpose

When `RETRORAPID_SCREENSHOT_CAPTURE=1` is set, the app swaps to a fixture-driven UI instead of live gameplay. UI tests capture localized screenshots and the Scripts CLI installs them into Screenshot Studio.

Capture mode is **not** user-facing product behavior; it exists for App Store asset generation only.

## Activation

| Environment variable | Required | Purpose |
|---|---|---|
| `RETRORAPID_SCREENSHOT_CAPTURE` | Yes (`1`) | Enables capture mode |
| `RETRORAPID_SCREENSHOT_SLIDE` | Yes | Slide index (`0`–`9` for iPhone/iPad; `0`–`8` for Mac; `0`–`4` for Watch) |
| `RETRORAPID_SCREENSHOT_STAGING` | Optional | Output directory for captured files |
| `RETRORAPID_SCREENSHOT_TARGETS` | Optional | Single capture target stem (e.g. `en-US_4`) for the UI test run |
| `RETRORAPID_SCREENSHOT_PLATFORM` | Optional | `iphone`, `ipad`, `mac`, or `watch`/`appleWatch`; selects the platform capture plan |
| `RETRORAPID_SCREENSHOT_FILE_EXTENSION` | Optional | `jpeg` (iPhone) or `png` (Mac) |

Under XCTest, capture mode also activates when `RETRORAPID_SCREENSHOT_SLIDE` is set (even without the capture flag).

The CLI writes the current target to `/tmp/retrorapid-capture-plan-active.json` immediately before each UI test run. UI tests read that file (not shell environment variables) to resolve locale, slide, and staging directory.

Implementation: `ScreenshotCaptureConfiguration` (Universal) and `WatchScreenshotCaptureConfiguration` (Watch) in `RetroRacingShared/ScreenshotCapture/`.

## Slide → fixture mapping

### iPhone / iPad

Canonical source: `ScreenshotSlideFixture` in `RetroRacingShared/ScreenshotCapture/ScreenshotSlideFixture.swift`. Ten slides (`0`–`9`).

| Slide | Fixture | Route | Gameplay layout | Presentation |
|---:|---|---|---|---|
| 0 | `hookGameplay` | Gameplay | Hook grid | Full screen |
| 1 | `actionGameplay` | Gameplay | Action grid | Full screen |
| 2 | `gameOver` | Game Over | Action crash grid (background HUD score = game-over run score) | Game-over sheet over gameplay |
| 3 | `accessibilitySettings` | Settings (accessibility focus) | Hook grid | Settings sheet from menu |
| 4 | `sharePlayWaiting` | Gameplay + SharePlay overlay | Hook grid | Waiting-for-friend overlay |
| 5 | `friendMarkerGameplay` | Gameplay | Friend-marker grid | Full screen |
| 6 | `themeSettings` | Settings (customize focus) | Hook grid | Settings sheet from menu |
| 7 | `pocketGameplay` | Gameplay | Hook grid + Pocket theme | Full screen |
| 8 | `achievementUnlock` | Achievement unlock | Hook grid (background) | VoiceOver control unlock sheet |
| 9 | `freeUserMenu` | Menu | — | Free-tier menu with Play with Friends (iOS/iPadOS) |

### Mac

Nine slides (`0`–`8`). Same story as iPhone/iPad except **no SharePlay slide** — indices `4`–`6` match iPhone slides `5`–`7`, then achievements and menu append at `7`–`8`. Menu omits Play with Friends.

| Slide | Fixture | Route | Presentation |
|---:|---|---|---|
| 0–3 | Same as iPhone | Same as iPhone | Same as iPhone |
| 4 | `friendMarkerGameplay` | Gameplay | Full screen |
| 5 | `themeSettings` | Settings (customize focus) | Settings sheet over menu overlay |
| 6 | `pocketGameplay` | Gameplay | Full screen |
| 7 | `achievementUnlock` | Achievement unlock | Unlock sheet |
| 8 | `freeUserMenu` | Menu | Solo menu (no SharePlay entry) |

Platform resolution uses `ScreenshotSlideFixture.fixture(for:platform:)` with `RETRORAPID_SCREENSHOT_PLATFORM`.

### Apple Watch

Canonical source: `WatchScreenshotSlideFixture` in `RetroRacingShared/ScreenshotCapture/WatchScreenshotSlideFixture.swift`.

Watch captures are **sequence-only** (empty Screenshot Studio overlay copy). Locale handling matches other platforms: seven source locales via UI tests, then derived English and `es-MX` copies.

| Slide | Fixture | Route | Gameplay layout | Presentation |
|---:|---|---|---|---|
| 0 | `hookGameplay` | Gameplay | Hook grid (LCD) | Full screen |
| 1 | `menu` | Menu | — | Main menu (Play + title) |
| 2 | `actionGameplay` | Gameplay | Action grid (LCD) | Full screen |
| 3 | `pocketGameplay` | Gameplay | Hook grid + Pocket theme | Full screen |
| 4 | `settings` | Settings | — | Settings sheet from menu |

Readiness marker identifier: `screenshot-ready-slide-{index}` (`ScreenshotCaptureIdentifiers.readinessIdentifier`).

All platforms expose the marker via SwiftUI `.accessibilityIdentifier` on a clear element (`ScreenshotCaptureReadinessMarker`). UI tests wait for that identifier before capturing. On macOS, UI tests also wait for the capture window to appear, activate the app, and retry landscape window sizing via `MacScreenshotCaptureAppDelegate` because XCUITest cannot discover overlay markers until the sandboxed app window is key.

macOS UI tests write captured PNGs directly to `.build/screenshot-capture/mac/` (`RetroRacingUniversalUITests.entitlements` disables the UI-test sandbox on macOS). The CLI also syncs flat `/tmp/retrorapid-mac-*` or legacy container paths when present.

## Architecture

- **Shared fixtures:** `RetroRacingShared/ScreenshotCapture/` — configuration, layouts, fixture catalog, readiness marker.
- **Platform orchestration:** `RetroRacingUniversal/ScreenshotCapture/ScreenshotCaptureRootView.swift` — gameplay fixtures, sheet presentation for settings and game-over slides, window sizing (Mac), dependency assembly.
- **Watch orchestration:** `RetroRacingWatchOS/ScreenshotCapture/WatchScreenshotCaptureRootView.swift` — five-slide menu/gameplay/settings storyboard; skips Game Center auth retries during capture.
- **App entry:** `RetroRacingApp` / `RetroRacingWatchOSApp` swap root view when capture configuration is active.
- **CLI:** `./retrorapid screenshots capture` → `capture-app-store-screenshots` → incremental xcodebuild UI test runs → Screenshot Studio install → manifest sync.

## Capture locales

**Source** (UI tests, all platforms): `en-US`, `de-DE`, `nl-NL`, `it`, `fr-FR`, `es-ES`, `ca`, `ja`, `ko`, `pt-BR`, `zh-Hant`.

**Derived** (pixel copy after capture/sync): `en-GB`/`en-AU`/`en-CA` ← `en-US`; `es-MX` ← `es-ES`.

Watch: same locale plan; CLI sets `AppleLanguages` / `AppleLocale` on watch + paired iPhone via `simctl`. Studio overlays stay empty.

**Ops checklist** (refresh, install-only, partial re-takes): [`AppStore/docs/08-locale-expansion.md`](../AppStore/docs/08-locale-expansion.md).

`./retrorapid screenshots sync` updates overlays + `contents.json` and copies **derived** pixels only — never overwrite source locales (`de-DE`, `ja`, …) with `en-US`.

Unit tests: `ScreenshotCaptureConfigurationTests`, Scripts capture/placement tests.

## Production constraints

- iPhone capture: JPEG staging in `.build/screenshot-capture/iphone/`. Before each target, the CLI sets simulator `AppleLanguages` / `AppleLocale` via `simctl` (same supplement as watch). The app applies launch-argument locale to `UserDefaults` and SwiftUI `.environment(\.locale)` during capture so string-catalog UI matches the requested App Store locale.
- Apple Watch capture: JPEG staging in `.build/screenshot-capture/appleWatch/`; `RetroRacingWatchOS` scheme + `RetroRacingWatchOSUITests/AppStoreScreenshotTests`; default destination `Apple Watch Ultra 3 (49mm)`. Capture strings use an explicit launch-argument locale via `GameLocalizedStrings` (watchOS often ignores Bundle preferredLocalizations from `-AppleLanguages`). Marketing clock **10:09** is **opt-in** with `--status-bar-override` (host system time; watchOS has no `simctl status_bar`) — off by default. Game Center auth skipped in capture mode. Gameplay slides present `WatchGameView` inside a `NavigationStack` so the close and pause toolbar buttons match live in-app capture.
- Mac capture: PNG staging in `.build/screenshot-capture/mac/`; landscape window sizing via `ScreenshotCaptureMacWindowLayout`.
- Mac capture waits ~900ms after layout before applying fixtures so window resizing can finish; gameplay readiness no longer resets on every sub-point geometry tick during capture.
- iPhone/iPad capture applies the App Store marketing status bar (`9:41` on **Wednesday, 27 January 2027**, full battery, strong signal) via `simctl status_bar override` on the **same simulator UDID** as the xcodebuild destination (matched by device name and `OS=` version). The ISO `--time` string uses the **marketing date's** seasonal UTC offset (not the capture host's current DST offset) so iPad renders `09:41` instead of drifting to `08:41`/`10:41`; pass `--no-status-bar-override` to skip. iPhone capture keeps portrait game layout; iPad capture rotates the simulator to landscape and uses the regular-width wide play layout (full-width score/lives header with direction buttons flanking the centered game square).
- iPad settings slides (2 and 5) present settings from the menu (iPhone/iPad) or menu overlay (Mac), matching in-app navigation — not from an in-progress game session. On iPhone/iPad screenshot capture, settings sheets use an opaque grouped navigation bar (`.toolbarBackground` + hard top scroll edge) and keep the live **Done** trailing toolbar button so chrome matches in-app Settings.
- Settings, game-over, and gameplay HUD slides use the isolated screenshot font store (`makeScreenshotFontPreferenceStore`) so Press Start 2P renders when bundled.
- Capture gameplay fixtures force **Big Cars off** via `ScreenshotCapturePreferences` (in-memory overrides; no persisted user-default writes). `GameView` runtime preference sync and `GameViewModel.applyScreenshotLayout` both re-apply capture overrides so `@AppStorage` cannot re-enable Big Cars mid-capture.
- Capture appearance defaults to **light** (in-app `preferredColorScheme` + iPhone/iPad `simctl ui appearance`). Pass `--appearance dark` to capture dark mode instead.
- Slide 5 friend-marker fixture targets the middle car one row above the player (row 3, center column) on every platform, with live badge sizing (no capture-only diameter scale hack).
- Slide 4 SharePlay fixture injects `.waitingForFriend` via `SharePlayUIState` (iPhone/iPad only).
- Slide 8 achievement fixture presents `AchievementUnlockView` with the VoiceOver control achievement as the visual only. Capture mode uses `NoOpAchievementMetadataService` so the sheet shows ASC-aligned local fallback strings from `AchievementIdentifier+Localization` / `Localizable.xcstrings` instead of English Game Center metadata.
- Slide 9 menu fixture uses freemium simulation and shows Play with Friends on iPhone/iPad only.
- Social/Game Center refresh is pinned during gameplay fixtures (`GameViewModel.isScreenshotCapturePinned`).

## Related requirements

- [testing.md](testing.md) — test strategy and capture test references
- [accessibility.md](accessibility.md) — slide 3 accessibility settings fixture
- [theming_system.md](theming_system.md) — slide 5 theme settings fixture
- [game_center_social_milestones.md](game_center_social_milestones.md) — slide 4 friend-marker fixture

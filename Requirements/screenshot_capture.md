# App Store Screenshot Capture Mode

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** DEBUG-only deterministic screenshot capture mode for App Store base images, fixtures, readiness markers, UI tests, and Scripts orchestration.
- **Must not break:** Capture mode is ignored in Release/App Store builds; fixtures are deterministic; readiness markers appear before capture; source locales are never overwritten by derived copies.
- **Key files:** `RetroRacingShared/ScreenshotCapture/`, platform capture roots, `AppStoreScreenshotTests`, `AppStoreScreenshotCaptureWorkflow`.

## Activation

- Main flag: `RETRORAPID_SCREENSHOT_CAPTURE=1`.
- Required target data: slide index plus locale/platform from the CLI active plan.
- Under XCTest, setting `RETRORAPID_SCREENSHOT_SLIDE` also activates capture mode.
- The CLI writes `/tmp/retrorapid-capture-plan-active.json` before each UI test run; tests read that file for locale, slide, platform, and staging.
- Readiness marker: `screenshot-ready-slide-{index}` via `ScreenshotCaptureReadinessMarker`.

## Fixture Catalog

- iPhone/iPad slides 0-9: hook gameplay, action gameplay, game over, accessibility settings, SharePlay waiting, friend marker, theme settings, Pocket gameplay, achievement unlock, free-user menu.
- Mac slides 0-8: same story without SharePlay slide; later indices shift accordingly.
- Watch slides 0-4: hook gameplay, menu, action gameplay, Pocket gameplay, settings.
- Fixture definitions live in `ScreenshotSlideFixture` and `WatchScreenshotSlideFixture`.

## Locale and Platform Rules

- Source locales: `en-US`, `de-DE`, `nl-NL`, `it`, `fr-FR`, `es-ES`, `ca`, `ja`, `ko`, `pt-BR`, `zh-Hant`.
- Derived copies: `en-GB`, `en-AU`, `en-CA` from `en-US`; `es-MX` from `es-ES`.
- `./retrorapid screenshots sync` may copy derived pixels and overlays but must never replace source locale captures with English.
- iPhone/iPad default to light appearance and marketing status bar unless flags override.
- Watch leaves marketing clock override off by default.
- Mac writes PNG captures and uses capture-specific window sizing.

## Production Constraints

- Capture mode must not be reachable in Release/App Store binaries.
- Capture root views may use in-memory preferences and no-op services to stabilize screenshots.
- Capture fixtures must avoid persisted user-default writes except explicit capture configuration paths.
- Game Center/social refreshes are pinned where needed so fixtures stay deterministic.

## Operations

- Storyboard and copy: [../AppStore/docs/06-screenshots.md](../AppStore/docs/06-screenshots.md).
- Add language / refresh checklist: [../AppStore/docs/08-locale-expansion.md](../AppStore/docs/08-locale-expansion.md).
- Common canary:

```bash
./retrorapid screenshots capture --all-platforms --locales en-US --slides 0 --dry-run
./retrorapid screenshots sync --check
```

## Testing

- Unit tests cover capture configuration, fixture routing, locale derivation, placement workflow, and manifest sync.
- UI tests wait for readiness markers before capture on every platform.

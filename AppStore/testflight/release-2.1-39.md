# RetroRapid! 2.1 (39) release candidate

**Status:** Superseded on 2026-10-19 by the coordinated [2.2 (38) candidate](release-2.2-38.md). Retain this record as upload history; do not select these builds for public release.

## Source and artifacts

- Working tree based on source commit `2f01a1a`, with the 2.1 personalization release changes in the current uncommitted workspace.
- Toolchain: Xcode 27.1 RC, build `27A9275`, selected at `/Applications/Xcode_27_1_RC.app/Contents/Developer`.
- iOS and embedded Watch archive: `build/testflight-2.1/RetroRacingUniversal-iOS.xcarchive`; the iPhone/iPad app and Watch companion are both version 2.1 (39), signed by team `PV9S9FTZF2`.
- Mac archive: `build/testflight-2.1/RetroRacingUniversal-macOS.xcarchive`; version 2.1 (39), signed by the same team.
- Xcode uploaded both packages on 2026-10-19. App Store Connect processed both as App Store eligible and reports no non-exempt encryption.

## Validation and release material

- `./retrorapid test package`: passed.
- `./retrorapid check`: passed, including assets, metadata, localization, documentation, IAP, and Game Center checks.
- `./retrorapid test`: the shared and Universal test suites passed under Xcode 27.1 RC after updating the 2.1 theme defaults.
- [The 2.1 What's New catalog](../metadata/retrorapid-v2.1-whats-new.json) contains App Store and TestFlight copy for all 20 supported locales.
- The approved App Store What's New text was applied to all 20 iOS localizations and all 20 macOS localizations. English readback matched the canonical copy on both versions.
- All 20 localized TestFlight What to Test notes were applied to each build. Helm currently provides no beta-note readback, so every update response was checked and all 40 completed without failure.
- The Apple TV 2.2 (38) beta and its localized notes were left unchanged. visionOS remains outside this release.

## App Store Connect on 2026-10-19

| Platform | Build ID | Processing | External TestFlight |
|---|---|---|---|
| iOS with Watch | `99b929a5-1ccd-42bb-b6b5-b31873d9aaf8` | Complete; App Store eligible | Attached to External Testing group `df40f833-12c7-4411-b28d-122690045c58`; `WAITING_FOR_BETA_REVIEW` |
| macOS | `54967863-69c9-47ed-bf80-b172acb34187` | Complete; App Store eligible | Attached to External Testing group `df40f833-12c7-4411-b28d-122690045c58`; `WAITING_FOR_BETA_REVIEW` |

Attaching the builds to the external group submitted both beta review requests. No build was selected for the public 2.1 App Store versions, no App Review submission was created, and no public release was scheduled.

## Remaining release gates

- Wait for Apple beta review before expecting external testers to receive build 39.
- Test the App Icon gallery on iPhone and iPad, including all nine Unlimited Plays icons, Dark artwork, Clear and Tinted appearances, purchase, and restore behavior.
- Test Cartridge and CRT plus the existing Styles on iPhone, iPad, Mac, and Apple Watch, including free and Unlimited Plays entitlement boundaries.
- Recheck SharePlay, Game Center, accessibility, layouts, and upgrade behavior before selecting build 39 for public App Review.
- Obtain fluent review for the localized release notes where required by the submission quality gate.

Use the [release candidate workflow](../docs/21-release-candidate-workflow.md) to resume. Do not create another build number unless code or release assets change.

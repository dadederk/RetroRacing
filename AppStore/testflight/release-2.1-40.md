# RetroRapid! 2.1 (40) corrective release candidate

**Status:** Uploaded and attached to external TestFlight on 2026-10-22. This candidate corrects the 2.1 App Icon gallery before public release while leaving the coordinated 2.2 App Store drafts unchanged.

## Source and artifacts

- Working tree based on source commit `2f01a1a`, with the corrective 2.1 personalization changes in the current uncommitted workspace.
- Toolchain: Xcode 27.1 RC, build `27A9275`, selected at `/Applications/Xcode_27_1_RC.app/Contents/Developer`.
- iOS and embedded Watch archive: `build/testflight-2.1-40/RetroRacingUniversal-iOS.xcarchive`; the iPhone/iPad app and Watch companion are both version 2.1 (40), signed by team `PV9S9FTZF2`.
- Mac archive: `build/testflight-2.1-40/RetroRacingUniversal-macOS.xcarchive`; version 2.1 (40), signed by the same team.
- The previous build 39 archives remain at `build/testflight-2.1-39/`.
- Xcode uploaded both build 40 packages on 2026-10-22. App Store Connect processed both as App Store eligible and reports no non-exempt encryption.

## Corrected behavior

- On iPhone and iPad, Unlimited Plays exposes seven alternate icons: Pocket, LCD, Cartridge, CRT, and three Special Editions. Every exposed alternate has custom Dark artwork.
- Disc remains hidden until the tvOS release; Polygon remains hidden until the visionOS release. Both asset packages remain compiled for their future platform rollouts.
- Default Styles remain LCD on iPhone, Cartridge on iPad, CRT on Mac, Pocket on Apple Watch, Disc on Apple TV, and Polygon on Apple Vision Pro.
- The tvOS and visionOS binaries were not uploaded as part of this corrective 2.1 candidate.

## Validation and release material

- `./retrorapid test package`, `./retrorapid test`, `./retrorapid check`, and `./retrorapid docs` passed for the corrective source before archiving.
- Archive inspection confirmed version 2.1 (40), team `PV9S9FTZF2`, and the intended architectures on iOS, embedded watchOS, and macOS.
- [The 2.1 What's New catalog](../metadata/retrorapid-v2.1-whats-new.json) contains the approved seven-icon App Store copy and platform-accurate TestFlight focus for all 20 supported locales.
- All 20 localized TestFlight What to Test notes passed Helm dry-run and were applied to each build. Every one of the 40 writes completed without failure.
- The existing 2.2 App Store versions and their metadata were left unchanged. App Store Connect has no editable 2.1 version, so the local 2.1 What's New catalog cannot be applied remotely without replacing the 2.2 drafts.

## App Store Connect on 2026-10-22

| Platform | Build ID | Processing | External TestFlight |
|---|---|---|---|
| iOS with Watch | `5f46280a-067b-4b68-983b-2a890d38a836` | Complete; App Store eligible | Attached to External Testing group `df40f833-12c7-4411-b28d-122690045c58`; `BETA_APPROVED` |
| macOS | `0b506ba3-d270-4fc9-a8ad-6bd11dfc707a` | Complete; App Store eligible | Attached to External Testing group `df40f833-12c7-4411-b28d-122690045c58`; `BETA_APPROVED` |

Both external attachments used `autoNotify = false`. No build was selected for a public App Store version, no App Review submission was created, and no public release was scheduled.

## Remaining release gates

- Test the App Icon gallery on iPhone and iPad, including all seven Unlimited Plays icons, Dark artwork, purchase, and restore behavior.
- Test all released Styles and platform defaults on iPhone, iPad, Mac, and Apple Watch.
- Recheck SharePlay, Game Center, accessibility, layouts, and upgrade behavior before selecting build 40 for public App Review.
- Resolve the remote App Store version mismatch before applying the 2.1 What's New text or choosing a public build.

Use the [release candidate workflow](../docs/21-release-candidate-workflow.md) to resume. Do not create another build number unless code or release assets change.

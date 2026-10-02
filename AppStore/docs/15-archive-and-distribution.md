# Archive and Distribution

Operational reference for TestFlight and App Store archive shape. For the end-to-end sequence, see [21-release-candidate-workflow.md](21-release-candidate-workflow.md); for Xcode Cloud, see [17-xcode-cloud-releases.md](17-xcode-cloud-releases.md); for local uploads, see [14-testflight-helm-upload.md](14-testflight-helm-upload.md).

## Required Archive Shape

| Platform build | Xcode destination | Notes |
|---|---|---|
| iOS + watchOS | Any iOS Device | One iOS archive contains iPhone/iPad plus embedded watch app. |
| macOS | Any Mac | Separate macOS archive; attach to the matching macOS version draft. |
| visionOS | Any visionOS Device | Implemented target only; the public listing remains a placeholder, so exclude it from the ordinary release candidate. |

- Do not upload a standalone watchOS build. TestFlight shows the watch app through the iOS build.
- Do not archive with a simulator or “My Mac” when producing the iOS/watchOS archive.
- `RetroRacingUniversal` builds iOS and macOS. The dedicated `RetroRacingVisionOS` target owns the visionOS binary.
- `RetroRacingUniversal` and `RetroRacingVisionOS` share `com.accessibilityUpTo11.RetroRacing`, but shared identity does not make visionOS a gameplay shipping promise.
- Keep one build number per release candidate across the iOS archive, its embedded Watch app, and the macOS archive. For a later public rebuild, advance to one new number on all shipping platforms, including a platform whose previous archive could already be submitted. Check App Store Connect for the highest uploaded number before reserving it.

## Watch Embed Checks

- `RetroRacingWatchOS` must be included in the scheme build list for Archive.
- `RetroRacingUniversal` must embed `RetroRacingWatchOS.app` into `$(CONTENTS_FOLDER_PATH)/Watch`.
- The embedded watch build file must use `platformFilter = ios`.
- Verify a completed iOS archive by inspecting the app bundle for `Watch/RetroRacingWatchOS.app`.

## macOS Release Checks

- macOS uploads require `LSApplicationCategoryType = public.app-category.games` scoped to `sdk=macosx*`.
- If App Review reports installed-name mismatch, use a macOS-only `PRODUCT_NAME[sdk=macosx*] = RetroRapid!` override while preserving bundle ID.
- Gameplay windows enforce minimum size only: 820 x 620.
- Validate macOS command behavior before archive: `Cmd+Q`, `Cmd+,`, menu overlay, settings Done placement, and trackpad swipe movement.

## Submission Checks

- Attach iOS and macOS builds to their matching **platform-specific** App Store Connect version drafts for the same marketing version.
- Record Xcode build and SDK for each archive. A TestFlight-accepted beta toolchain may not be accepted for the public App Store; verify [Apple's current notice](https://developer.apple.com/help/app-store-connect/release-notes/) before selecting a public build.
- Confirm App Store platform availability matches public status in [../README.md](../README.md) and repo rules in [../../AGENTS.md](../../AGENTS.md).
- Confirm macOS screenshots and metadata parity before submitting public Mac claims.
- Xcode Cloud release builds should arrive in Internal Testing first; promote to external beta or App Store review only after manual feedback and release-gate checks pass.

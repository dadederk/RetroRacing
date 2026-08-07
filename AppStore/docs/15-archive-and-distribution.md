# Archive and Distribution

Operational reference for TestFlight and App Store archive shape. For Xcode Cloud release workflows, see [17-xcode-cloud-releases.md](17-xcode-cloud-releases.md). For Helm upload steps, see [14-testflight-helm-upload.md](14-testflight-helm-upload.md).

## Required Archive Shape

| Platform build | Xcode destination | Notes |
|---|---|---|
| iOS + watchOS | Any iOS Device | One iOS archive contains iPhone/iPad plus embedded watch app. |
| macOS | Any Mac | Separate macOS archive; attach to the same App Store version. |
| visionOS | Any visionOS Device | Archive `RetroRacingVisionOS` and attach it to the same App Store app identity. |

- Do not upload a standalone watchOS build. TestFlight shows the watch app through the iOS build.
- Do not archive with a simulator or “My Mac” when producing the iOS/watchOS archive.
- `RetroRacingUniversal` builds iOS and macOS. The dedicated `RetroRacingVisionOS` target owns the visionOS binary.
- `RetroRacingUniversal` and `RetroRacingVisionOS` share `com.accessibilityUpTo11.RetroRacing` so the approved Unlimited Plays product resolves on every supported App Store platform.

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

- Attach both iOS and macOS builds to the same App Store Connect version.
- Confirm App Store platform availability matches public status in [../README.md](../README.md) and repo rules in [../../AGENTS.md](../../AGENTS.md).
- Confirm macOS screenshots and metadata parity before submitting public Mac claims.
- Xcode Cloud release builds should arrive in Internal Testing first; promote to external beta or App Store review only after manual feedback and release-gate checks pass.

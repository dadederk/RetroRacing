# RetroRapid! 2.2 (38) coordinated release candidate

## Source and artifacts

- Working tree based on source commit `2f01a1a`, with the coordinated 2.2 release changes in the current uncommitted workspace.
- Toolchain: Xcode 27.1 RC, build `27A9275`, selected at `/Applications/Xcode_27_1_RC.app/Contents/Developer`.
- iOS and embedded Watch archive: `build/testflight-2.2/RetroRacingUniversal-iOS.xcarchive`; the iPhone/iPad app and Watch app are both version 2.2 (38), signed by team `PV9S9FTZF2`.
- Mac archive: `build/testflight-2.2/RetroRacingUniversal-macOS.xcarchive`; version 2.2 (38), signed by the same team.
- Apple TV archive: `build/testflight-2.2/RetroRacingTvOS.xcarchive`; version 2.2 (38), bundle ID `com.accessibilityUpTo11.RetroRacing`.
- The Apple TV generic archive is intentionally unsigned so creating it does not require a registered Apple TV. Xcode applies authenticated App Store distribution signing during export.
- Apple TV was uploaded on 2026-10-18. iOS with embedded Watch and macOS were uploaded on 2026-10-19. App Store Connect processed all three packages as App Store eligible and reports no non-exempt encryption.
- visionOS remains the separate public “Coming Soon” placeholder and is not part of this 2.2 release candidate.

## Validation and release material

- `./retrorapid test package`: 137 automation tests passed after the final version alignment.
- `./retrorapid check`: passed, including assets, Screenshot Studio sources, metadata, localization, documentation, IAP, and Game Center checks.
- `./retrorapid test`: the shared and Universal test suites passed under Xcode 27.1 RC after all shipping targets were aligned to 2.2 (38).
- Archive inspection confirms iPhone/iPad, embedded Apple Watch, macOS, and tvOS all use marketing version 2.2 and build number 38.
- Screenshot Studio contains 10 Apple TV slides for each of 20 locales: 200 PNG source images at 3840 × 2160. The screenshot and localization checks pass against the complete manifest.
- Representative English, German, Japanese, Polish, and Traditional Chinese Apple TV screenshots were visually inspected. The deterministic capture uses the Apple TV Disc style and includes gameplay, settings, accessibility, Game Center, SharePlay, and achievement states.
- [The 2.2 What's New catalog](../metadata/retrorapid-v2.2-whats-new.json) contains the Apple TV launch copy for iOS, macOS, watchOS, and tvOS in all 20 supported locales.
- [The full 2.2 metadata catalog](../metadata/retrorapid-v2.2-candidate.json) was applied through Helm to the iOS, macOS, and tvOS drafts across all 20 locales. App Store Connect accepted What's New for iOS/macOS; its first-release rule leaves the tvOS What's New field unavailable and empty.
- All 20 localized TestFlight What to Test notes were applied to each platform build. These remain separate from App Store What's New.

## App Store Connect on 2026-10-19

| Platform | Build ID | Processing | External TestFlight |
|---|---|---|---|
| iOS with embedded Watch | `a1531256-d063-4ed9-a7a7-bb2b2b6b79c5` | Complete; App Store eligible | Attached to External Testing group `df40f833-12c7-4411-b28d-122690045c58`; `WAITING_FOR_BETA_REVIEW` |
| macOS | `d9bf752a-2efe-4228-a68e-3f9914fb2991` | Complete; App Store eligible | Attached to External Testing group `df40f833-12c7-4411-b28d-122690045c58`; `WAITING_FOR_BETA_REVIEW` |
| tvOS | `72763099-1352-486b-b2f1-a6fa8ba8ac88` | Complete; App Store eligible | Attached to External Testing group `df40f833-12c7-4411-b28d-122690045c58`; `IN_BETA_TESTING` |

Attaching the builds to the external group submitted beta review requests. Apple has approved the Apple TV build for external testing; iOS and macOS are awaiting beta review.

Editable public 2.2 App Store versions now exist for iOS (`1f8c3bf2-b4cf-42db-9684-132d016c4d96`), macOS (`4f70252a-8246-4e5c-932e-b59a4374c505`), and tvOS (`9997d862-c36e-4f8c-905c-65fce7fce3ab`), all in `PREPARE_FOR_SUBMISSION`. Their localized metadata is applied. No build was selected for public release and no App Review submission was made.

## Coordinated public-release rule

- Treat iPhone, iPad, embedded Apple Watch, Mac, and Apple TV as one 2.2 release train.
- Do not submit or release any 2.2 platform independently. All public versions must select build 38 and carry the approved 20-locale 2.2 What's New copy before submission.
- Use a shared release date or hold every approved version for a coordinated manual release so availability remains aligned across storefronts.
- Keep visionOS outside this release until its placeholder stage is explicitly promoted.

## Remaining release gates

- Obtain external beta approval for iOS and macOS, then confirm all three TestFlight builds are available to the external group.
- Complete Apple TV hardware acceptance with the Siri Remote and a supported controller: launch/focus, gameplay, pause/exit, settings, Game Center, purchase/restore, VoiceOver, and SharePlay with a real FaceTime group.
- Recheck the personalization features included in the shared source: the iPhone/iPad App Icon gallery and Cartridge/CRT Styles on iPhone, iPad, Mac, and Apple Watch.
- Obtain fluent approval for the exact 20-locale What's New and What to Test copy. Machine validation does not replace native review.
- Complete human visual approval of all 200 Apple TV screenshots in Screenshot Studio before exporting or uploading the public App Store screenshot sets.
- Export, review, and upload the localized public screenshots, then select build 38 on all three public versions only after the owner explicitly authorizes the public-release step.

Use the [release candidate workflow](../docs/21-release-candidate-workflow.md) to resume. Do not create another build number unless code or release assets change.

# RetroRapid! 2.2 (39) corrective coordinated TestFlight candidate

**Status:** Uploaded and configured on 2026-10-24 for iOS with embedded Apple Watch, macOS, and tvOS. All three builds are processed, App Store eligible, and `READY_FOR_BETA_SUBMISSION`. They are not attached to the external TestFlight group and have not been submitted for beta review.

## Source and artifacts

- Source commit: `9cebd700341166003dc101e5fa3a8303fa5d0db9` on `master`.
- Toolchain: Xcode 27.1, build `27A9275`, selected at `/Applications/Xcode_27_1_RC.app/Contents/Developer`. Apple [accepts Xcode 27.1 builds](https://developer.apple.com/help/app-store-connect/release-notes/) for the App Store and internal or external TestFlight testing.
- iOS and embedded Watch archive: `build/testflight-2.2/RetroRacingUniversal-iOS.xcarchive`; the iPhone/iPad app and embedded Watch app are both version 2.2 (39), built with the iOS 27.1 and watchOS 27.0 SDKs.
- Mac archive: `build/testflight-2.2/RetroRacingUniversal-macOS.xcarchive`; version 2.2 (39), built with the macOS 27.0 SDK for `arm64` and `x86_64`.
- Apple TV archive: `build/testflight-2.2/RetroRacingTvOS.xcarchive`; version 2.2 (39), built with the tvOS 27.0 SDK. The generic archive is intentionally unsigned and was App Store signed during its successful export.
- Rejected build-38 archives are preserved under `build/testflight-2.2-build38/`.
- visionOS remains the separate public “Coming Soon” placeholder and is outside this 2.2 release candidate.

## Validation

- `./retrorapid test package`: 231 tests passed across the Scripts package suites.
- `./retrorapid check`: passed, including assets, app icons, spatial assets, screenshots, metadata, localization, documentation, IAP, and Game Center checks.
- `./retrorapid test`: the shared and Universal app suites passed under Xcode 27.1.
- Release-configuration UI regressions passed for the exact shipping Styles and App Icon catalogs.
- Shipping configuration tests cover every implemented platform and assert clean-install defaults: LCD on iPhone, Cartridge on iPad, CRT on Mac, Pocket on Watch, Disc on Apple TV, and Polygon on Vision Pro.
- iPhone/iPad release UI exposes Pocket, LCD, Cartridge, and CRT. Its App Icon gallery exposes Classic, the four released theme icons, and the three Special Editions; Disc and Polygon are absent.
- All three App Store exports and uploads completed successfully. App Store Connect reports no processing failure.

## App Store Connect

| Platform | Build ID | State | Configuration |
|---|---|---|---|
| iOS with embedded Watch | `f5768ebb-a3c2-4bc2-a903-4a0c90e9828e` | `READY_FOR_BETA_SUBMISSION` | No non-exempt encryption; all 20 localized What to Test notes applied |
| macOS | `a98e523c-de13-4f9f-a6d2-894fdbc5cc5c` | `READY_FOR_BETA_SUBMISSION` | No non-exempt encryption; all 20 localized What to Test notes applied |
| tvOS | `31cd32b2-2803-4647-8f22-86cb2aaf13ad` | `READY_FOR_BETA_SUBMISSION` | No non-exempt encryption; all 20 localized What to Test notes applied |

The intended external group is `External Testing` (`df40f833-12c7-4411-b28d-122690045c58`). No build-39 group attachment or beta-review submission has been made. Attaching through Helm submits an eligible external build by default, so that step requires explicit authorization.

No build 39 is selected on a public App Store version, and no 2.2 App Review submission has been made.

## Remaining release gates

- Explicitly authorize external TestFlight submission, then attach all three builds with tester auto-notification disabled and verify their resulting beta-review states.
- Install the accepted build on clean iPhone and iPad test devices and repeat the Styles, App Icon, purchase-gating, selection, and persistence acceptance checks.
- Confirm the clean-install Mac, Watch, and Apple TV defaults on their target devices.
- Complete Apple TV hardware acceptance with the Siri Remote and a supported controller, including gameplay, pause/exit, settings, Game Center, purchase/restore, VoiceOver, and SharePlay with a real FaceTime group.
- Obtain fluent approval for the exact 20-locale What's New and What to Test copy and complete human visual approval of the Apple TV screenshots.
- Select and submit build 39 on the coordinated public versions only after every release gate passes and the owner explicitly authorizes App Review submission.

Use the [release candidate workflow](../docs/21-release-candidate-workflow.md) to resume.

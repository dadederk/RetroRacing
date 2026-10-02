# RetroRapid! 2.0 (36) candidate

## Source and scope

- Candidate prepared on `master` on 2026-10-02. Record the exact approved source commit when making the final public archive; beta archives predate the release-preparation commit but no runtime source changed afterward.
- Shipping targets: iPhone/iPad with embedded Apple Watch, and macOS. tvOS and visionOS remain outside the public release.
- iOS archive: `build/testflight-2.0/RetroRacingUniversal-iOS.xcarchive`, Xcode 27.1 beta `27A9269`, iOS 27.1 SDK, signed and uploaded.
- macOS archive: `build/testflight-2.0/RetroRacingUniversal-macOS.xcarchive`, stable Xcode 27.0 (`27A266a`), universal arm64/x86_64, signed, exported, and uploaded.
- Both archives use marketing version 2.0 and build 36. The iOS build includes SharePlay, iPhone Duo tabletop layout, and hinge-change pause behavior.

## Validation and metadata

- `./retrorapid test package`: 122 tests passed under the selected Xcode 27.1 beta on October 2.
- `./retrorapid check` and `./retrorapid metadata apply --dry-run`: passed on October 2.
- `./retrorapid test`: shared and Universal iOS simulator tests passed under Xcode 27.1 beta on October 2.
- App Store What's New in all 20 locales on each editable iOS/macOS 2.0 draft matched [the release catalog](../metadata/retrorapid-v2.0-candidate.json) exactly on readback (40 matches).
- Full localized [TestFlight notes](beta-notes/en-US/whats-new.txt) were accepted by Helm for all 20 build localizations on **each** platform (40 successful updates). Helm offers no TestFlight note readback; this is verified by successful mutation responses.
- The strict `./retrorapid localization audit --require-approval` gate reports **all 20 locales** still need fluent approval of the revised copy. Manual gameplay acceptance remains open.

## App Store Connect state on 2026-10-02

| Platform | Build | TestFlight | App Store 2.0 draft |
|---|---|---|---|
| iOS with Watch | `f1bd1225-9636-473b-9b02-99ae58ccc50e` | External Testing group `df40f833-12c7-4411-b28d-122690045c58`; `WAITING_FOR_BETA_REVIEW`; no automatic tester notification | `af16a599-2c7b-4ccb-90bd-9aaa9b8d1e1e` |
| macOS | `798f1f47-654a-47c5-bfe7-0e52cff57a94` | External Testing group `df40f833-12c7-4411-b28d-122690045c58`; `WAITING_FOR_BETA_REVIEW`; no automatic tester notification | `cb14d6f6-5e4e-4088-b6d0-c3e883850398`; build 36 selected |

- Both App Store drafts are `PREPARE_FOR_SUBMISSION` with `MANUAL` release control. The iOS draft still has build 35 selected; the macOS draft now has the stable-Xcode 2.0 (36) build selected. No 2.0 App Review submission or public release has been initiated.
- Both 2.0 (36) builds have no non-exempt encryption. Apple currently accepts the Xcode 27.1 beta iOS toolchain for TestFlight, while its latest public App Store notice covers stable Xcode 27.0. Do not treat the beta iOS archive as the public release build; see [Apple's release notes](https://developer.apple.com/help/app-store-connect/release-notes/).
- The Mac export first failed with `Failed to Use Accounts` / missing `Xcode-Username` inside the command sandbox. Running the same stable-Xcode export with normal Xcode account access succeeded on October 2; the package uploaded, processed, and was configured through Helm.
- The SharePlay featuring nomination was submitted by the user; its ID and exact submitted copy have not yet been captured locally. The Major Update In-App Event `6818452317` is `WAITING_FOR_REVIEW` in submission `15e913ab-a4a9-40e0-a308-4678ab34a492`, with en-US pixel-art assets. Its other 19 localizations remain open.

## Remaining acceptance

- Verify Duo partial-fold layout, hinge pause and resume, and unfolding on a working simulator or physical device.
- Run a two-person SharePlay race on devices, including the free allowance behavior, and smoke-test macOS.
- Approve localized copy and screenshots against the release. Helm confirms complete screenshot uploads in 20 iPhone/Watch locales and 18 iPad/Mac locales; `pl` and `tr` lack iPad and Mac captures. The current Studio screenshot storyboard still claims four retro eras, but 2.0 exposes LCD and Pocket; replace or omit that slide and inspect the attached draft screenshots. Choose the final source commit and an App Store-eligible iOS 27.1 toolchain. Build and attach a new eligible iOS archive, then submit both platforms for App Review after acceptance, retaining manual release control.

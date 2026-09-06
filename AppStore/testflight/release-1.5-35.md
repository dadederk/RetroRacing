# RetroRapid! 1.5 (35) candidate

## Source and scope

- Source: `0fe0ead` on `master` (includes flag cleanup commit `d5f3bb2`).
- Platforms: iPhone/iPad with embedded Apple Watch, plus macOS.
- Toolchain: stable Xcode 26.6; iOS/macOS/watchOS 26.5 SDKs; Release configuration.
- Archives: `build/testflight-1.5-35/RetroRacingUniversal-iOS.xcarchive` and `RetroRacingUniversal-macOS.xcarchive`.
- App Store-eligible exports preserve marketing version 1.5 and build 35.
- SharePlay enabled; LCD/Pocket gallery; Pocket requires Unlimited Plays outside watchOS. Cartridge/CRT and alternate icons remain hidden. TV/Vision are excluded.
- Includes corrected first-day allowance copy and Rate visibility after entitlement resolution.

## Validation

- Combined source: 781 shared/Universal unit tests passed on iPhone 17, iOS 26.5 simulator.
- Gallery UI test passed: only LCD/Pocket, future styles/icons absent, LCD selected, Pocket requires Unlimited Plays and opens its purchase prompt.
- Scripts package tests, full repository checks, and documentation checks passed.
- Both signed archives succeeded; embedded Watch version/build and all SDK identifiers verified.
- App Store descriptions, promotional text, keywords, and What's New applied and read back exactly for all 20 locales on both editable 1.5 drafts (40 matches).
- Localized TestFlight source: [beta-notes](beta-notes/en-US/whats-new.txt); canonical App Store source: [candidate catalog](../metadata/retrorapid-v1.5-candidate.json).

## App Store Connect outcome

| Platform | Processed build ID | App Store draft |
|---|---|---|
| iOS with Watch | `e35380bd-33f2-4ea2-ba07-c85a84ee6a04` | `af16a599-2c7b-4ccb-90bd-9aaa9b8d1e1e` |
| macOS | `b82c45e8-e515-4911-883a-ed8c91e592b9` | `cb14d6f6-5e4e-4088-b6d0-c3e883850398` |

- Both uploads succeeded and processing completed with audience `app-store-eligible`.
- Export compliance is set to no non-exempt encryption; both builds report `READY_FOR_BETA_SUBMISSION` (external beta status).
- All 20 TestFlight beta localizations per build returned successful update responses.
- Both processed builds are selected on the corresponding editable 1.5 drafts. Neither App Store nor external beta review was submitted.
- Apple rejected manual Mac build assignment to the existing Internal Testing group with HTTP 422, “Builds cannot be assigned to this internal group.” Helm does not expose automatic-distribution state; internal tester availability remains unverified. No tester invitations or automatic-notification settings were changed.

## Public-release acceptance still open

- Physical-device SharePlay acceptance for advertised device combinations, especially Mac.
- Fluent review and exact-digest approval of the locale packages; structural checks do not imply language approval.
- Screenshots checked against release-1 themes and current copy before public submission.
- No App Store submission or public release is authorized by this upload record.

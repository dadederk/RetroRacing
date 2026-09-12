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
- Export compliance is set to no non-exempt encryption.
- All 20 TestFlight beta localizations per build returned successful update responses.
- Both processed builds are selected on the corresponding editable 1.5 drafts. App Store review has not been submitted.
- Live TestFlight verification on 2026-09-07 confirms both build-35 binaries are assigned to Internal Testing and External Testing. iOS with embedded Watch reports `IN_BETA_TESTING`.
- With user authorization, macOS build 35 was attached to External Testing and submitted for beta review on 2026-09-07. Helm reported success for both actions; readback confirms `WAITING_FOR_BETA_REVIEW`. External Mac testers still use build 34 while review is pending.
- No tester invitations or automatic-notification settings were changed. tvOS and visionOS have no uploaded TestFlight builds and remain outside this candidate.

## Release-note editorial follow-up (2026-09-06)

- Revised the App Store and TestFlight notes in all 20 locales using the approved English copy: Pocket's Unlimited Plays requirement, free styles on Apple Watch, extensively redrawn artwork, smoother gameplay, the full new-language list, and a short recap of earlier updates.
- Regional wording follows the localization contract: informal French for France, formal Canadian French, Valencian Catalan, distinct Portuguese variants, and separate Chinese scripts and vocabulary. Purchase names match the locale glossary; style names remain unchanged.
- TestFlight testing prompts now ask whether gameplay stays smooth during longer runs. Each beta note starts with its matching App Store release notes.
- Helm accepted all 40 App Store draft updates and all 40 TestFlight build-localization updates. Exact App Store readback matched the canonical What's New, description, promotional text, and keywords in all 40 platform/locale combinations. TestFlight verification is based on successful update responses. Build 35 itself is unchanged.
- Regenerated metadata documents and all 20 review sheets. Localization audit, length checks, and documentation checks passed. Fluent approval remains pending against the new content digests.

## Public-release acceptance still open

- Physical-device SharePlay acceptance for advertised device combinations, especially Mac.
- Fluent review and exact-digest approval of the locale packages; structural checks do not imply language approval.
- Screenshots checked against release-1 themes and current copy before public submission.
- No App Store submission or public release is authorized by this upload record.

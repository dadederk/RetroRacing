# RetroRapid! 2.0 (37) release candidate

## Source and artifacts

- Source commit: `2572121` (`Prepare RetroRapid 2.0 build 37 for release.`). No runtime source changed after the 2.0 (36) beta; this commit advances the Universal and embedded Watch build numbers together.
- Toolchain: Xcode 27.1 RC, build `27A9275`, selected at `/Applications/Xcode_27_1_RC.app/Contents/Developer`. Apple listed this RC as accepted for App Store and TestFlight uploads on 2026-10-05.
- iOS and embedded Watch archive: `build/testflight-2.0-37/RetroRacingUniversal-iOS.xcarchive`; both bundle versions are 2.0 (37), with iOS 27.1 SDK and team `PV9S9FTZF2` signing.
- Mac archive: `build/testflight-2.0-37/RetroRacingUniversal-macOS.xcarchive`; version 2.0 (37), macOS 27.0 SDK, universal `arm64` and `x86_64`, same team signing.
- Both archives were exported and uploaded through Xcode on 2026-10-06. App Store Connect finished processing both as App Store eligible. Both builds declare no non-exempt encryption.

## Validation and copy

- `./retrorapid test package`: 122 tests passed on 2026-10-06.
- `./retrorapid check`: passed, including metadata, localization structure, screenshots source sync, assets, and documentation.
- `./retrorapid test`: shared and Universal iOS simulator suites passed under Xcode 27.1 RC.
- `./retrorapid metadata apply --dry-run`: catalog valid for 20 locales on each platform. Fresh Helm localization readback exactly matched the canonical 2.0 What's New for all 40 platform/locale entries.
- All 20 localized TestFlight What to Test notes were applied to each 2.0 (37) build. A subsequent Helm dry run returned `noop` for all 40 entries. These are separate from the App Store What's New fields.
- Removed the inaccurate four-theme screenshot from 20 locales on both iPhone sizes, 18 iPad locales, and 18 Mac locales: 76 deletions in total. Helm readback confirms no slide 8 on iPhone/iPad and no corresponding slide 7 on Mac. The remaining screenshots still need human visual approval. Polish and Turkish iPad/Mac sets remain absent and use App Store fallback.

## App Store Connect on 2026-10-06

| Platform | Build ID | External TestFlight | App Store version / review submission |
|---|---|---|---|
| iOS with Watch | `44f37090-1991-4598-b47f-ab6f6814a4c4` | `IN_BETA_TESTING` in External Testing; automatic tester notification requested | Version `af16a599-2c7b-4ccb-90bd-9aaa9b8d1e1e`; draft submission `c3cac1f1-7f06-4abe-a76a-9e94ac55bb41` |
| macOS | `f583f844-9257-472a-8b37-ce0539c848c9` | `IN_BETA_TESTING` in External Testing; automatic tester notification requested | Version `cb14d6f6-5e4e-4088-b6d0-c3e883850398`; draft submission `be5fa6a0-21ef-408a-a51a-ba04aab51fc1` |

Both App Store versions are `READY_FOR_REVIEW` and select their matching build 37. On October 6, Helm changed both from manual to `SCHEDULED` release, no earlier than **2026-10-16 12:00 UTC** (13:00 UK time), with seven-day phased release enabled. Fresh version readback confirmed `SCHEDULED` and `earliestReleaseDate` `813844800` for each platform; the Helm update confirmed the phased-release setting. Both review submissions contain the 2.0 version and are `READY_FOR_REVIEW`; **neither has been submitted to App Review or released publicly**. The approved Major Update event is `6818452317`, scheduled to start 2026-10-23 at 11:52 UTC.

## Remaining gates and release timing

- Owner acceptance: partially folded Duo layout, hinge move/pause/settle/resume and unfolding; two-device SharePlay, including no daily-play charge; Mac controls and purchase behavior; accessibility; screenshots and review notes. Physical Duo hardware may not be available before launch, so record simulator evidence and verify on hardware when available.
- `./retrorapid localization audit --require-approval` still fails for all 20 locales. Fluent approval of the exact revised copy is required by the [submission quality gate](../docs/03-submission-quality-gate.md).
- Review the remaining screenshot pixels and crops. Decide whether to add native Polish and Turkish iPad/Mac screenshots or accept App Store locale fallback. Do not re-export the historical four-theme Studio slide for 2.0.
- After the manual gates pass, submit both staged review submissions through Helm. Review approval must precede public release. If both versions are approved by October 16 at 12:00 UTC, scheduled release begins then, and day seven of the automatic-update phase is October 22. Users can manually download from the first day. Apple says iPhone Duo becomes available October 23, not at October 16 preorders. This October 16 schedule therefore completes the phase one day before Duo availability, superseding the earlier October 17 manual-release plan. If App Review approval comes later, release and the phase move later; monitor the event schedule accordingly.

Use the [release candidate workflow](../docs/21-release-candidate-workflow.md) to resume. Do not create another build number unless code or release assets change.

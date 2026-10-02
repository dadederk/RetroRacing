# RetroRapid! 2.0: SharePlay and iPhone Duo release plan

**Status:** In progress on 2026-10-02. The user reports the featuring nomination was submitted; the Major Update In-App Event is `WAITING_FOR_REVIEW` with both pixel-art assets attached. Both App Store drafts are 2.0 with manual release control, and their What's New text matches the 2.0 catalog in all 20 locales per platform. iOS build `f1bd1225-9636-473b-9b02-99ae58ccc50e` and macOS build `798f1f47-654a-47c5-bfe7-0e52cff57a94` are `WAITING_FOR_BETA_REVIEW` in External Testing. Device and public-release acceptance remain open.
**App/account:** `6758641625` / AccessibilityUpTo11. **Public target:** 2026-10-23, subject to an App Store-eligible Xcode 27.1 release and acceptance gates.

## Decision and critical path

1. **Submitted on 2026-10-02:** The user reports the [SharePlay-led App Enhancements nomination](../../Docs/iphone-duo-shareplay-nomination-2026.md) was submitted. Record its ID and exact submitted copy in [the nominations archive](09-featuring-nominations-submitted.md) when available. Once Apple approves the event, attach it to the nomination if it was not attached at submission.
2. **Next:** Complete Duo visual and hinge QA plus a real two-person SharePlay race. Resolve the black frames from the iOS 27.1 Duo simulator or use physical hardware. Both platform builds are awaiting external beta review; testers were not automatically notified.
3. **When Apple accepts Xcode 27.1 for App Store distribution:** Rebuild the approved commit with that toolchain, complete the App Store quality gate, submit iOS and macOS 2.0 for review, and release manually no earlier than the intended date. Do not submit the beta-built archive as a public build.

Apple says iPhone Duo arrives with iOS 27.1 on October 23. The selected Xcode is `/Applications/Xcode_27_1_Beta.app`, Xcode 27.1 beta `27A9269`; `/Applications/Xcode.app` is stable 27.0. The project compiles hinge handling only for an iOS 27.1 SDK. Apple currently lists 27.1 beta uploads for TestFlight testing; its latest App Store eligibility notice covers stable Xcode 27.0. See [Apple's release notes](https://developer.apple.com/help/app-store-connect/release-notes/) and [Duo announcement](https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/).

This 2.0 release uses the major number for its new iOS 27.1 SDK work. Alternate icons and Cartridge/CRT personalization, Apple TV distribution, and visionOS gameplay remain in the later gated stages of [the staged release plan](../staged_release_plan.md) (working slots 2.1, 2.2, and 2.3). Do not include them in the 2.0 build, screenshots, or store promises.

## Automation and ownership

| Step | Preferred path | Gate |
|---|---|---|
| Featuring nomination | Submitted manually on October 2; record its ID and edit it to attach the approved event later if needed. | Helm has no nomination command; exact submitted copy and ID are not yet recorded. |
| Release source | Universal and embedded Watch versions are 2.0 (36) for beta; allocate a higher build number for the final archive. Preserve existing staged changes. | Select and record a final source commit after manual acceptance. |
| Store copy | `AppStore/metadata/retrorapid-v2.0-candidate.json` contains cumulative 2.0 copy in all 20 locales. The repository metadata pipeline validated and applied it through Helm on 2026-10-02; all 40 What's New entries matched on readback. | Both drafts retain their localization IDs and are 2.0; replace attached build 35 with an eligible 2.0 build before review. Fluent/native review of the new translations remains open. |
| Beta notes | All 20 `AppStore/testflight/beta-notes/*/whats-new.txt` files now contain the cumulative 2.0 notes and localized Duo behavior. | The current upload script sends the same note files to iOS and macOS; Duo is explicitly qualified as an iPhone Duo feature. |
| Beta archive and upload | iOS 2.0 (36) was archived and uploaded with Xcode 27.1 beta; macOS 2.0 (36) was archived and uploaded with stable Xcode 27.0. Both are awaiting external beta review through Helm. | Apple's current 27.1 beta notice names iOS/iPadOS TestFlight only. Device acceptance and beta review remain open. |
| Public archive and review | Rebuild with an App Store-eligible Xcode 27.1 toolchain; use Helm for version/build attachment and review submissions. | Both draft versions already use `MANUAL`; validate both final builds and avoid a second submission for the same version. |

Both 2.0 (36) builds have no non-exempt encryption, full localized TestFlight notes in all 20 locales, and are awaiting external beta review in group `df40f833-12c7-4411-b28d-122690045c58`. Helm accepted every TestFlight note update; TestFlight notes have no readback through this CLI. Exact App Store What's New readback matched the catalog in all 40 platform/locale combinations. The two editable 2.0 version IDs are iOS `af16a599-2c7b-4ccb-90bd-9aaa9b8d1e1e` and macOS `cb14d6f6-5e4e-4088-b6d0-c3e883850398`. Their release type is `MANUAL`. The Mac draft selects build 36; the iOS draft retains build 35 until an App Store-eligible iOS 27.1 archive is available. Re-read these values immediately before any write. Helm's active account is AccessibilityUpTo11. Follow [the current release workflow](../../AppStore/docs/21-release-candidate-workflow.md) for later submissions.

The Xcode 27.1 beta installation includes the iOS 27.1 SDK and an available iPhone Duo simulator. The project is set to 2.0 (36). The iOS archive succeeded with Xcode 27.1 beta at `build/testflight-2.0/RetroRacingUniversal-iOS.xcarchive`. The macOS archive succeeded with stable Xcode 27.0 at `build/testflight-2.0/RetroRacingUniversal-macOS.xcarchive`; export/upload succeeded on October 2 with normal Xcode account access outside the command sandbox. Both builds are processed in App Store Connect.

The exact build and App Store Connect state is in [the 2.0 (36) candidate record](../../AppStore/testflight/release-2.0-36.md).

The en-US addition to the existing App Store What's New, after its SharePlay paragraph:

> Built for iOS 27 and iPhone Duo. Fold iPhone Duo into a horizontal tabletop pose and the road moves above the hinge while score, lives, and controls sit below. Sustained hinge movement pauses the race; once the device settles, tap Play to resume the same run. Opening the device restores the regular layout without restarting.

The same user benefit and a fold/pause/resume/unfold testing prompt are in all 20 TestFlight note files. The cumulative SharePlay, Styles, artwork, polish, and localization notes remain. Structural checks and store readback passed; fluent review is still needed.

## Acceptance before each external step

- **Nomination:** Lead with free, two-player iPhone/iPad SharePlay races and the fact they never consume daily solo plays. Mention iOS 27 and Duo tabletop play and hinge pause second. Use the draft's 2026-10-23 target, verify any supplemental URLs in a signed-out browser, and add a public demo or TestFlight link later if available. A nomination can be edited after submission.
- **TestFlight:** `./retrorapid test package`, `./retrorapid check`, and the iOS 27.1 Duo simulator unit tests passed on October 2. The signed iOS archive also succeeded with Watch embedding. Complete visual Duo QA: captured frames are black even on the simulator Home screen after terminating RetroRapid, so this is not yet an app-specific rendering diagnosis. Inspect the beta simulator in a working graphical session or test physical hardware. Then verify the partially folded layout, hinge pause, settle/resume, and unfolding without restarting. On two real iPhones/iPads, validate invitation, countdown, shared traffic, results/rematch, disconnect, and a free friend race after solo plays are exhausted. Confirm macOS smoke tests and no Debug-only controls.
- **App Review:** Confirm the selected final archive is App Store eligible and that iOS/macOS metadata, screenshots, review notes, IAP behavior, accessibility, and exact-digest locale approvals meet [the submission gate](../../AppStore/docs/03-submission-quality-gate.md) and [localization review gate](../../AppStore/docs/19-localization-quality-review.md). Test physical Duo hardware when available; if it is unavailable before submission, record simulator evidence and verify on hardware as soon as possible. Use manual release to prevent approval from publishing early.

## In-App Event decision

The **Major Update** event `6818452317` is waiting for review with its en-US copy, pixel-art card and details artwork, deep link, and territories in App Store Connect. Apple currently schedules advance discoverability for October 16, the event start for October 23, and its end for November 13. Decide whether the one-week preview is intentional; move the schedule if the 2.0 release slips. Test the deep link and native-review localized copy. After event approval, attach it to the submitted featuring nomination if needed. See the [event brief](../../AppStore/docs/20-major-update-2-0-in-app-event.md), [Apple's event guidance](https://developer.apple.com/app-store/in-app-events/), and [the existing campaign draft](10-shareplay-release-campaign.md).

## Completion record

Record nomination ID/status, beta and final build IDs, SDK/Xcode build versions, validated devices, metadata catalog and locale approvals, App Review submission IDs, chosen release control, and public availability in the App Store and campaign documents. The release is complete only when 2.0 is public on its intended shipping platforms.

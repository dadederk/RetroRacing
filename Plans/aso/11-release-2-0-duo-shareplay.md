# RetroRapid! 2.0: SharePlay and iPhone Duo release plan

**Status, 2026-10-06:** Xcode 27.1 RC build 37 is uploaded, processed, and selected on both iOS/Watch and Mac App Store drafts. Both review submissions are staged but **not submitted**. Both versions use manual release with a seven-day phase. The Major Update In-App Event is approved; the SharePlay-led featuring nomination was submitted by the user. See the [2.0 (37) candidate record](../../AppStore/testflight/release-2.0-37.md) for exact IDs, tests, archives, and outstanding gates.

**App/account:** `6758641625` / AccessibilityUpTo11. **Duo availability:** October 23, 2026, according to [Apple's announcement](https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/); October 16 is preorders. Apple [accepts Xcode 27.1 RC uploads](https://developer.apple.com/help/app-store-connect/release-notes/) for TestFlight and the App Store.

## Rollout decision

- After App Review approval, manually release iOS and Mac 2.0 on **October 17** at the chosen launch time. Day seven of Apple's phase then falls on **October 23**, when iPhone Duo first reaches customers. Apple's phase covers automatic updates; anyone can manually download 2.0 from the first day. If review approval misses October 17, revise the rollout and event schedule rather than assuming the phase can catch up.
- The approved Major Update event `6818452317` is discoverable from October 16, starts October 23 at 11:52 UTC, and ends November 13. The event's exact schedule is in the [event brief](../../AppStore/docs/20-major-update-2-0-in-app-event.md). Its deep link and event crops still need a device check.
- This major version covers the new iOS 27.1 SDK work, free SharePlay friend races, and iPhone Duo tabletop play with hinge-change pause. Alternate icons and Cartridge/CRT personalization, Apple TV distribution, and visionOS gameplay remain in later gated stages of [the staged release plan](../staged_release_plan.md) (working slots 2.1, 2.2, and 2.3).

## Remaining critical path

1. Complete the manual gameplay checks on **build 37**: Duo partial fold, moving hinge, pause/settle/resume/unfold; a real two-person SharePlay race, including no charge against daily solo plays; Mac controls; purchase behavior; accessibility and review deep link. Use the iOS 27.1 simulator until physical Duo hardware is available, then verify on hardware as soon as possible. Record results in the [candidate record](../../AppStore/testflight/release-2.0-37.md).
2. Obtain fluent approval of the revised release copy in all 20 locales. The strict localization audit currently reports every locale pending. Visually approve the remaining App Store screenshots and decide whether Polish/Turkish iPad and Mac need native uploads or can use fallback. The old four-theme screenshot was removed from all attached iPhone, iPad, and Mac sets on October 6; do not re-upload it for 2.0.
3. When the [submission quality gate](../../AppStore/docs/03-submission-quality-gate.md) passes, submit the staged iOS and Mac review submissions through Helm. Both drafts already select App Store-eligible 2.0 (37) builds and are `READY_FOR_REVIEW`, with manual/phased release configured. Do not create duplicate submissions.
4. Monitor App Review and the event. Both build 37 uploads are `IN_BETA_TESTING` in the existing External Testing group, with automatic tester notification requested. Record launch timing before the October 17 manual release.

## Featuring and campaign

- The user submitted the [SharePlay-led App Enhancements nomination](../../Docs/iphone-duo-shareplay-nomination-2026.md) on October 2. The nomination ID and exact submitted copy are not yet recorded. Attach the approved event if it was not attached at submission.
- The event is a **Major Update** with pixel-art card and details images, free SharePlay emphasis, and iPhone Duo as a secondary feature. Only en-US event localization is submitted; other event languages remain open. See [the event brief](../../AppStore/docs/20-major-update-2-0-in-app-event.md).
- Keep public 2.0 copy limited to iPhone/iPad, Apple Watch companion, and Mac. tvOS and visionOS targets do not create public gameplay promises.

The release is complete only when 2.0 is approved and public on both shipping App Store platforms, the seven-day phase reaches day seven, and the event remains aligned with actual app availability.

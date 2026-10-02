# RetroRapid! 2.0 featuring nomination: SharePlay + iPhone Duo

**Status:** User reports the nomination was submitted on 2026-10-02. Nomination ID and exact submitted copy have not yet been recorded; Helm does not expose featuring nominations.
**Account:** AccessibilityUpTo11.
**App:** RetroRapid: Retro Arcade Racer (`6758641625`).
**Target:** Version 2.0, aligned with iPhone Duo customer availability on Friday 2026-10-23 if the App Store-eligible iOS 27.1 toolchain and release gates are ready.
**Nomination deadline:** Friday 2026-10-02 for Apple's recommended three-week lead time. Submit earlier if possible.

## App Store Connect fields

| Field | Value |
|---|---|
| Name | `RetroRapid! 2.0: Free Friend Races + iPhone Duo` (47/60) |
| Type | App Enhancements |
| Publish date | 2026-10-23 |
| Platforms | iOS (iPhone), iOS (iPad) |
| Related app | 6758641625 only |
| Relevant countries/regions | All regions where the iOS app is available. |
| Localizations | Keep the app's available localizations selected. |
| Initial market launch | No |
| New In-App Event | Yes. Event `6818452317` is awaiting review; attach it to the submitted nomination after approval if it was not attached at submission. |
| Pre-order | No |

### Nomination description (866/1,000 characters)

```text
RetroRapid! 2.0 brings friends into the race. On iPhone and iPad, tap Play with Friends to start a live two-player SharePlay match. You start together, face the same traffic, see each other's scores and lives, and compare a shared win, loss, or tie at the finish. A rematch starts only when both players agree.

Every friend race is free. It never uses either player's daily solo plays, and it remains available when that allowance is exhausted. This is a permanent part of the game, not a limited-time offer.

Version 2.0 also embraces iOS 27 and iPhone Duo. In a partially folded tabletop pose, the road fills the upper display while score, lives, and controls sit below the hinge. Sustained fold movement pauses an active run; once the device settles, tapping Play resumes that same run. Opening the device restores the regular layout without restarting the race.
```

### Helpful details (489/500 characters)

```text
Editor quick test: 1) On two iPhones or iPads, tap Play with Friends, accept a SharePlay invite, and race. Check the shared countdown, live scores and lives, result, and mutual rematch. 2) Use up the solo daily plays; a friend race still starts without a purchase. 3) On iPhone Duo, fold to a horizontal tabletop pose to place the road above the hinge and controls below it. Move the hinge during a run; the race pauses, then resumes from the same point when you tap Play after it settles.
```

## Supplemental materials

Submit the nomination without waiting for media. Add a public, non-expiring Duo demo or TestFlight link to the submitted nomination when the new build is ready. Apple permits edits after submission. The developer supplied these posts as supporting references; anonymous access could not be verified in this review, so check them in a signed-out browser before using them in the form:

1. [iPhone Duo angled Arcade Mode demo](https://x.com/dadederk/status/2101783995688042760?s=20)
2. [iPhone Duo layout demo](https://x.com/dadederk/status/2101046304017125768?s=20)
3. [SharePlay demo](https://x.com/dadederk/status/2080217503393841156?s=20)
4. [App Store product page](https://apps.apple.com/app/apple-store/id6758641625)

The App Store product page is public but does not yet demonstrate the new update. Apple's form allows up to five URLs.

## Release facts and gates

- Apple announced preorders for 2026-10-16, first customer availability for 2026-10-23 in more than 70 countries and regions including the UK and US, and a second wave on 2026-10-30.
- Apple recommends submitting and finalizing the featuring plan at least three weeks before the planned publish date.
- iPhone Duo ships with iOS 27.1. The selected Xcode is stable 27.0; Xcode 27.1 beta (`27A9269`) is installed separately. The hinge API is compiled into the game only with the iOS 27.1 SDK. Apple has announced Xcode 27.1 beta upload support for TestFlight, but has not announced public App Store eligibility for that beta. iOS 2.0 (36) was uploaded on October 2, processed, and is ready for TestFlight beta submission. The separate stable Xcode installation still reports missing App Store Connect access for the Mac archive export.
- App Store Connect has editable iOS and macOS 2.0 drafts with their localization IDs preserved. Both still have older build 35 attached. The nomination does not submit an app version for App Review.
- Both 2.0 drafts now use manual release control, so approval will not publish the update before the intended date.
- Keep the release gates in [AppStore submission quality gate](../AppStore/docs/03-submission-quality-gate.md) and [staged release plan](../Plans/staged_release_plan.md). Test the iPhone Duo pose and pause on the 27.1 simulator and a physical device when available, and complete real-device SharePlay acceptance before shipping.
- Local validation on 2026-10-02: the iOS 27.1 Duo simulator tests, `./retrorapid test package`, `./retrorapid check`, and a signed iOS archive pass. Visual inspection remains unresolved: simulator screenshots are black even on the Home screen after the app is terminated, so the display/capture environment must be restored before accepting the Duo layout and hinge behavior. Real-device SharePlay and physical Duo acceptance remain open.
- Major Update In-App Event `6818452317` is waiting for review with the pixel-art media pair attached. It frames the arrival of the 2.0 experience as a launch moment, following the accepted Xarra precedent. Attach it to the submitted nomination after Apple approves it if it was not attached at submission. `Friend Race Week` remains a separate, uncreated campaign idea.
- The App Store Connect iOS and macOS drafts have been advanced to 2.0 with manual release control. Localized 2.0 What's New copy was applied on 2026-10-02. Both drafts still point to older build 35 until a new eligible build is uploaded and attached.
- Record the nomination ID and exact submitted copy in [submitted nominations](../Plans/aso/09-featuring-nominations-submitted.md) when available. Follow the [2.0 execution plan](../Plans/aso/11-release-2-0-duo-shareplay.md).

## Sources

- [Apple iPhone Duo announcement](https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/)
- [Apple nomination instructions](https://developer.apple.com/help/app-store-connect/manage-featuring-nominations/nominate-your-app-for-featuring/)
- [Apple nomination field limits](https://developer.apple.com/help/app-store-connect/reference/nominations/nominations-template/)
- [App Store Connect September 18 TestFlight update](https://developer.apple.com/help/app-store-connect/release-notes/)
- [Apple In-App Event guidance](https://developer.apple.com/app-store/in-app-events/)
- [Duo input contract](../Requirements/input_handling.md), [pause contract](../Requirements/launch_flow.md), [SharePlay contract](../Requirements/shareplay_multiplayer.md), and [free-play contract](../Requirements/monetization.md)

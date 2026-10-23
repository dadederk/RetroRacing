# Staged release plan

**Status:** Stage 2 is the active coordinated RetroRapid! **2.2** release. It combines the personalization work with the Apple TV launch so iPhone, iPad, embedded Apple Watch, Mac, and Apple TV can ship together on the same version and build. Its committed release default exposes Cartridge and CRT, and the iPhone/iPad App Icon gallery no longer has a rollout flag. Stage 1 is RetroRapid! 2.0, the SharePlay and iPhone Duo release in [the 2.0 plan](aso/11-release-2-0-duo-shareplay.md). Vision Pro remains a separately gated later stage and public “Coming Soon” placeholder.

The coordinated release now has 2.2 (38) TestFlight candidates for iOS with embedded Watch, macOS, and tvOS. App Store Connect processed all three as App Store eligible and applied all 20 localized beta notes to each build. Apple TV is in external testing; iOS and macOS are awaiting beta review. Editable public 2.2 versions now exist for all three platforms, and Helm applied the full 20-locale metadata catalog; the first tvOS release correctly has no What's New field. The complete 20-locale Apple TV screenshot source set is in Screenshot Studio. This does not close the stage: iOS/macOS beta approval, fluent copy approval, full screenshot review, personalization acceptance, and Apple TV hardware acceptance remain required before any public App Review submission. See [the 2.2 candidate record](../AppStore/testflight/release-2.2-38.md).

The public 2.0 RC uses build 37 from Xcode 27.1 RC: iOS with embedded Watch and macOS are uploaded, processed, selected on their App Store drafts, and staged in separate review submissions. The 20-locale App Store What's New and TestFlight notes are verified on both platforms. Both build 37 uploads are in external testing. Fluent approval, visual screenshot review, and real-device SharePlay and Duo acceptance remain before App Review submission. See [the candidate record](../AppStore/testflight/release-2.0-37.md) for exact states and IDs.

Earlier 1.5/build-35 evidence remains in [its historical record](../AppStore/testflight/release-1.5-35.md). GitHub branch protection and Xcode Cloud setup are separate infrastructure work; neither is claimed as a gate that has already passed.

## Outcome and release sequence

Integrate the feature work into `master` (the repository's default branch) with committed release defaults and local Debug overrides. Keep one development line; tag each public release and record its platform build numbers. Do not rename `master` as part of this work.

| Stage / working version | Public additions | Held back |
|---|---|---|
| 1: 2.0 SharePlay + Duo | Free iPhone/iPad friend races with SharePlay; iPhone Duo tabletop play and hinge pause; iPhone/iPad/Mac and embedded Watch updates; Styles gallery with LCD and Pocket; artwork, accessibility, and localization improvements | Cartridge/CRT themes, alternate icons and icon gallery, Apple TV and Vision Pro gameplay launches |
| 2: 2.2 personalization + Apple TV | Cartridge (8-bit) and CRT (16-bit) in the Styles gallery; iPhone/iPad alternate icons and icon gallery; Apple TV distribution, Disc platform style, remote/controller UX, and validated TV SharePlay | Vision Pro launch; Disc/Polygon gameplay styles outside their platform policies |
| 3: Vision Pro (later working slot) | Vision Pro distribution, Classic and spatial solo gameplay, Polygon style, validated Classic SharePlay | Spatial multiplayer remains out of scope |

The 2.2 version and build 38 are fixed for the current coordinated candidate; later version numbers remain planning slots rather than release dates or promises. Xarra's major-version convention applies when a new SDK drives a later release. The 2.0 release includes removal of the legacy Simplified Grid option; retain and verify Big Cars and accessible road rendering. Personalization does not automatically expand Disc/Polygon gameplay availability beyond existing platform policy. Icon selection remains independent from gameplay style.

## First implementation: minimum release gates

- Introduce a small shared, typed release configuration and a protocol-backed observable feature-availability provider, injected by platform composition roots. Do not build a remote flag service or a generic experimentation system.
- Use independent flags for new retro themes and platform SharePlay availability. The Styles gallery ships in stage 1 and needs no rollout flag or fallback picker. Keep the existing Disc/Polygon experimental capabilities but resolve them through the same configuration boundary. The temporary alternate-icon flag is removed for stage 2; injected platform eligibility is the permanent gallery boundary.
- Commit stage-1 defaults: new retro themes, alternate icons/gallery, and non-platform Disc/Polygon experiments off; SharePlay on for iPhone/iPad/macOS and off for Watch. Keep TV/Vision feature testing available in their own targets; exclude both archives from stage 1 and include TV only when the coordinated stage-2 gates pass.
- Debug defaults must mirror production. Expose `Release default`, `Enabled`, and `Disabled` per applicable flag, plus Reset All Overrides. Persist only explicit Debug overrides; Release ignores all stored overrides and uses committed values.
- Remove the temporary icon flag/service seam for stage 2. Injected iPhone/iPad eligibility controls gallery availability and must not grant Unlimited Plays ownership; use existing purchase simulation separately.
- Apply theme overrides immediately in Settings. SharePlay overrides require relaunch and are labeled accordingly because composition chooses the transport service at launch. Disable gameplay-affecting flag controls during active solo/SharePlay sessions so catalog changes cannot alter a live run.
- With new themes off, expose only LCD/Pocket: LCD is the iPhone/iPad/Mac default and Pocket is the Watch default. Preserve baseline free/purchased access. With the flag on, use the existing Cartridge/CRT platform defaults and entitlement policy.
- Keep the existing Styles gallery as the selector, backed by the filtered catalog and entitlement resolver. In stage 1 it previews and selects only LCD/Pocket, keeping LCD free and requiring Unlimited Plays for Pocket outside watchOS. Future themes must be absent from previews, accessibility entry points, and benefit copy, not shown as locked teasers. In stage 2, eligible iPhone/iPad builds always show the icon gallery and its benefit copy.
- Preserve explicit stored theme IDs when a known theme is temporarily unavailable; render the accessible platform fallback without overwriting the preference. Unknown IDs fall back safely. Turning features back on restores the preference if entitled. Existing accessible user selections beat new stage-2 defaults.
- Screenshot capture uses the committed release configuration, not a developer's saved overrides. Future-feature test fixtures must opt in explicitly and must not feed 2.0 store exports.
- Update the routed theming, icons, debug, monetization, screenshot, and launch contracts alongside implementation. Keep runtime changes small and reuse shared UI/services.

## Stage 1: 2.0 critical path

1. Finish the [active 2.0 release plan](aso/11-release-2-0-duo-shareplay.md) and [candidate record](../AppStore/testflight/release-2.0-37.md). Both iOS with embedded Watch and macOS have processed build 37 uploads, localized TestFlight notes, and external testing access.
2. Validate SharePlay on two physical devices in both host roles, including Mac combinations where advertised. Verify Duo's partially folded layout, hinge pause, settle/resume, and unfold on a working simulator or device. Record device, OS, build, and result; unit tests alone do not close these gates.
3. Freeze the 20-locale [canonical metadata](../AppStore/metadata/retrorapid-v2.0-candidate.json), obtain fluent approval for revised copy, and check screenshots against the LCD/Pocket and Duo claims. Keep alternate icons, Apple TV, and Vision Pro gameplay out of 2.0 public copy.
4. Both platforms now select App Store-eligible Xcode 27.1 RC build 37 and use automatic release no earlier than October 16 at 12:00 UTC, with a seven-day phase. Pass the [submission quality gate](../AppStore/docs/03-submission-quality-gate.md), then submit both staged App Review submissions. If approved by the scheduled time, day seven falls on October 22, ahead of iPhone Duo availability on October 23.
5. Once 2.0 is public, tag the exact source commit and record platform builds, release defaults, availability, and initial crash/SharePlay/purchase observations. Promote the personalization stage only after its own gate passes.

## Validation and acceptance

- Run `./retrorapid test package`, `./retrorapid check`, and `./retrorapid test`; add the affected Watch tests and Mac build/tests. Build all implemented targets to catch shared-code regressions, without making TV/Vision launch acceptance a stage-1 dependency.
- Test default/override/reset behavior and Release isolation with stored Debug values present. Test each remaining rollout flag independently and verify the permanent iPhone/iPad icon-gallery eligibility.
- Test fresh install and upgrades with LCD/Pocket, a saved hidden theme, unavailable purchase state, purchase/restore, entitlement loss, and an installed alternate icon. Verify hidden catalogs cannot be selected via stale objects or alternate entry points.
- Verify stage-1 iPad/Mac defaults remain LCD and Watch remains Pocket. The Styles gallery contains exactly LCD/Pocket, with LCD free and Pocket locked for free users outside watchOS, plus the Unlimited Plays prompt and correct selected state. Expanded previews cover locked and entitlement-loading states, purchase, and restore. Check VoiceOver and largest text sizes in the two-theme gallery. The icon gallery and future-theme upsells are absent; the available paid Style remains a purchase benefit.
- On actual Release builds, exercise invite/cancel/retry, countdown and matching traffic, live scores/lives, elimination/spectating, win/loss/tie, mutual rematch, disconnect/background/exit, guest difficulty restoration, and third-participant rejection. Verify free matches at zero solo plays never consume a play.
- Smoke-test solo gameplay, leaderboards, achievements, purchase/restore, landscape, all font choices, VoiceOver, largest text sizes, and Big Cars across shipping platforms.
- Release acceptance requires passing code checks, real-device SharePlay evidence for advertised platforms, correct release-only feature visibility, approved current copy, and screenshots matching the archived build. Tests cannot establish real GroupActivities transport readiness alone.

## Later stages and cleanup

- Stage 2 has flipped the new-retro-themes default and permanently exposes the alternate-icons gallery on eligible iPhone/iPad builds. The temporary icon rollout flag is removed. The existing Styles gallery gains Cartridge/CRT without changing the selection flow. Stage 2 also adds TV distribution after remote focus, pause/exit, Game Center, purchase, and real-device SharePlay acceptance, with Disc following its TV platform policy. Preserve existing selections; new defaults apply when no valid choice exists. Icon system-surface and appearance QA, expanded-gallery accessibility checks, entitlement checks, upgrade tests, and TV hardware acceptance remain release gates. Submit and release iOS with embedded Watch, macOS, and tvOS together as 2.2 (38).
- Stage 3 adds Vision archive/submission actions only after physical-device spatial placement, visibility/comfort, repeated 2D/3D handoff, accessibility, purchase, and Classic SharePlay acceptance. Replace the placeholder only then.
- After each stage is publicly stable, remove that stage's temporary release flags, obsolete fallback UI, and override keys/tests. Retain platform eligibility, entitlements, unshipped experiment gates, and coverage for the permanent behavior.
- The 2.0 featuring nomination and Major Update event have their own review and schedule; coordinate them with app availability. New videos, keyword experiments, and broader marketing work remain separate decisions. Existing documented submission requirements remain explicit until revised with authorization.

## Related plans and operations

- [Plans index](INDEX.md) and [SharePlay campaign](aso/10-shareplay-release-campaign.md).
- [App Store hub](../AppStore/README.md), [submission gate](../AppStore/docs/03-submission-quality-gate.md), [localization review](../AppStore/docs/19-localization-quality-review.md), and [release lane](../AppStore/docs/17-xcode-cloud-releases.md).
- [SharePlay contract](../Requirements/shareplay_multiplayer.md), [Mac QA plan](shareplay_macos_plan.md), [theme contract](../Requirements/theming_system.md), and [Vision acceptance](../Requirements/visionos_gameplay.md).

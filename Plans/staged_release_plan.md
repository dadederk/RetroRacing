# Staged release plan

**Status:** Stage 1 is now RetroRapid! **2.0**, the SharePlay and iPhone Duo release in [the active 2.0 plan](aso/11-release-2-0-duo-shareplay.md). The former 1.5 SharePlay launch sequence was superseded before public submission. The following stages remain planned and gated; their working version slots are 2.1, 2.2, and 2.3, subject to Apple SDK timing and release acceptance.

The 2.0 candidate uses build 36: iOS with embedded Watch and macOS are both awaiting external TestFlight review. The 20-locale App Store What's New and TestFlight notes are applied on both platforms; the Mac 2.0 draft selects build 36. Fluent approval, screenshot alignment, real-device SharePlay and Duo acceptance, and an App Store-eligible Xcode 27.1 toolchain remain public-release gates. See [the candidate record](../AppStore/testflight/release-2.0-36.md) for exact states and IDs.

Earlier 1.5/build-35 evidence remains in [its historical record](../AppStore/testflight/release-1.5-35.md). GitHub branch protection and Xcode Cloud setup are separate infrastructure work; neither is claimed as a gate that has already passed.

## Outcome and release sequence

Integrate the feature work into `master` (the repository's default branch) with committed release defaults and local Debug overrides. Keep one development line; tag each public release and record its platform build numbers. Do not rename `master` as part of this work.

| Stage / working version | Public additions | Held back |
|---|---|---|
| 1: 2.0 SharePlay + Duo | Free iPhone/iPad friend races with SharePlay; iPhone Duo tabletop play and hinge pause; iPhone/iPad/Mac and embedded Watch updates; Styles gallery with LCD and Pocket; artwork, accessibility, and localization improvements | Cartridge/CRT themes, alternate icons and icon gallery, Apple TV and Vision Pro gameplay launches |
| 2: 2.1 personalization (working slot) | Cartridge (8-bit) and CRT (16-bit) in the Styles gallery; iPhone/iPad alternate icons and icon gallery | Apple TV and Vision Pro launches; Disc/Polygon gameplay styles on existing shipping platforms |
| 3: 2.2 Apple TV (working slot) | Apple TV distribution, Disc platform style, remote/controller UX, validated TV SharePlay | Vision Pro launch |
| 4: 2.3 Vision Pro (working slot) | Vision Pro distribution, Classic and spatial solo gameplay, Polygon style, validated Classic SharePlay | Spatial multiplayer remains out of scope |

These version numbers are planning slots, not release dates or promises. Xarra's major-version convention applies when a new SDK drives a release; choose the final marketing version for each later stage at its own gate. The 2.0 release includes removal of the legacy Simplified Grid option; retain and verify Big Cars and accessible road rendering. Personalization does not automatically expand Disc/Polygon gameplay availability beyond existing platform policy. Icon selection remains independent from gameplay style.

## First implementation: minimum release gates

- Introduce a small shared, typed release configuration and a protocol-backed observable feature-availability provider, injected by platform composition roots. Do not build a remote flag service or a generic experimentation system.
- Use independent flags for new retro themes, alternate icons/gallery, and platform SharePlay availability. The Styles gallery ships in stage 1 and needs no rollout flag or fallback picker. Keep the existing Disc/Polygon experimental capabilities but resolve them through the same configuration boundary. Treat the icon feature and its gallery as one capability.
- Commit stage-1 defaults: new retro themes, alternate icons/gallery, and non-platform Disc/Polygon experiments off; SharePlay on for iPhone/iPad/macOS and off for Watch. Keep TV/Vision feature testing available in their own targets; exclude their archives from stages 1 and 2.
- Debug defaults must mirror production. Expose `Release default`, `Enabled`, and `Disabled` per applicable flag, plus Reset All Overrides. Persist only explicit Debug overrides; Release ignores all stored overrides and uses committed values.
- Reuse the current icon flag/service seam rather than maintaining competing resolvers. Remove its permanent Release-off behavior in favor of the committed icon release default. Feature availability must not grant Unlimited Plays ownership; use existing purchase simulation separately.
- Apply theme/icon overrides immediately in Settings. SharePlay overrides require relaunch and are labeled accordingly because composition chooses the transport service at launch. Disable gameplay-affecting flag controls during active solo/SharePlay sessions so catalog changes cannot alter a live run.
- With new themes off, expose only LCD/Pocket: LCD is the iPhone/iPad/Mac default and Pocket is the Watch default. Preserve baseline free/purchased access. With the flag on, use the existing Cartridge/CRT platform defaults and entitlement policy.
- Keep the existing Styles gallery as the selector, backed by the filtered catalog and entitlement resolver. In stage 1 it previews and selects only LCD/Pocket, keeping LCD free and requiring Unlimited Plays for Pocket outside watchOS. Future themes must be absent from previews, accessibility entry points, and benefit copy, not shown as locked teasers. Icons off hides its gallery and benefit copy without changing the installed icon.
- Preserve explicit stored theme IDs when a known theme is temporarily unavailable; render the accessible platform fallback without overwriting the preference. Unknown IDs fall back safely. Turning features back on restores the preference if entitled. Existing accessible user selections beat new stage-2 defaults.
- Screenshot capture uses the committed release configuration, not a developer's saved overrides. Future-feature test fixtures must opt in explicitly and must not feed 2.0 store exports.
- Update the routed theming, icons, debug, monetization, screenshot, and launch contracts alongside implementation. Keep runtime changes small and reuse shared UI/services.

## Stage 1: 2.0 critical path

1. Finish the [active 2.0 release plan](aso/11-release-2-0-duo-shareplay.md) and [candidate record](../AppStore/testflight/release-2.0-36.md). Both iOS with embedded Watch and macOS must have processed beta builds with localized TestFlight notes, followed by the requested external review state.
2. Validate SharePlay on two physical devices in both host roles, including Mac combinations where advertised. Verify Duo's partially folded layout, hinge pause, settle/resume, and unfold on a working simulator or device. Record device, OS, build, and result; unit tests alone do not close these gates.
3. Freeze the 20-locale [canonical metadata](../AppStore/metadata/retrorapid-v2.0-candidate.json), obtain fluent approval for revised copy, and check screenshots against the LCD/Pocket and Duo claims. Keep alternate icons, Apple TV, and Vision Pro gameplay out of 2.0 public copy.
4. When Apple accepts the required Xcode 27.1 SDK for App Store submission, archive the approved source with a new build number, then select the eligible builds on both platform drafts. Pass the [submission quality gate](../AppStore/docs/03-submission-quality-gate.md) before App Review. Both versions retain manual release control.
5. Once 2.0 is public, tag the exact source commit and record platform builds, release defaults, availability, and initial crash/SharePlay/purchase observations. Promote the personalization stage only after its own gate passes.

## Validation and acceptance

- Run `./retrorapid test package`, `./retrorapid check`, and `./retrorapid test`; add the affected Watch tests and Mac build/tests. Build all implemented targets to catch shared-code regressions, without making TV/Vision launch acceptance a stage-1 dependency.
- Test default/override/reset behavior and Release isolation with stored Debug values present. Test each rollout flag independently and the combined stage-1/stage-2 configurations.
- Test fresh install and upgrades with LCD/Pocket, a saved hidden theme, unavailable purchase state, purchase/restore, entitlement loss, and an installed alternate icon. Verify hidden catalogs cannot be selected via stale objects or alternate entry points.
- Verify stage-1 iPad/Mac defaults remain LCD and Watch remains Pocket. The Styles gallery contains exactly LCD/Pocket, with LCD free and Pocket locked for free users outside watchOS, plus the Unlimited Plays prompt and correct selected state. Expanded previews cover locked and entitlement-loading states, purchase, and restore. Check VoiceOver and largest text sizes in the two-theme gallery. The icon gallery and future-theme upsells are absent; the available paid Style remains a purchase benefit.
- On actual Release builds, exercise invite/cancel/retry, countdown and matching traffic, live scores/lives, elimination/spectating, win/loss/tie, mutual rematch, disconnect/background/exit, guest difficulty restoration, and third-participant rejection. Verify free matches at zero solo plays never consume a play.
- Smoke-test solo gameplay, leaderboards, achievements, purchase/restore, landscape, all font choices, VoiceOver, largest text sizes, and Big Cars across shipping platforms.
- Release acceptance requires passing code checks, real-device SharePlay evidence for advertised platforms, correct release-only feature visibility, approved current copy, and screenshots matching the archived build. Tests cannot establish real GroupActivities transport readiness alone.

## Later stages and cleanup

- Stage 2 flips the new-retro-themes and alternate-icons/gallery defaults together after icon system-surface and appearance QA, expanded-gallery accessibility checks, entitlement checks, and upgrade tests. The existing Styles gallery gains Cartridge/CRT without changing the selection flow. Preserve existing selections; new defaults apply when no valid choice exists.
- Stage 3 adds TV archive/submission actions only after remote focus, pause/exit, Game Center, purchase, and real-device SharePlay acceptance. Ship Disc according to its TV platform policy.
- Stage 4 adds Vision archive/submission actions only after physical-device spatial placement, visibility/comfort, repeated 2D/3D handoff, accessibility, purchase, and Classic SharePlay acceptance. Replace the placeholder only then.
- After each stage is publicly stable, remove that stage's temporary release flags, obsolete fallback UI, and override keys/tests. Retain platform eligibility, entitlements, unshipped experiment gates, and coverage for the permanent behavior.
- The 2.0 featuring nomination and Major Update event have their own review and schedule; coordinate them with app availability. New videos, keyword experiments, and broader marketing work remain separate decisions. Existing documented submission requirements remain explicit until revised with authorization.

## Related plans and operations

- [Plans index](INDEX.md) and [SharePlay campaign](aso/10-shareplay-release-campaign.md).
- [App Store hub](../AppStore/README.md), [submission gate](../AppStore/docs/03-submission-quality-gate.md), [localization review](../AppStore/docs/19-localization-quality-review.md), and [release lane](../AppStore/docs/17-xcode-cloud-releases.md).
- [SharePlay contract](../Requirements/shareplay_multiplayer.md), [Mac QA plan](shareplay_macos_plan.md), [theme contract](../Requirements/theming_system.md), and [Vision acceptance](../Requirements/visionos_gameplay.md).

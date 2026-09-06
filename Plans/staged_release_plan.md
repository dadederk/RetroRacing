# Four-stage release plan

**Status:** Release-1 gates implemented and locally validated for integration into `master`. Public release preparation remains pending.

Implemented evidence: stable Xcode 26.6 Release builds pass for iOS/Watch, Mac, and Vision Pro; Apple TV builds with the available Xcode 27 SDK (stable tvOS component is absent). The full shared/Universal unit-test suites, Scripts tests, the full repository check, and two gallery UI tests pass (release-1 free LCD/Pocket flow and expanded icon preview). Generated spatial model containers were refreshed; exported USDA scene contents are byte-identical to the originals. The strict readiness audit reports all 20 locale packages still need fluent approval; real-device SharePlay QA also remains a release gate.

Read-only App Store Connect verification on 2026-09-06: iOS/macOS 1.4.2 are live; both platforms already have editable 1.5 drafts. Release 1 targets 1.5. GitHub reports `master` is not protected; cloud merge protection still needs setup before relying on that lane. This integration uses the completed local validation, not a claimed cloud result. The active local toolchain is Xcode 27 beta; distribution validation must use the installed stable Xcode 26.6.

## Outcome and release sequence

Integrate the feature work into `master` (the repository's default branch) with committed release defaults and local Debug overrides. Keep one development line; tag each public release and record its platform build numbers. Do not rename `master` as part of this work.

| Stage | Public additions | Held back |
|---|---|---|
| 1: Play with Friends | iPhone/iPad/macOS SharePlay; Styles gallery with LCD and Pocket only; existing-theme artwork refresh; landscape, launch, Game Center, font, accessibility, and general UX improvements; reviewed localization changes | Cartridge/CRT themes, alternate icons and icon gallery, Apple TV and Vision Pro launches |
| 2: Personalization | Cartridge (8-bit) and CRT (16-bit) added to the Styles gallery; iPhone/iPad alternate icons and icon gallery | Apple TV and Vision Pro launches; Disc/Polygon gameplay styles on existing shipping platforms |
| 3: Apple TV | Apple TV distribution, Disc platform style, remote/controller UX, validated TV SharePlay | Vision Pro launch |
| 4: Vision Pro | Vision Pro distribution, Classic and spatial solo gameplay, Polygon style, validated Classic SharePlay | Spatial multiplayer remains out of scope |

Release 1 includes the current code refinements, including removal of the legacy Simplified Grid option; retain and verify Big Cars and accessible road rendering. Release 2 does not automatically expand Disc/Polygon gameplay availability beyond existing platform policy. Icon selection remains independent from gameplay style.

## First implementation: minimum release gates

- Introduce a small shared, typed release configuration and a protocol-backed observable feature-availability provider, injected by platform composition roots. Do not build a remote flag service or a generic experimentation system.
- Use independent flags for new retro themes, alternate icons/gallery, and platform SharePlay availability. The Styles gallery ships in stage 1 and needs no rollout flag or fallback picker. Keep the existing Disc/Polygon experimental capabilities but resolve them through the same configuration boundary. Treat the icon feature and its gallery as one capability.
- Commit stage-1 defaults: new retro themes, alternate icons/gallery, and non-platform Disc/Polygon experiments off; SharePlay on for iPhone/iPad/macOS and off for Watch. Keep TV/Vision feature testing available in their own targets; exclude their archives from stages 1 and 2.
- Debug defaults must mirror production. Expose `Release default`, `Enabled`, and `Disabled` per applicable flag, plus Reset All Overrides. Persist only explicit Debug overrides; Release ignores all stored overrides and uses committed values.
- Reuse the current icon flag/service seam rather than maintaining competing resolvers. Remove its permanent Release-off behavior in favor of the committed icon release default. Feature availability must not grant Unlimited Plays ownership; use existing purchase simulation separately.
- Apply theme/icon overrides immediately in Settings. SharePlay overrides require relaunch and are labeled accordingly because composition chooses the transport service at launch. Disable gameplay-affecting flag controls during active solo/SharePlay sessions so catalog changes cannot alter a live run.
- With new themes off, expose only LCD/Pocket: LCD is the iPhone/iPad/Mac default and Pocket is the Watch default. Preserve baseline free/purchased access. With the flag on, use the existing Cartridge/CRT platform defaults and entitlement policy.
- Keep the existing Styles gallery as the selector, backed by the filtered catalog and entitlement resolver. In stage 1 it previews and selects only LCD/Pocket, preserving the verified baseline where both LCD and Pocket are free. Future themes must be absent from previews, accessibility entry points, and benefit copy, not shown as locked teasers. Icons off hides its gallery and benefit copy without changing the installed icon.
- Preserve explicit stored theme IDs when a known theme is temporarily unavailable; render the accessible platform fallback without overwriting the preference. Unknown IDs fall back safely. Turning features back on restores the preference if entitled. Existing accessible user selections beat new stage-2 defaults.
- Screenshot capture uses the committed release configuration, not a developer's saved overrides. Future-feature test fixtures must opt in explicitly and must not feed release-1 store exports.
- Update the routed theming, icons, debug, monetization, screenshot, and launch contracts alongside implementation. Keep runtime changes small and reuse shared UI/services.

## Release 1 critical path

1. **Confirm public baseline first.** Read App Store Connect versions, attached builds, platform availability, and current locale status. Reconcile the project version (currently 1.5), staged 1.6 metadata, and historical docs. Select the next unused marketing version and record the mapping; do not infer a shipped commit from `master` or invent a release tag.
2. **Implement gates on the newer feature branch.** `feature/improve-tv-and-vision-apps-with-new-themes` already includes all of `feature/assets-update`; merge it once after validation. Do not separately merge or discard the assets branch. Preserve unrelated work and use the repository merge gate.
3. **Verify release-1 behavior.** Run the checks below, fix release-blocking regressions, merge into `master`, then verify the resulting commit and archive that exact commit. Do not expand this step into icon redesign, platform-launch polish, or an unrelated refactor.
4. **Validate real SharePlay early.** iPhone-to-iPad in both host roles; Mac-to-Mac; Mac hosting iPhone/iPad and the reverse. Record device/OS/build and pass/fail evidence. Existing Mac QA is pending; do not claim it passed. The default scope includes Mac SharePlay. A blocking Mac failure requires an explicit scope decision; the platform flag permits deferral without holding back iPhone/iPad code.
5. **Prepare accurate store material.** Reuse the canonical metadata pipeline with the confirmed version. Lead with free two-player SharePlay and include only shipped refinements. The LCD/Pocket Styles gallery may appear in release-1 screenshots and copy. Remove stage-2/TV/Vision claims and replace screenshots showing held-back styles or the icon gallery. Keep unchanged accurate assets where possible.
6. **Close existing editorial gates.** Audit exact-digest locale approvals; Turkish/Polish were last documented as needing review. Freeze release-1 copy before review and capture. Follow the existing submission and localization gates; do not silently waive them for speed. Report any approval or keyword-baseline blocker immediately for a deliberate user decision.
7. **Internal TestFlight, then submission.** Archive iOS with embedded Watch and macOS only, using the existing release lane and a supported distribution toolchain. Smoke-test those Release builds, resolve blockers, prepare concrete review notes, then obtain release authorization before submitting/publishing. Leave the existing Vision placeholder unchanged in this release.
8. **Record the shipment.** Once public, tag the exact source commit and record marketing version, platform builds, release defaults, and validation evidence. Check initial crash reports, SharePlay failures, and purchase/restore regressions after launch; no monitoring automation is created by this plan.

## Validation and acceptance

- Run `./retrorapid test package`, `./retrorapid check`, and `./retrorapid test`; add the affected Watch tests and Mac build/tests. Build all implemented targets to catch shared-code regressions, without making TV/Vision launch acceptance a stage-1 dependency.
- Test default/override/reset behavior and Release isolation with stored Debug values present. Test each rollout flag independently and the combined stage-1/stage-2 configurations.
- Test fresh install and upgrades with LCD/Pocket, a saved hidden theme, unavailable purchase state, purchase/restore, entitlement loss, and an installed alternate icon. Verify hidden catalogs cannot be selected via stale objects or alternate entry points.
- Verify stage-1 iPad/Mac defaults remain LCD and Watch remains Pocket. The Styles gallery contains exactly LCD/Pocket, both free, with correct selected state. Expanded previews cover locked and entitlement-loading states, purchase, and restore. Check VoiceOver and largest text sizes in the two-theme gallery. The icon gallery and future-theme upsells are absent.
- On actual Release builds, exercise invite/cancel/retry, countdown and matching traffic, live scores/lives, elimination/spectating, win/loss/tie, mutual rematch, disconnect/background/exit, guest difficulty restoration, and third-participant rejection. Verify free matches at zero solo plays never consume a play.
- Smoke-test solo gameplay, leaderboards, achievements, purchase/restore, landscape, all font choices, VoiceOver, largest text sizes, and Big Cars across shipping platforms.
- Release acceptance requires passing code checks, real-device SharePlay evidence for advertised platforms, correct release-only feature visibility, approved current copy, and screenshots matching the archived build. Tests cannot establish real GroupActivities transport readiness alone.

## Later stages and cleanup

- Stage 2 flips the new-retro-themes and alternate-icons/gallery defaults together after icon system-surface and appearance QA, expanded-gallery accessibility checks, entitlement checks, and upgrade tests. The existing Styles gallery gains Cartridge/CRT without changing the selection flow. Preserve existing selections; new defaults apply when no valid choice exists.
- Stage 3 adds TV archive/submission actions only after remote focus, pause/exit, Game Center, purchase, and real-device SharePlay acceptance. Ship Disc according to its TV platform policy.
- Stage 4 adds Vision archive/submission actions only after physical-device spatial placement, visibility/comfort, repeated 2D/3D handoff, accessibility, purchase, and Classic SharePlay acceptance. Replace the placeholder only then.
- After each stage is publicly stable, remove that stage's temporary release flags, obsolete fallback UI, and override keys/tests. Retain platform eligibility, entitlements, unshipped experiment gates, and coverage for the permanent behavior.
- Optional launch events, featuring campaigns, new videos, keyword experiments, and broader marketing work must not become new dependencies for stage 1. Existing documented submission requirements remain explicit until revised with authorization.

## Related plans and operations

- [Plans index](INDEX.md) and [SharePlay campaign](aso/10-shareplay-release-campaign.md).
- [App Store hub](../AppStore/README.md), [submission gate](../AppStore/docs/03-submission-quality-gate.md), [localization review](../AppStore/docs/19-localization-quality-review.md), and [release lane](../AppStore/docs/17-xcode-cloud-releases.md).
- [SharePlay contract](../Requirements/shareplay_multiplayer.md), [Mac QA plan](shareplay_macos_plan.md), [theme contract](../Requirements/theming_system.md), and [Vision acceptance](../Requirements/visionos_gameplay.md).

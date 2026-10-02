# Submission Quality Gate & Helm Rollout

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-10-02

**See also:** [Release candidate workflow](21-release-candidate-workflow.md) · [Metadata copy](05-metadata-copy.md) · [Live listing](02-listing-snapshot.md) · [Swift scripts](../../Scripts/README.md)

---

## Current candidate: 2.0 (36)

The active catalog is [retrorapid-v2.0-candidate.json](../metadata/retrorapid-v2.0-candidate.json), applied to the editable iOS/macOS 2.0 drafts in all 20 locales per platform. The [2.0 (36) candidate record](../testflight/release-2.0-36.md) contains current build, beta, and toolchain status. SharePlay and iPhone Duo lead this release; tvOS and visionOS gameplay remain outside the public shipping scope.

App Store What's New matches the catalog on readback for all 40 platform/locale combinations. Full TestFlight notes were accepted on both processed builds for all 20 locales. Both iOS and macOS builds await external beta review; the Mac App Store draft selects build 36, while the iOS draft still selects build 35. `DRAFT_APPLIED` means copy is staged, not approved or public. Before App Review, complete Duo/SharePlay device acceptance, Mac smoke testing, fluent locale approval, and screenshot review against the features actually shipping. The current Studio storyboard still promises four retro eras; 2.0 exposes LCD and Pocket, so that screenshot copy and imagery must be corrected or omitted before submission. Helm confirms uploaded screenshots in all 20 iPhone/Watch locales and 18 iPad/Mac locales; Polish and Turkish have no iPad/Mac uploads. Attach only builds made with an App Store-accepted toolchain, keep manual release control, and use the [release candidate workflow](21-release-candidate-workflow.md) for the sequence.

## Public submission gate

- The exact selected source commit, Xcode build/SDK, marketing version, and build number are recorded for iOS with embedded Watch and macOS. Apple accepts each archive's toolchain for public App Store submission.
- Both platform-specific draft versions have the intended build selected, `MANUAL` release control, correct export compliance, review contact, and review notes. Neither version is submitted merely because a TestFlight build passed beta review.
- The canonical metadata catalog matches readback for every affected locale on both platform drafts. Fluent reviewers have approved the exact revised text; TestFlight What to Test is checked separately on each uploaded build.
- Current screenshots and previews reflect shipped UI, supported devices, and the localized story. Public claims exclude unshipped tvOS and visionOS gameplay.
- SharePlay, Duo fold/pause/resume behavior, Mac controls, accessibility, and Unlimited Plays purchase behavior have the required manual acceptance evidence. Any remaining limitation is recorded in the candidate file before the owner decides on submission.
- The featuring nomination and In-App Event, if used, have IDs, statuses, deep link, and dates recorded. The event start is compatible with the planned app availability.

## Historical 1.5 submission snapshot


Status on 2026-07-26: `DRAFT_APPLIED`. Name, subtitle, keywords, promotional text, description, and What's New are applied to both 1.5 drafts across all 18 App Store listing locales. Today's pass updated What's New to list the full v1.5 localization set, removed em dashes from App Store metadata copy, and replaced the Simplified Chinese hidden keyword `watch` with native Chinese terms to resolve the related-language duplicate with Brazilian Portuguese. TestFlight beta-note source files were updated locally, but no build-level TestFlight notes were changed in App Store Connect in this pass. Two issues should still be closed before submission:

1. **The new keyword fields are not rank-validated yet.** The live fields are now archived, but there is still no Appfigures/Krankie baseline. The staged keywords remain hypotheses until current rankings and demand are captured.
2. **The public visionOS placeholder remains unresolved.** The staged metadata correctly omits Apple Vision, but the public listing still exposes a "Coming Soon" experience. Decide whether to remove it from sale or complete the gameplay experience.

Screenshots are no longer a submission-gate blocker for iPhone English variants (all four are fully rendered and uploaded), but the following still need work before submitting: Mac (missing 2 of 7 slides in English, 0 in Spanish/Catalan), iPad (0 rendered), Apple Watch (0 rendered, sequence still `BLOCKED`), and Spanish/Catalan iPhone (rendered exports were cleared from disk after the 2026-07-17 copy tightening and need re-export even though old renders are still live on the ASC draft). See `06-screenshots.md` for the exact per-locale breakdown.

Ready now:

- Capture the remaining App Store Connect analytics and keyword/rank baseline.
- Regenerate the remaining localized screenshot exports from the aligned source (Mac, iPad, Apple Watch, and Spanish/Catalan iPhone).

Ready to submit when:

- At least the core US/GB and Spain keyword hypotheses have been checked.
- The public visionOS availability decision is resolved and recorded.
- The rendered screenshots and uploaded order match the approved story on every platform and locale.

### Helm Rollout Status

Helm CLI path: `/Applications/Helm.app/Contents/Helpers/helm-asc`

Repeatable Swift command: `apply-retrorapid-metadata` in the root `Scripts` package.

On 2026-06-24, `helm-asc` / the apply script updated the editable **1.5** drafts for **iOS** and **macOS** across **en-US**, **en-GB**, **en-AU**, **en-CA**, **es-ES**, **ca**, and **es-MX**. On 2026-07-17, `helm-asc localization <id> update --name ...` applied the new `RetroRapid: Retro Arcade Racer` name for the four English locales; the shared App Info HTTP 409 that blocked this on 2026-06-25 no longer reproduced. Subtitles already matched the staged natural-language values from the earlier pass. On 2026-07-19, description and What's New (plus a re-sync of keywords/promotional text) were applied on **both** iOS and macOS for all seven then-active locales, with social proof in the description and the standardized "sharpens...racing polish" What's New everywhere. On 2026-07-26, direct `helm-asc localization <id> update` calls applied the full-locale What's New copy to **all 18 locales** on both platform drafts, updated English and Spanish review attribution punctuation in descriptions, and updated `zh-Hans` keywords. The 2026-07-26 Helm pass used argv-based subprocess calls rather than the Swift apply wrapper because `apply-retrorapid-metadata` previously mangled accented characters for Spanish/Catalan locales (see `04-metadata-strategy.md` decision notes). Nothing has been submitted to App Review.

| Platform | Draft version ID | Applied locales |
|---|---|---|
| iOS 1.5 | `af16a599-2c7b-4ccb-90bd-9aaa9b8d1e1e` | `en-US`, `en-GB`, `en-AU`, `en-CA`, `de-DE`, `nl-NL`, `it`, `fr-FR`, `fr-CA`, `es-ES`, `ca`, `es-MX`, `ja`, `ko`, `pt-BR`, `pt-PT`, `zh-Hant`, `zh-Hans` |
| macOS 1.5 | `cb14d6f6-5e4e-4088-b6d0-c3e883850398` | `en-US`, `en-GB`, `en-AU`, `en-CA`, `de-DE`, `nl-NL`, `it`, `fr-FR`, `fr-CA`, `es-ES`, `ca`, `es-MX`, `ja`, `ko`, `pt-BR`, `pt-PT`, `zh-Hant`, `zh-Hans` |

| Field | Status on 1.5 drafts | Notes |
|---|---|---|
| **Name** | `DRAFT_APPLIED` | `RetroRapid: Retro Arcade Racer` for en-US/GB/AU/CA (applied 2026-07-17); localized names applied for the remaining App Store locales. Shared App Info field updates propagate across iOS and macOS automatically. |
| **Subtitle** | `DRAFT_APPLIED` | Verified against the staged catalog on both platforms for all 18 locales. |
| **Keywords** | `DRAFT_APPLIED` | Applied on iOS and macOS for all 18 locales. English variants use split keyword fields for cross-localization. `zh-Hans` no longer repeats `watch` from `pt-BR`. |
| **Promotional text** | `DRAFT_APPLIED` | Shared English conversion copy; Mexico uses `carros`. |
| **Description** | `DRAFT_APPLIED` | Includes offline phrasing plus review/press proof. The 2026-07-26 pass replaced em-dash attribution lines with hyphen attribution in English and Spanish descriptions. |
| **What's New** | `DRAFT_APPLIED` | Applied across both platforms and all 18 locales. Copy names the full v1.5 localization set: German, Dutch, Italian, French (France), French (Canada), Japanese, Korean, Brazilian Portuguese, European Portuguese, Traditional Chinese, and Simplified Chinese. |

```bash
swift run --package-path Scripts generate-metadata-docs --check
swift run --package-path Scripts apply-retrorapid-metadata --dry-run
swift run --package-path Scripts apply-retrorapid-metadata
swift run --package-path Scripts apply-retrorapid-metadata --keywords-only
swift run --package-path Scripts apply-retrorapid-metadata --include-app-info
```

The Swift metadata tool now defaults to `AppStore/metadata/retrorapid-v2.0-candidate.json` and validates it before calling Helm. Planned catalogs may omit draft IDs for local generation, but apply and dry-run commands fail until complete iOS and macOS version-localization IDs are recorded. Use `--catalog` to select another release, `--keywords-only` for a keyword-only sync, and `--include-app-info` to sync shared name/subtitle fields.

For the current candidate, follow the 2.0 gate above and record any unresolved ASO or screenshot decision before submission.

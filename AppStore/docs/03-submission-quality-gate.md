# Submission Quality Gate & Helm Rollout

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-07-19

**See also:** [Metadata copy](05-metadata-copy.md) · [Live listing](02-listing-snapshot.md) · [90-day plan](11-execution-90-day.md) · [Swift scripts](../../Scripts/README.md)

---

## Submission Quality Gate

Status on 2026-07-19: `DRAFT_APPLIED`. Name, subtitle, keywords, promotional text, description, and What's New are all applied to both 1.5 drafts across all seven locales, and What's New is also synced to the TestFlight build 28 What to Test copy. Two issues should still be closed before submission:

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

On 2026-06-24, `helm-asc` / the apply script updated the editable **1.5** drafts for **iOS** and **macOS** across **en-US**, **en-GB**, **en-AU**, **en-CA**, **es-ES**, **ca**, and **es-MX**. On 2026-07-17, `helm-asc localization <id> update --name ...` applied the new `RetroRapid: Retro Arcade Racer` name for the four English locales — the shared App Info HTTP 409 that blocked this on 2026-06-25 no longer reproduced. Subtitles already matched the staged natural-language values from the earlier pass. On 2026-07-19, description and What's New (plus a re-sync of keywords/promotional text) were applied on **both** iOS and macOS for all seven locales — social proof (review quotes + Create with Swift feature) in the description, and the standardized "sharpens...racing polish" What's New everywhere. `apply-retrorapid-metadata` mangled accented characters for `es-ES`/`ca`/`es-MX` (see `04-metadata-strategy.md` decision notes); those three locales were applied with direct `helm-asc localization <id> update` calls instead. Nothing has been submitted to App Review.

| Platform | Draft version ID | en-US | en-GB | en-AU | en-CA | es-ES | ca | es-MX |
|---|---|---|---|---|---|---|---|---|
| iOS 1.5 | `af16a599-2c7b-4ccb-90bd-9aaa9b8d1e1e` | `232e55bc-…44a8` | `56d24d0e-…1405` | `d809f973-…a1e5` | `6911ddd4-…8a3b` | `47a0349f-…3211` | `2cd5433c-…015f` | `1bc0a5d0-…2919` |
| macOS 1.5 | `cb14d6f6-5e4e-4088-b6d0-c3e883850398` | `1d3832e5-…2e04` | `b4ac4ead-…000e` | `78af339a-…32c4` | `114533d9-…926f` | `b64f919a-…02a94` | `f01d2437-…50d7e` | `110854bd-…306e` |

| Field | Status on 1.5 drafts | Notes |
|---|---|---|
| **Name** | `DRAFT_APPLIED` | `RetroRapid: Retro Arcade Racer` for en-US/GB/AU/CA (applied 2026-07-17); Spanish/Catalan names unchanged. Shared App Info field — updating any one locale's localization propagates across iOS and macOS automatically. |
| **Subtitle** | `DRAFT_APPLIED` | Verified against the staged catalog on both platforms for all seven locales. |
| **Keywords** | `DRAFT_APPLIED` | Applied on iOS and macOS for all seven locales. English variants use split keyword fields for cross-localization. |
| **Promotional text** | `DRAFT_APPLIED` | Shared English conversion copy; Mexico uses `carros`. |
| **Description** | `DRAFT_APPLIED` | Includes offline phrasing (*Works offline*, *sin conexión*, *sense connexió*, *sin internet*) plus a review quote and the Create with Swift "Indie App of the Week" pull-quote on all seven locales (applied 2026-07-19). |
| **What's New** | `DRAFT_APPLIED` | Standardized on "This update sharpens RetroRapid! with bug fixes and racing polish..." across both platforms, all seven locales, and the TestFlight build 28 What to Test copy (applied 2026-07-19). |

```bash
swift run --package-path Scripts generate-metadata-docs --check
swift run --package-path Scripts apply-retrorapid-metadata --dry-run
swift run --package-path Scripts apply-retrorapid-metadata
swift run --package-path Scripts apply-retrorapid-metadata --keywords-only
swift run --package-path Scripts apply-retrorapid-metadata --include-app-info
```

The Swift tool reads `AppStore/metadata/retrorapid-v1.5.json` and validates it before calling Helm. By default it applies only version-localization fields. Use `--keywords-only` for a keyword-only sync, `--dry-run` for a non-mutating preflight, and `--include-app-info` to sync the shared name field (now confirmed working).

Do not submit until keyword ranks are baselined and the screenshot story is finalized.

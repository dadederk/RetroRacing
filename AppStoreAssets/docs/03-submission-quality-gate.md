# Submission Quality Gate & Helm Rollout

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-06-24

**See also:** [Metadata copy](05-metadata-copy.md) · [Live listing](02-listing-snapshot.md) · [90-day plan](11-execution-90-day.md) · [Apply script](../scripts/apply_retrorapid_metadata.py)

---

## Submission Quality Gate

Status on 2026-06-24: **draft metadata staged, not ready to submit yet**. The strategy is sound, but four issues should be closed before submission:

1. **The shared App Info fields are locked.** The recommended `RetroRapid:` names and natural-language subtitles pass validation, but App Store Connect currently rejects `helm-asc` name/subtitle updates with HTTP 409 despite editable 1.5 drafts. Keywords on those drafts are already applied.
2. **The new keyword fields are not rank-validated yet.** The live fields are now archived, but there is still no Appfigures/Krankie baseline. The staged keywords remain hypotheses until current rankings and demand are captured.
3. **The description overpromises visionOS.** The public listing exposes visionOS, but `RetroRacingVisionOS/App/ContentView.swift` is explicitly a "Coming Soon" placeholder. Do not market Apple Vision gameplay until the shipping experience is real.
4. **The screenshot source is not yet aligned with the proposed story.** iPhone/iPad still use the old order, Mac lacks Spanish/Catalan copy, and Apple Watch has no completed screenshot sequence.

Ready now:

- Finalize and update promotional text, which does not require a new app version.
- Capture the remaining App Store Connect analytics and keyword/rank baseline.
- Prepare the screenshot and localization source changes.

Ready to submit when:

- At least the core US/GB and Spain keyword hypotheses have been checked.
- Apple Vision is removed from marketing copy or the visionOS experience is made functional.
- The final name/subtitle read naturally in every localization.
- The screenshot source and uploaded order match the approved story.

### Helm Rollout Status

Helm CLI path: `/Applications/Helm.app/Contents/Helpers/helm-asc`

Repeatable apply script: `AppStoreAssets/scripts/apply_retrorapid_metadata.py`

On 2026-06-24, `helm-asc` / the apply script updated the editable **1.5** drafts for **iOS** and **macOS** across **en-US**, **en-GB**, **en-AU**, **en-CA**, **es-ES**, **ca**, and **es-MX**. Nothing was submitted to App Review.

| Platform | Draft version ID | en-US | en-GB | en-AU | en-CA | es-ES | ca | es-MX |
|---|---|---|---|---|---|---|---|---|
| iOS 1.5 | `af16a599-2c7b-4ccb-90bd-9aaa9b8d1e1e` | `232e55bc-…44a8` | `56d24d0e-…1405` | `d809f973-…a1e5` | `6911ddd4-…8a3b` | `47a0349f-…3211` | `2cd5433c-…015f` | `1bc0a5d0-…2919` |
| macOS 1.5 | `cb14d6f6-5e4e-4088-b6d0-c3e883850398` | `1d3832e5-…2e04` | `b4ac4ead-…000e` | `78af339a-…32c4` | `114533d9-…926f` | `b64f919a-…02a94` | `f01d2437-…50d7e` | `110854bd-…306e` |

| Field | Status on 1.5 drafts | Notes |
|---|---|---|
| **Keywords** | Applied on iOS and macOS for all seven locales | English variants use **split keyword fields** for cross-localization. Spanish split unchanged: `conexion` (es-ES), `internet` (es-MX). |
| **Promotional text** | Applied on iOS and macOS for all seven locales | Shared English conversion copy; Mexico `carros` copy unchanged. |
| **Description** | Applied on iOS and macOS for all seven locales | Includes offline phrasing: *Works offline*, *sin conexión*, *sense connexió*, *sin internet*. |
| **What's New** | Applied on iOS and macOS for all seven locales | Uses the 1.5 polish + Game Center copy from the reference doc. |
| **Name + subtitle** | **Blocked via API** | ASC still returns HTTP 409 for shared App Information updates. Set manually in App Store Connect before submission. |

```bash
python3 AppStoreAssets/scripts/apply_retrorapid_metadata.py
```

The script applies version-localization fields first, then retries shared App Information name/subtitle once per locale.

### Manual App Store Connect fallback

When the API blocks shared App Info (HTTP 409 on name/subtitle), apply fields manually:

1. Run `python3 AppStoreAssets/scripts/apply_retrorapid_metadata.py` first so version-localization fields (keywords, promotional text, description, What's New) land on the editable draft.
2. In App Store Connect → App Information, set **name** and **subtitle** per locale from `05-metadata-copy.md` (staged) or verify against `02-listing-snapshot.md` (live).
3. Re-open the version draft and confirm keywords, promo, description, and What's New match the staged pack.
4. Upload screenshots from Screenshot Studio exports if the storyboard changed (`06-screenshots.md`).
5. Record any manual-only fields and submission date in `11-execution-90-day.md`.

Do not submit until name/subtitle, keywords, and screenshot story are consistent across live intent and the staged pack.

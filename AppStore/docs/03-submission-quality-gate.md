# Submission Quality Gate & Helm Rollout

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-06-25

**See also:** [Metadata copy](05-metadata-copy.md) · [Live listing](02-listing-snapshot.md) · [90-day plan](11-execution-90-day.md) · [Swift scripts](../../Scripts/README.md)

---

## Submission Quality Gate

Status on 2026-06-25: `BLOCKED`. Version-localized metadata is `DRAFT_APPLIED`, but four issues should be closed before submission:

1. **The shared App Info fields are locked.** The recommended `RetroRapid:` names and natural-language subtitles pass validation, but App Store Connect currently rejects `helm-asc` name/subtitle updates with HTTP 409 despite editable 1.5 drafts. Keywords on those drafts are already applied.
2. **The new keyword fields are not rank-validated yet.** The live fields are now archived, but there is still no Appfigures/Krankie baseline. The staged keywords remain hypotheses until current rankings and demand are captured.
3. **The public visionOS placeholder remains unresolved.** The staged metadata correctly omits Apple Vision, but the public listing still exposes a "Coming Soon" experience. Decide whether to remove it from sale or complete the gameplay experience.
4. **Rendered screenshot exports are incomplete.** Source copy is aligned for iPhone, iPad, and Mac, but localized exports and uploads remain incomplete. Apple Watch still needs a finalized sequence.

Ready now:

- Validate or update promotional text, which does not require a new app version.
- Capture the remaining App Store Connect analytics and keyword/rank baseline.
- Regenerate the remaining localized screenshot exports from the aligned source.

Ready to submit when:

- At least the core US/GB and Spain keyword hypotheses have been checked.
- The public visionOS availability decision is resolved and recorded.
- The final name/subtitle read naturally in every localization.
- The rendered screenshots and uploaded order match the approved story.

### Helm Rollout Status

Helm CLI path: `/Applications/Helm.app/Contents/Helpers/helm-asc`

Repeatable Swift command: `apply-retrorapid-metadata` in the root `Scripts` package.

On 2026-06-24, `helm-asc` / the apply script updated the editable **1.5** drafts for **iOS** and **macOS** across **en-US**, **en-GB**, **en-AU**, **en-CA**, **es-ES**, **ca**, and **es-MX**. Nothing was submitted to App Review.

| Platform | Draft version ID | en-US | en-GB | en-AU | en-CA | es-ES | ca | es-MX |
|---|---|---|---|---|---|---|---|---|
| iOS 1.5 | `af16a599-2c7b-4ccb-90bd-9aaa9b8d1e1e` | `232e55bc-…44a8` | `56d24d0e-…1405` | `d809f973-…a1e5` | `6911ddd4-…8a3b` | `47a0349f-…3211` | `2cd5433c-…015f` | `1bc0a5d0-…2919` |
| macOS 1.5 | `cb14d6f6-5e4e-4088-b6d0-c3e883850398` | `1d3832e5-…2e04` | `b4ac4ead-…000e` | `78af339a-…32c4` | `114533d9-…926f` | `b64f919a-…02a94` | `f01d2437-…50d7e` | `110854bd-…306e` |

| Field | Status on 1.5 drafts | Notes |
|---|---|---|
| **Keywords** | `DRAFT_APPLIED` | Applied on iOS and macOS for all seven locales. English variants use split keyword fields for cross-localization. |
| **Promotional text** | `DRAFT_APPLIED` | Shared English conversion copy; Mexico uses `carros`. |
| **Description** | `DRAFT_APPLIED` | Includes offline phrasing: *Works offline*, *sin conexión*, *sense connexió*, *sin internet*. |
| **What's New** | `DRAFT_APPLIED` | Uses the 1.5 polish + Game Center copy from the canonical catalog. |
| **Name + subtitle** | `BLOCKED` | ASC still returns HTTP 409 for shared App Information updates. Set manually in App Store Connect before submission. |

```bash
swift run --package-path Scripts generate-metadata-docs --check
swift run --package-path Scripts apply-retrorapid-metadata --dry-run
swift run --package-path Scripts apply-retrorapid-metadata
swift run --package-path Scripts apply-retrorapid-metadata --keywords-only
swift run --package-path Scripts apply-retrorapid-metadata --include-app-info
```

The Swift tool reads `AppStore/metadata/retrorapid-v1.5.json` and validates it before calling Helm. By default it applies only version-localization fields. Use `--keywords-only` for a keyword-only sync, `--dry-run` for a non-mutating preflight, and `--include-app-info` only when intentionally retrying the currently blocked shared name/subtitle fields.

### Manual App Store Connect fallback

When the API blocks shared App Info (HTTP 409 on name/subtitle), apply fields manually:

1. Run `swift run --package-path Scripts generate-metadata-docs --check`.
2. Run `swift run --package-path Scripts apply-retrorapid-metadata --dry-run`, then apply the version-localization fields.
3. In App Store Connect → App Information, set **name** and **subtitle** per locale from `05-metadata-copy.md`.
4. Re-open the version draft and confirm keywords, promo, description, and What's New match the generated pack.
5. Upload the regenerated Screenshot Studio exports (`06-screenshots.md`).
6. Record manual-only fields and the submission date in `11-execution-90-day.md`.

Do not submit until name/subtitle, keywords, and screenshot story are consistent across live intent and the staged pack.

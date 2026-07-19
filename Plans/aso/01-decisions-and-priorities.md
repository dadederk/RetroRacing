# ASO Decisions & Priorities

Part of [ASO & growth plans](README.md). Index: [retrorapid_aso_growth_plan.md](../retrorapid_aso_growth_plan.md).

Last updated: 2026-07-03
**See also:** [Canonical metadata](../../AppStore/metadata/retrorapid-v1.5.json) · [Generated metadata copy](../../AppStore/docs/05-metadata-copy.md) · [90-day plan](../../AppStore/docs/11-execution-90-day.md)


---

## 1) Confirmed Decisions

- Installed and in-app branding uses **RetroRapid!**. The staged App Store listing name (English locales) uses **RetroRapid: Retro Arcade Racer** — adding the standalone word "retro" since it's otherwise likely not indexed as a separate search token inside the compound brand word `RetroRapid` (2026-07-17).
- **tvOS is not publicly supported.** The public visionOS placeholder remains unresolved and is intentionally omitted from staged marketing copy.
- Accessibility is a core differentiator, but for broad discovery we should lead with the **game fantasy first**, then accessibility.
- Game Center is useful for retention/fun, but not a top-of-funnel differentiator.

## 2) User-Facing Brand Status

As of 2026-06-25, installed display names, in-app copy, screenshot captions, and About/paywall strings use **RetroRapid!**. App Store listing names omit the exclamation mark and add a category phrase. The remaining public mismatch is the live 1.4.2 What's New copy, which still says `RetroRacing`.

Non-user-facing references to `RetroRacing` (bundle identifiers, module names, repo paths) can remain unless/until a technical rebrand is planned.

## 3) Highest-Impact Actions With Rationale

Order: low effort + high impact -> higher effort.

| Priority | Action | Exactly where | Rationale |
|---|---|---|---|
| P1 | Fix the remaining live What's New name mismatch | App Store Connect version metadata | Brand consistency improves trust and perceived quality |
| P1 | Export and upload the aligned gameplay-first screenshot funnel | ScreenshotStudio iPhone/iPad/Mac export sets | Most users decide from the first screenshots; source copy is ready but rendered sets remain incomplete |
| P1 | Keep accessibility as slide 2 or 3, not slide 1 | ScreenshotStudio narrative order | Accessibility remains a differentiator without narrowing top-of-funnel appeal |
| P1 | Complete the staged metadata refresh | App Store Connect listing fields | Version fields are applied; name/subtitle and rank validation remain blocked |
| P1 | Complete accessibility listing fields for 1.3+ | App Store Connect -> Accessibility section | Converts your real product strength into visible store trust signals |
| P2 | Localize screenshot copy for ES/CA (not only metadata) | ScreenshotStudio localizations + ASC uploads | Metadata localization without visual localization leaves conversion on the table |
| P2 | Watch screenshots: no overlay text; optimize frame sequence only | Apple Watch screenshot set | If text overlay is impractical, story must come from screenshot order and shot choice |
| P2 | Apply Netflix PPP country pricing around current 2.99 | Helm country pricing preview + analytics sheet | Improves affordability by market before any flat 1.99 promo test |
| P3 | Expand to Wave-1 locales | ASC localization + screenshot localizations | Adds discoverability in large gaming/iOS markets |

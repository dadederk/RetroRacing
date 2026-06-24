# ASO Decisions & Priorities

Part of [ASO & growth plans](README.md). Index: [retrorapid_aso_growth_plan.md](../retrorapid_aso_growth_plan.md).

Last updated: 2026-03-14 (campaign); brand status refreshed 2026-06-24
**See also:** [Canonical metadata](../../AppStoreAssets/docs/05-metadata-copy.md) · [90-day plan](../../AppStoreAssets/docs/11-execution-90-day.md)


---

## 1) Confirmed Decisions

- Public name is **RetroRapid!** everywhere user-facing.
- **tvOS and visionOS are not currently supported** in the shipping App Store offer.
- Accessibility is a core differentiator, but for broad discovery we should lead with the **game fantasy first**, then accessibility.
- Game Center is useful for retention/fun, but not a top-of-funnel differentiator.

## 2) User-Facing Brand Status

As of 2026-06-24, user-facing app copy in `Localizable.xcstrings`, display names, screenshot captions, and About/paywall strings use **RetroRapid!**. The remaining `RetroRacing` references in the repo are internal (module names, bundle IDs, achievement prefixes, repo paths).

Non-user-facing references to `RetroRacing` (bundle identifiers, module names, repo paths) can remain unless/until a technical rebrand is planned.

## 3) Highest-Impact Actions With Rationale

Order: low effort + high impact -> higher effort.

| Priority | Action | Exactly where | Rationale |
|---|---|---|---|
| P1 | Fix remaining user-facing name mismatch | `Localizable.xcstrings` key `tutorial_voiceover_intro` (EN/ES/CA) | Brand consistency improves trust and perceived quality |
| P1 | Align screenshot messaging to gameplay-first funnel | ScreenshotStudio iPhone/iPad/Mac caption set | Most users decide from first screenshot; lead with fun/clarity first |
| P1 | Keep accessibility as slide 2 or 3, not slide 1 | ScreenshotStudio narrative order | Accessibility remains a differentiator without narrowing top-of-funnel appeal |
| P1 | Add concrete metadata refresh (subtitle, keywords, description opening) | App Store Connect listing fields | Better search intent coverage + clearer value prop |
| P1 | Complete accessibility listing fields for 1.3+ | App Store Connect -> Accessibility section | Converts your real product strength into visible store trust signals |
| P2 | Localize screenshot copy for ES/CA (not only metadata) | ScreenshotStudio localizations + ASC uploads | Metadata localization without visual localization leaves conversion on the table |
| P2 | Watch screenshots: no overlay text; optimize frame sequence only | Apple Watch screenshot set | If text overlay is impractical, story must come from screenshot order and shot choice |
| P2 | Pricing test windows around current 2.99 | ASC pricing schedule + analytics sheet | Gives evidence-based decision between 2.99 and 1.99 |
| P3 | Expand to Wave-1 locales | ASC localization + screenshot localizations | Adds discoverability in large gaming/iOS markets |

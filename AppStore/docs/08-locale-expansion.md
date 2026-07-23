# Country & Language Expansion

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-06-25

**Status:** current storefront coverage is `LIVE`; v1.5 regional metadata is `DRAFT_APPLIED`; `de-DE`, `nl-NL`, `it`, and `fr-FR` app strings and metadata are `LIVE` in repo/ASC drafts; `fr-CA` remains optional future work.

**See also:** [Cross-localization](04-metadata-strategy.md#cross-localization-strategy) · [Localization requirements](../../Requirements/localization.md)


---

## Country And Language Expansion Strategy

Current supported app languages are English (`en`, `en-GB`, `en-AU`, `en-CA`), German (`de`), Dutch (`nl`), Italian (`it`), French (`fr`), Spanish, and Catalan. App Store metadata should stay aligned with in-app localization, especially because RetroRapid sells accessibility and settings clarity. For each new market, prepare App Store metadata, screenshots, app strings, IAP display names, Game Center metadata, and support/privacy pages as one localization package.

### Priority Tiers

| Priority | Locale / market | Why it is interesting | Preparation notes |
|---|---|---|---|
| P0 | `en-US`, `en-GB`, `en-AU`, `en-CA`, `es-ES`, `ca` | App strings and existing storefront coverage are `LIVE`; v1.5 regional metadata fields are `DRAFT_APPLIED`. UK ratings remain strong. | Re-export remaining localized screenshots. Compare UK/AU/CA conversion separately in ASC. |
| P0 | `es-MX` | v1.5 metadata is `DRAFT_APPLIED`; full app localization and rendered screenshots are `PLANNED`. Mexico/LatAm cross-indexes with en-US. | Validate ranks for `carro`, `rebasar`, `internet`, and `control` before submission. |
| P1 | `de-DE` | Large European App Store market; racing and arcade terms are direct enough to localize well. | **LIVE** in repo + ASC 1.5 drafts (2026-07-23). |
| P1 | `ja` | Strong game market and good fit for compact arcade gameplay. | Needs professional localization and screenshot typography QA. Avoid literal machine translation of racing/retro terms. |
| P1 | `pt-BR` | Large audience and useful next step after Spanish. | Prepare Brazilian Portuguese specifically, not generic Portuguese. Validate monetization/pricing expectations. |
| P2 | `fr-FR` | Large EU market with reasonable localization lift. | **LIVE** in repo + ASC 1.5 drafts (2026-07-23). Optional `fr-CA` deferred. |
| P2 | `ko` | Strong mobile gaming market and high engagement potential. | Higher localization QA bar. Prioritize only after Japanese/German data or if App Store Connect shows Korean traction. |
| P2 | `zh-Hans`, `zh-Hant` | High upside, especially for simple arcade games. | Needs careful localization, legal/availability review, screenshot QA, and monetization expectations. |
| P3 | `it`, `nl`, `pl`, `tr` | Additional scale after the first wave. | `it` and `nl` are **LIVE** in repo + ASC 1.5 drafts (2026-07-23). |

### Data To Request Before Each Locale

For each candidate market, collect:

- App Store Connect: product page views, conversion rate, units, proceeds, IAP conversion, ratings, and retention by territory.
- Keyword rank baseline for RetroRapid.
- Suggested keywords for the local storefront.
- Competitor keyword exports.
- Storefront-level revenue and conversion comparison against UK/US baseline.
- Local review language and support emails, if any.

### Competitors And Adjacent Apps To Track

Track both racing games and Apple Watch / accessible-game adjacencies:

- Retro Highway
- Traffic Racer
- WhiskerDash: Retro Watch Game
- Tunnel Ball: Watch Retro Run 3D
- Watch Car Race: Carify Highway
- Pong 360: Retro Watch Arcade
- Lane Defender: Haptic Arcade
- Echo Chain: Multiplayer Fun
- Accessible or VoiceOver-friendly games surfaced by AppleVis/community feedback

Useful English keyword checks:

- `retro racing`
- `arcade racing`
- `traffic dodger`
- `endless racing`
- `3 lane racing`
- `watch racing game`
- `apple watch game`
- `high score racing`
- `reflex game`
- `accessible game`
- `voiceover game`
- `haptic game`
- `controller racing`

Useful Spanish checks:

- `carreras arcade`
- `carreras retro`
- `juego de carreras`
- `trafico infinito`
- `esquivar coches`
- `juego apple watch`
- `juego accesible`
- `voiceover juego`
- `reflejos`
- `puntuacion`

Useful Catalan checks will likely have lower volume. Keep Catalan primarily as a quality and regional trust localization unless App Store Connect shows meaningful search demand.

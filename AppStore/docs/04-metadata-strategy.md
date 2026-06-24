# Metadata Strategy & ASO Review

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-06-24
**See also:** [Metadata copy (staged)](05-metadata-copy.md) · [Screenshots](06-screenshots.md) · [Locale expansion](08-locale-expansion.md)


---

## ASO Review

### Current Strengths

- The brand is distinctive and memorable.
- The public page already communicates privacy, accessibility, Game Center, Apple Watch, Mac, and one-time IAP support.
- User reviews reinforce the right messages: addictive high-score chasing, simple controls, Apple Watch support, nostalgia, and accessibility.
- The game has a clean core search story: retro arcade racing, 3 lanes, traffic dodging, high-score/reflex play, quick sessions, and accessible gameplay.
- Screenshot source files include English (`en-US`, `en-GB`, `en-AU`, `en-CA`), Spanish, and Catalan for iPhone/iPad, aligned to the recommended seven-slide storyboard.

### Main Opportunities

- Use the app-name field for the brand plus a natural category hint, not brand alone or a compressed verb list.
- Use the subtitle for the core traffic-dodging mechanic without repeating visible terms.
- Spend the hidden keyword field on supporting intents, niches, and long-tail phrases not already covered in visible metadata.
- Replace the platform-only promotional text with a benefit-led conversion message.
- Fix the public What's New brand mismatch from `RetroRacing` to `RetroRapid!`.
- Make the first three screenshots tell the conversion story in this order: game loop, controls, accessibility.
- Bring Mac screenshots to parity with iPhone/iPad and localize them into Spanish and Catalan.
- Remove Apple Vision marketing claims while the shipping visionOS experience remains a placeholder.
- Remove or park Apple TV screenshot output while tvOS is not publicly supported.
- Capture Appfigures/Krankie baselines, submit one coherent metadata pack, then measure before further keyword churn.

## Recommended Metadata Candidate

This is the preferred natural-language direction for the next version. It follows Apple's guidance more closely: keep the app name simple, memorable, distinctive, and descriptive; use the subtitle to explain the core experience in greater detail.

The Xarra `Read, Listen, Focus` pattern should not be treated as a universal template. It works for Xarra's task-oriented product, but three compressed verbs make RetroRapid feel more like a tagline than an app name.

| Field | Role | RetroRapid treatment |
|---|---|---|
| **App name** | Brand + concise category hint | Arcade racer / carreras arcade / carreres arcade |
| **Subtitle** | Core mechanic and action | Dodge traffic across three lanes |
| **Keywords** | Supporting intents not visible above | High score, overtakes, reflexes, offline, accessibility, controllers, handheld/LCD nostalgia |
| **Promotional text** | Conversion promise | Game loop, Game Center, Apple Watch support, and accessible controls |
| **Description** | Proof and use cases | Gameplay, platforms, controls, accessibility, privacy, and monetization |

Avoid repeating the same indexed term across name, subtitle, and keywords. These keyword fields remain provisional until the current fields and baseline rankings have been captured.
### Cross-Localization Strategy

Source: [AppTweak — cross-localization on the App Store](https://www.apptweak.com/en/aso-blog/how-to-benefit-from-cross-localization-on-the-app-store).

RetroRapid currently ships metadata for **en-US**, **en-GB**, **en-AU**, **en-CA**, **es-ES**, **ca**, and **es-MX**. Apple indexes **multiple locales per territory**, so keyword fields should be planned as a set, not isolated lists.

| Territory | Primary locale | Also indexes (relevant to us) | Subtitle + keyword strategy |
|---|---|---|---|
| **United States** | English (US) | **Spanish (Mexico)** among others | Core mechanic in **en-US** subtitle (`dodge`, `traffic`, `lanes`). Mexico Spanish in **es-MX** with its own subtitle. |
| **United Kingdom** | English (UK) | **English (Australia)** | Split **en-GB** + **en-AU** subtitles and keyword fields — no duplicate tokens across the pair. |
| **Canada** | English (Canada) | **English (US)** among others | Split **en-CA** + **en-US** subtitles and keyword fields — no duplicate tokens across the pair. |
| **Australia** | English (Australia) | **English (UK)** | Same **en-GB** + **en-AU** pair as UK (roles reversed). |
| **Spain** | Spanish (Spain) | **Catalan**, English (UK) | Split Spanish and Catalan across **es-ES** and **ca**. **en-GB** adds English search coverage without duplicating Spanish tokens. |
| **Mexico** | Spanish (Mexico) | English (UK) | **es-MX** subtitle/name stay Mexican Spanish; keywords carry local terms plus `internet`. |

Rules applied from the article:

- Use **commas between keywords**, not spaces; prefer **singular tokens** over glued phrases.
- Keywords combine **within** a locale (`high` + `score` → `high score`), but **not across** locales (`bus` in en-US + `metro` in es-MX does not create `metro bus`).
- Avoid repeating the same keyword across locales that index together in one territory, unless deliberately targeting a cross-token phrase inside the same locale.
- Split **subtitle** tokens the same way as keywords for cross-indexing pairs (**en-GB**/**en-AU**, **en-CA**/**en-US**).
- Keep **title and subtitle localized** for humans; use the keyword field for extra discovery terms and cross-locale coverage.

Why not `sin conexion` / `sin internet` in the keyword field:

- Apple expects comma-separated tokens, not multi-word phrases.
- `sin` is a weak connector and wastes bytes.
- Glued forms like `sinconexion` / `sininternet` are poor search matches.
- Better split: **`conexion`** on Spain Spanish, **`internet`** on Mexico Spanish, **`offline`** on English (US), plus explicit *sin conexión* / *sin internet* / *sense connexió* phrasing in visible description copy.

### Decision Notes

Field allocation:

- **Name** protects brand quality while adding a concise category hint.
- **Subtitle** explains the mechanic in natural language rather than maximizing token density at the expense of readability.
- **Keywords** cover vehicle, scoring, overtakes, reflexes, connectivity hints, accessibility, controllers, leaderboards, watch, and handheld/LCD nostalgia — split across locales using cross-localization rules above.
- Use **`offline`** on English (US), **`conexion`** on Spanish (Spain), and **`internet`** on Spanish (Mexico) rather than glued `sinconexion` / `sininternet`. Spell out *sin conexión* / *sin internet* in description bullets where gameplay supports it.
- Do not add `Game Center` to hidden keywords. It belongs in promotional text, description, and screenshots.
- Helm/App Store Connect may warn when a keyword token already appears in the name or subtitle. Current fixes: drop `retro` from **en-US** (`RetroRapid` already carries it; use `endless` instead), drop `arcade`/`racer`/`traffic`/`lanes` from English variants, drop `retro` from **ca**, drop `carro` from **es-MX** (subtitle already uses `carros`), add `logros` on **es-ES** / **es-MX** and `puntuacio`/`connexio`/`mac` on **ca**.
- Treat `retro`, `voiceover`, `haptics`, `handheld`, `lcd`, and `leaderboard` as hypotheses. Keep or replace them based on real popularity, competition, and current rank data.

Useful keyword checks before submission:

| Store | Phrases to check | Why |
|---|---|---|
| US / GB | `retro racing`, `arcade racing`, `traffic racer`, `endless racing`, `watch racing game`, `apple watch game`, `high score game`, `reflex game`, `voiceover game`, `haptic game`, `controller racing` | Core English discovery and differentiators |
| ES | `carreras arcade`, `carreras retro`, `trafico infinito`, `esquivar coches`, `juego apple watch`, `reflejos`, `record puntuacion`, `juego accesible` | Spain gameplay and watch/accessibility intent |
| CA | `carreres arcade`, `transit infinit`, `esquivar cotxes`, `joc apple watch`, `reflexos`, `accessibilitat` | Lower volume, but validates regional trust copy |
| MX | `carreras arcade`, `trafico infinito`, `juego de carros`, `rebasar`, `juego apple watch`, `record`, `sin internet` | Mexico often diverges from Spain; compare before reusing es-ES keywords |

Competitors worth checking by storefront:

- Retro Highway
- Traffic Racer
- WhiskerDash: Retro Watch Game
- Tunnel Ball: Watch Retro Run 3D
- Watch Car Race: Carify Highway
- Lane Defender: Haptic Arcade

After submission, re-check ranks at 7, 14, and 28 days. Update this section with actual movement rather than making more metadata edits during the observation window.
## Why This Metadata Direction

- The **name** keeps RetroRapid distinctive while adding a concise category hint.
- The **subtitle** explains the central action and three-lane mechanic in a natural phrase.
- **Hidden keywords** cover vehicle, scoring, reflex, offline play, accessibility, controllers, leaderboards, and handheld/LCD nostalgia that visible metadata does not repeat.
- **Promotional text** sells conversion, not platform inventory: traffic dodging, high scores, quick runs, Game Center, Apple Watch, accessibility.
- The **description** opens with gameplay first, then proves replayability, controls, platform support, accessibility, privacy, and monetization clarity.
- Apple Vision is intentionally omitted while the shipping visionOS experience is a "Coming Soon" placeholder.

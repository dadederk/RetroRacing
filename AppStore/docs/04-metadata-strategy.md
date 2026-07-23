# Metadata Strategy & ASO Review

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-07-19

**Status:** `READY` strategy; keyword demand validation remains a submission `BLOCKED` item.

**See also:** [Metadata copy (staged)](05-metadata-copy.md) · [Screenshots](06-screenshots.md) · [Locale expansion](08-locale-expansion.md)


---

## ASO Review

### Current Strengths

- The brand is distinctive and memorable.
- The public page already communicates privacy, accessibility, Game Center, Apple Watch, Mac, and one-time IAP support.
- User reviews reinforce the right messages: addictive high-score chasing, simple controls, Apple Watch support, nostalgia, and accessibility.
- The game has a clean core search story: retro arcade racing, 3 lanes, traffic dodging, high-score/reflex play, quick sessions, and accessible gameplay.
- Screenshot source files include English (`en-US`, `en-GB`, `en-AU`, `en-CA`), German (`de-DE`), Dutch (`nl-NL`), Italian (`it`), French (`fr-FR`), Spanish, and Catalan for iPhone/iPad, aligned to the recommended seven-slide storyboard.

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

### External Audit (aso-audit skill, 2026-07-19)

Grounded in `metadata/retrorapid-v1.5.json`, this strategy doc, `06-screenshots.md`, `09-product-page-optimization.md`, `Requirements/rating_system.md`, and live App Store Connect data pulled read-only via `helm-asc` (app `6758641625`, iOS + macOS 1.5 drafts).

```
Overall ASO Score: 69/100  (weights normalized to 100%)

Title:              8/10  ████████░░
Subtitle:           9/10  █████████░
Keyword Field:      9/10  █████████░
Description:        8/10  ████████░░
Screenshots:        3/10  ███░░░░░░░
Preview Video:      1/10  █░░░░░░░░░
Ratings & Reviews:  9/10  █████████░
Icon:               7/10  ███████░░░
Keyword Rankings:   3/10  ███░░░░░░░
Conversion Signals: 7/10  ███████░░░
```

**Key strengths:** all 14 written reviews on file are 5★ (public snapshot 4.8★), spread across the US, UK, Australia, Spain, Brazil, and Kazakhstan; `Requirements/rating_system.md` ties the native StoreKit prompt to a real satisfaction signal (3rd personal-best improvement) with sane frequency caps; the keyword cross-localization strategy above correctly avoids Apple's cross-locale indexing traps; two past In-App Events (Global Accessibility Awareness Day, Miami Grand Prix Weekend) prove the lever works and is just dormant.

**Quick wins:**

1. The redundant second "Retro" in `RetroRapid: Retro Arcade Racer` is a low-confidence, low-impact issue — see the 2026-07-19 decision note below; no change made.
2. Add social proof (review quote + Create with Swift feature) to the description — **done 2026-07-19**, see decision notes below.
3. Resolve the What's New drift before shipping — **done 2026-07-19**, see decision notes below.

**High-impact changes:**

1. Screenshot completeness is the single biggest score drag. Verified via Helm on the 1.5 drafts at audit time: iPhone en-US 7/7, iPad 5/7, Watch 5/7; `ca`/`es-ES` iPhone only 7/7 with nothing else; `en-GB`/`en-AU`/`en-CA`/`es-MX` had zero screenshots; macOS had only 5/7 for en-US and nothing else. See `06-screenshots.md` and `03-submission-quality-gate.md` for the current per-locale/platform breakdown.
2. No App Preview video exists on the iOS draft at all (`0` items via Helm) — a straightforward, high-conversion addition not currently queued anywhere in the docs.
3. Ship the Game Center Custom Product Page — copy and keyword-assignment plan are already `READY` in `09-product-page-optimization.md`; the remaining work is just Screenshot Studio export + ASC setup.

**Strategic recommendations:**

1. Capture the Appfigures/Krankie keyword baseline flagged as blocked in "Main Opportunities" above — every keyword decision here is currently a hypothesis with zero rank validation.
2. Resolve the visionOS "Coming Soon" placeholder — a shipped placeholder without gameplay is a conversion and trust risk on a publicly listed platform.
3. Plan the next In-App Event; the template already exists and the lever is proven.
4. Localize social-proof messaging (done for `es-ES`/`es-MX`; `ca` intentionally carries only the translated press quote, not a fabricated player review — see decision notes below).

**What couldn't be measured:** no live keyword-ranking API/MCP is connected, so Keyword Rankings is scored on coverage/structure only, not actual rank position. Icon distinctiveness is scored on structural signals only (modern Icon Composer `.icon` format in place); no visual quality pass was done.

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

The v1.5 draft catalog includes **en-US**, **en-GB**, **en-AU**, **en-CA**, **de-DE**, **nl-NL**, **it**, **fr-FR**, **es-ES**, **ca**, and **es-MX**. Apple indexes **multiple locales per territory**, so keyword fields should be planned as a set, not isolated lists.

| Territory | Primary locale | Also indexes (relevant to us) | Subtitle + keyword strategy |
|---|---|---|---|
| **United States** | English (US) | **Spanish (Mexico)** among others | Core mechanic in **en-US** subtitle (`dodge`, `traffic`, `lanes`). Mexico Spanish in **es-MX** with its own subtitle. |
| **United Kingdom** | English (UK) | **English (Australia)** | Split **en-GB** + **en-AU** subtitles and keyword fields — no duplicate tokens across the pair. |
| **Canada** | English (Canada) | **English (US)** among others | Split **en-CA** + **en-US** subtitles and keyword fields — no duplicate tokens across the pair. |
| **Australia** | English (Australia) | **English (UK)** | Same **en-GB** + **en-AU** pair as UK (roles reversed). |
| **Germany** | German (Germany) | English (US) | Split **de-DE** + **en-US** keywords — no duplicate tokens. |
| **France** | French (France) | English (UK) | Split **fr-FR** + **en-GB** subtitles/keywords. |
| **Italy** | Italian | English (UK) | Split **it** + **en-GB** keywords. |
| **Netherlands** | Dutch (Netherlands) | English (US) | Split **nl-NL** + **en-US** keywords. |
| **Belgium** | Dutch / French | each other | Avoid duplicate FR/NL tokens where both index. |
| **Switzerland** | German / French / Italian | multiple | De-dupe **de-DE**, **fr-FR**, and **it** globally. |
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

### Decision notes

- 2026-07-19: Added social proof to the description on all seven locales — an App Store review quote (English: Datafile, "I am really a fan of this nice accessible game..."; Spanish: Jonathan Chacón, "Un juego simplemente accesible y simplemente entretenido...", reused for `es-MX` since it's genuinely Spanish-language and no Mexico-specific review exists yet) plus the Create with Swift "Indie App of the Week" pull-quote (Weekly Newsletter #96: *"But beyond the nostalgia and tight gameplay, what truly stands out is its accessibility."*). `ca` gets the Create with Swift quote only (translated) — no Catalan-language review exists yet, so no player quote was fabricated for that locale. Applied to both iOS and macOS 1.5 drafts via Helm for all seven locales.
- 2026-07-19: Standardized What's New on *"This update sharpens RetroRapid! with bug fixes and racing polish..."* everywhere — canonical `retrorapid-v1.5.json`, both 1.5 platform drafts (it was already live on the four English App Store locales but still showed old copy on `es-ES`/`ca`/`es-MX` and on all seven macOS locales), and the TestFlight `beta-notes/en-US/whats-new.txt` used for build 28. This resolves the What's New drift flagged in `13-open-questions.md`. Spanish/Catalan translations keep the existing "Game Center sigue siendo la protagonista" phrasing already established in prior release notes.
- 2026-07-19: Found that `swift run --package-path Scripts apply-retrorapid-metadata` mangles accented characters (`á`, `ñ`, etc. arrive at Apple's API as decomposed combining-mark sequences, rejected with `INVALID_CHARACTERS`) when it shells out to Helm for `es-ES`/`ca`/`es-MX`. English-only locales are unaffected since they have no accents. Worked around by calling `helm-asc localization <id> update` directly with argv-based subprocess calls (no intermediate shell string) for the three Spanish/Catalan locales on both platforms. The Swift tool's shell-invocation path needs a fix (likely in `RetroRacingAutomationCore`'s Helm command construction) before it can be trusted for non-English locales again.
- 2026-07-19: Considered dropping the redundant second "Retro" in the `en-US`/`en-GB`/`en-AU`/`en-CA` name (`RetroRapid: Retro Arcade Racer`) to free 6 characters. Apple's search algorithm indexes the app name as whole tokens, not as arbitrary substrings, so it is not confirmed that "Retro" is credited from inside the `RetroRapid` brand token — the repeated word is a low-confidence, low-impact issue either way. No change made yet; every strong alternative token (`Game`, `3-Lane`, `Racing`, `Highway`, etc.) already exists somewhere in the keyword/subtitle set, so the marginal ASO gain of a swap is smaller than the screenshot/preview-video gaps below. Revisit only alongside a deliberate PPO/App Store name test, not as a quick edit.

- The **name** keeps RetroRapid distinctive while adding a concise category hint.
- The **subtitle** explains the central action and three-lane mechanic in a natural phrase.
- **Hidden keywords** cover vehicle, scoring, reflex, offline play, accessibility, controllers, leaderboards, and handheld/LCD nostalgia that visible metadata does not repeat.
- **Promotional text** sells conversion, not platform inventory: traffic dodging, high scores, quick runs, Game Center, Apple Watch, accessibility.
- The **description** opens with gameplay first, then proves replayability, controls, platform support, accessibility, privacy, and monetization clarity.
- Apple Vision is intentionally omitted while the shipping visionOS experience is a "Coming Soon" placeholder.

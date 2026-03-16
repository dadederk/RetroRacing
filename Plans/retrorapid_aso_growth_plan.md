# RetroRapid! ASO Execution Plan

Updated: 2026-03-14  
Owner: Dani  
Goal: Increase App Store conversion and monetization while keeping RetroRapid! positioning clear and consistent.

## 1) Confirmed Decisions

- Public name is **RetroRapid!** everywhere user-facing.
- **tvOS and visionOS are not currently supported** in the shipping App Store offer.
- Accessibility is a core differentiator, but for broad discovery we should lead with the **game fantasy first**, then accessibility.
- Game Center is useful for retention/fun, but not a top-of-funnel differentiator.

## 2) Where `RetroRacing` Still Appears User-Facing

This is the concrete user-facing occurrence still found in the app copy:

1. `tutorial_voiceover_intro` string values still say `RetroRacing` (EN/ES/CA).
   - File: `RetroRacing/RetroRacingShared/Localizable.xcstrings`
   - Current lines: ~4404, ~4410, ~4416
   - Action: Replace product name in those three values with `RetroRapid!`.
   - Rationale: VoiceOver onboarding is a key accessibility touchpoint; naming inconsistency here undermines trust and polish.

Non-user-facing references to `RetroRacing` (bundle identifiers, module names, repo paths) can remain unless/ until a technical rebrand is planned.

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

## 4) Screenshot Messaging Plan (Revised)

## 4.1 Positioning Rule

- Slide 1 should sell the game loop.
- Accessibility should appear early (slide 2/3), but not replace the gameplay hook.
- Game Center should appear as replayability support, not as headline proposition.

## 4.2 iPhone/iPad/Mac Caption Sequence (EN master)

1. Title: `Dodge Endless Traffic.`  
   Body: `Three lanes, rising speed, one more run.`
2. Title: `Simple Controls. Real Challenge.`  
   Body: `Move left or right, react fast, beat your best score.`
3. Title: `Built For Accessibility.`  
   Body: `VoiceOver, audio cues, haptics, and adaptable gameplay settings.`
4. Title: `Play Across Apple Devices.`  
   Body: `Designed for iPhone, iPad, Mac, and Apple Watch.`
5. Title: `Chase High Scores Your Way.`  
   Body: `Customize sound, feedback, and visuals. Leaderboards add replayability.`

## 4.3 Apple Watch Screenshot Approach

- Assume **no marketing text overlays** for watch output.
- Use sequence-only storytelling:
  1. Core gameplay lane view
  2. Input interaction moment (Digital Crown/swipe)
  3. Collision/high-tension moment
  4. Pause/help/accessibility state
  5. Score/result state
- Add support explanation in ASC screenshot order notes/internal checklist, not in-image copy.

## 4.4 Platform Scope Cleanup In ScreenshotStudio

- Remove Apple TV and Apple Vision from active planning/output for now to avoid accidental scope drift.
- Keep active sets: iPhone, iPad, Mac, Apple Watch.

## 5) Metadata Proposals (Concrete)

Validated with `validate_metadata.py` on 2026-03-14.

## 5.1 Primary Metadata Pack (Recommended)

## EN (US/UK)

- App Name (25/30): `RetroRapid! Arcade Racing`
- Subtitle (29/30): `3-Lane Endless Traffic Dodger`
- Promotional Text (132/170): `Dodge traffic, beat your high score, and enjoy retro arcade racing with accessibility-first options and quick one-more-run sessions.`
- Keywords (94/100): `traffic,arcade,racing,endless,highscore,overtake,reflex,casual,offline,voiceover,haptics,watch`
- Description (637/4000):
  `RetroRapid! is a fast retro arcade racer built for quick sessions and high-score chasing.`
  `Move across 3 lanes, dodge traffic, and survive as speed keeps rising. Controls are simple to learn and hard to master, so every run becomes a reflex challenge.`
  `Why players keep coming back:`
  `• One-more-run arcade gameplay`
  `• Accessibility-first options: VoiceOver support, audio cues, haptics, Dynamic Type, and Reduce Motion behavior`
  `• Designed for iPhone, iPad, Mac, and Apple Watch`
  `• Game Center leaderboards for extra replayability`
  `• Optional one-time Unlimited Plays purchase (no subscription)`
  `Crash, restart, and beat your best.`
- What’s New (275/4000):
  `Version 1.3 improves accessibility, onboarding, and localization.`
  `- Added App Store listing translations in Spanish and Catalan`
  `- Improved accessibility options and guidance`
  `- Better in-game help/tutorial clarity`
  `- Stability and gameplay polish across supported devices`

## ES (Spain)

- App Name (27/30): `RetroRapid! Carreras Arcade`
- Subtitle (28/30): `3 carriles, tráfico infinito`
- Promotional Text (134/170): `Esquiva tráfico, supera tu puntuación y disfruta de carreras arcade retro con opciones de accesibilidad y partidas rápidas de "una más".`
- Keywords (95/100): `trafico,carreras,arcade,infinito,puntuacion,reflejos,casual,sinconexion,accesibilidad,voiceover`
- Description (697/4000):
  `RetroRapid! es un arcade de carreras retro pensado para partidas rápidas y para perseguir tu mejor puntuación.`
  `Muévete entre 3 carriles, esquiva tráfico y aguanta cuando la velocidad sube. Los controles son fáciles de aprender y difíciles de dominar, así que cada partida pone a prueba tus reflejos.`
  `Por qué engancha:`
  `• Jugabilidad arcade de "una más"`
  `• Opciones de accesibilidad: compatibilidad con VoiceOver, pistas de audio, hápticos, Dynamic Type y Reducción de movimiento`
  `• Diseñado para iPhone, iPad, Mac y Apple Watch`
  `• Leaderboards de Game Center para aumentar la rejugabilidad`
  `• Compra única opcional de Partidas ilimitadas (sin suscripción)`
  `Choca, reinicia y supera tu marca.`
- What’s New (297/4000):
  `La versión 1.3 mejora accesibilidad, onboarding y localización.`
  `- Añadidas traducciones de la ficha de App Store en español y catalán`
  `- Mejoradas las opciones de accesibilidad y su guía`
  `- Ayuda/tutorial dentro del juego más claro`
  `- Mejoras de estabilidad y pulido en dispositivos compatibles`

## CA (Valencian style)

- App Name (27/30): `RetroRapid! Carreres Arcade`
- Subtitle (26/30): `3 carrils, trànsit infinit`
- Promotional Text (135/170): `Esquiva trànsit, supera la teua puntuació i gaudix de carreres arcade retro amb opcions d'accessibilitat i partides ràpides de "una més".`
- Keywords (93/100): `transit,carreres,arcade,infinit,puntuacio,reflexos,casual,sensexarxa,accessibilitat,voiceover`
- Description (711/4000):
  `RetroRapid! és un arcade de carreres retro pensat per a partides ràpides i per a perseguir la teua millor puntuació.`
  `Mou-te entre 3 carrils, esquiva trànsit i resistix quan la velocitat puja. Els controls són fàcils d'aprendre i difícils de dominar, aixina que cada partida posa a prova els teus reflexos.`
  `Per què enganxa:`
  `• Jugabilitat arcade de "una més"`
  `• Opcions d'accessibilitat: compatibilitat amb VoiceOver, pistes d'àudio, hàptics, Dynamic Type i Reducció de moviment`
  `• Dissenyat per a iPhone, iPad, Mac i Apple Watch`
  `• Classificacions de Game Center per a augmentar la rejugabilitat`
  `• Compra única opcional de Partides il·limitades (sense subscripció)`
  `Xoca, reinicia i supera la teua marca.`
- What’s New (294/4000):
  `La versió 1.3 millora accessibilitat, onboarding i localització.`
  `- Afegides traduccions de la fitxa d'App Store en espanyol i català`
  `- Millorades les opcions d'accessibilitat i la seua guia`
  `- Ajuda/tutorial dins del joc més clar`
  `- Millores d'estabilitat i polit en dispositius compatibles`

## 5.2 Secondary Variant (For Later Testing)

- Subtitle alternative (EN): `Retro Arcade Car Reflex Game`
- Promo alternative (EN): `Classic-inspired 3-lane racing with quick sessions, strong accessibility support, and endless high-score chasing.`
- Keyword alternative (EN): `retro,car,lane,dodge,score,arcadegame,reaction,handheld,accessibility,voiceover,watchgame`

Use this variant only after the primary pack has enough data (at least one full 3-4 week cycle).

## 5.3 Why This Metadata Direction

- App name keeps brand first while adding explicit category intent (`Arcade Racing`).
- Subtitle prioritizes mechanic clarity and search matching (`3-lane`, `traffic`, `endless`).
- Promo text sells the emotional loop ("one-more-run") and includes accessibility without becoming niche.
- Keywords avoid duplication and cover both broad + long-tail intent.
- Description order matches conversion flow: gameplay hook -> proof points -> accessibility -> platform coverage -> monetization clarity.
- Game Center is included as replayability support, not as the main promise.

## 5.4 ES/CA Adaptation Rule

- Localize meaning, not literal word-by-word copies.
- Preserve keyword intent by locale (arcade/racing/high-score terms users actually search in each language).
- Keep Valencian style consistency for `ca`.

## 6) Pricing Strategy (Specific)

## 6.1 Baseline

- Keep current one-time `Unlimited Plays` at **2.99** while creative/metadata updates settle.

## 6.2 Test Design

- Window A (baseline): 2.99 for 28 days
- Window B (promo): 1.99 for 7-10 days (aligned with update push)
- Window C (rebound): 2.99 for 21-28 days

## 6.3 Metrics

- Product page conversion rate
- IAP conversion rate per first-time installer
- Net proceeds per 1,000 product page views
- D1 and D7 retention split by purchaser/non-purchaser

## 6.4 Decision Threshold

- Keep 2.99 if it wins net proceeds per 1,000 views.
- Consider 1.99 if:
  - IAP conversion lifts materially (target +30% or better), and
  - net proceeds per 1,000 views do not decline.

## 7) Language Expansion Priority (After EN/ES/CA)

## Wave 1

1. Japanese (`ja`)
2. Brazilian Portuguese (`pt-BR`)
3. German (`de-DE`)
4. French (`fr-FR`)
5. Korean (`ko`)

Rationale:
- Large game markets and/or strong iOS monetization.
- Strong fit for fast, low-text, reflex gameplay.

## Wave 2

1. Chinese Simplified (`zh-Hans`)
2. Chinese Traditional (`zh-Hant`)
3. Italian (`it`)
4. Turkish (`tr`)
5. Polish (`pl`)

Rationale:
- Additional scale opportunities after Wave 1 validation.
- Chinese variants are high-upside but need stricter QA and localization quality control.

## 8) 60-Day Operational Checklist

## Days 1-10

- [ ] Update `tutorial_voiceover_intro` brand text to `RetroRapid!` in EN/ES/CA.
- [ ] Replace iPhone/iPad/Mac screenshot caption sequence with revised gameplay-first order.
- [ ] Remove tvOS/visionOS outputs from current ASO screenshot workflow.
- [ ] Publish/accessibility fields completion in ASC.

## Days 11-30

- [ ] Export and upload ES/CA screenshot localizations.
- [ ] Build and upload Apple Watch screenshot set using sequence storytelling.
- [ ] Apply EN metadata proposal and submit if aligned with release window.
- [ ] Draft GAAD featuring nomination entry and internal approval pack.

## Days 31-60

- [ ] Run 2.99 -> 1.99 -> 2.99 price window test.
- [ ] Measure KPI deltas and decide baseline price.
- [ ] Prepare Wave-1 locale rollout pack.
- [ ] Submit GAAD nomination and finalize supplemental materials links.

## 9) Featuring Nomination Add-On (GAAD)

Yes, this should be part of the ASO growth plan because App Store featuring can materially increase product page impressions and conversion volume for a short window.

## 9.1 Campaign Goal and KPI Targets

Primary goal:
- Earn App Store featuring consideration tied to GAAD while maintaining gameplay-first positioning.

Secondary goals:
- Improve product page conversion through clearer accessibility storytelling.
- Increase quality installs during the campaign window.

KPI set (measure for 14 days pre-window vs 14 days post-window):
- Product page impressions.
- Product page conversion rate.
- First-time installs.
- D1 and D7 retention.
- IAP conversion rate and proceeds per 1,000 product page views.

## 9.2 GAAD Campaign Window (2026)

- Occasion: Global Accessibility Awareness Day (GAAD)
- GAAD date: **Thursday, 2026-05-21**
- Recommended featuring window: **2026-05-18 to 2026-05-24**
- Latest safe nomination submit date (3-week lead): **2026-04-30**
- Recommended nomination submit target (4-5 week lead): **2026-04-17**

## 9.3 Nomination Strategy (Primary + Backup)

Primary nomination:
- Type: `App Enhancements`
- Why: safest path if campaign focuses on improved accessibility UX + refreshed store assets.

Secondary nomination (submit only if event is approved/published in time):
- Type: `New Content`
- Why: event-led framing can increase editorial relevance for a specific week.

Fallback path:
- If event approval timing slips, keep `App Enhancements` only and remove event dependency from copy.

## 9.4 Apple Field Rules to Follow

Confirmed constraints to enforce:
- `Nomination Name`: 60 characters max.
- `Nomination Description`: 1,000 characters max.
- `Helpful Details`: 500 characters max.
- `Related apps`: up to 10 apps from same account.
- `Supplemental Materials`: up to 5 URLs.
- `Related In-App Events` (CSV): up to 25 event IDs.
- Recommended lead time: minimum 3 weeks before publish start date.
- In-App Events attachment is only available on iPhone and iPad apps.
- Individual nominations can be saved as drafts.
- CSV-imported nominations are auto-submitted (not draftable).

## 9.5 Step-by-Step Execution Plan

### T-8 to T-7 weeks (Mar 23-Apr 3)

1. Lock campaign angle:
   - `Gameplay-first + inclusive play` (avoid accessibility-only framing on slide 1).
2. Select nomination path:
   - Primary `App Enhancements`.
   - Secondary `New Content` only if In-App Event can be approved in time.
3. Confirm ASC role access:
   - Account Holder, Admin, App Manager, or Marketing.

### T-6 weeks (Apr 6-Apr 10)

1. Finalize nomination copy v1 (Description + Helpful Details).
2. Build supplemental materials pack:
   - Trailer (30-45s).
   - Accessibility walkthrough clip.
   - Press kit folder.
   - Release notes page.
3. Validate all URLs are public and stable.

### T-5 weeks (Apr 13-Apr 17) — Recommended submit week

1. Enter nomination in App Store Connect as Draft.
2. Fill required fields and additional context fields.
3. Internal review pass:
   - Product
   - Accessibility
   - Marketing
4. Submit nomination by **2026-04-17** if assets are ready.

### T-4 to T-3 weeks (Apr 20-Apr 30) — Latest safe window

1. If not submitted yet, submit by **2026-04-30**.
2. If using CSV for multiple nominations:
   - Validate strict template format.
   - Remember CSV submits immediately.
3. Attach In-App Event only if approved/published and aligned.

### T-2 to T-0 weeks (May 1-May 17)

1. Freeze campaign copy and creative.
2. Re-check localization quality (EN/ES/CA).
3. Confirm storefront availability settings match planned regions.
4. Keep supplemental URLs unchanged until campaign closes.

### Campaign week (May 18-May 24)

1. Monitor impressions, conversion, installs, and retention daily.
2. Capture screenshots and analytics notes for post-mortem.
3. Log what messaging gets the strongest conversion lift.

### T+1 week (May 25-May 31)

1. Publish post-mortem with KPI deltas.
2. Keep winning creative in base ASO set.
3. Prepare next nomination concept (motorsport + seasonal beat).

## 9.6 GAAD Nomination Copy Pack (Ready to Paste)

### A) Primary (`App Enhancements`) — Recommended

- Nomination Name (40/60):
  `RetroRapid! GAAD Accessibility Week 2026`
- Nomination Type:
  `App Enhancements`
- Publish Date (Start):
  `2026-05-18`
- Publish Date (End):
  `2026-05-24`
- Platforms:
  `iOS (iPhone), iOS (iPad), macOS, watchOS`
- Nomination Description (627/1000):
  `RetroRapid! is a fast, 3-lane arcade racer built for quick sessions and high-score replayability. For Global Accessibility Awareness Day 2026, we are spotlighting accessibility-forward play across iPhone, iPad, Mac, and Apple Watch. This update highlights VoiceOver support, adaptive audio cues, haptics, Dynamic Type-friendly interface choices, and Reduce Motion behavior, while keeping gameplay simple and exciting for all players. The campaign also includes refreshed localized product-page assets (EN/ES/CA), accessibility-focused creative, and a time-bound challenge window to drive meaningful engagement during GAAD week.`
- Helpful Details (450/500):
  `RetroRapid! combines gameplay-first positioning with inclusive design. Accessibility is not a side menu item; it is part of onboarding, controls, feedback, and UI readability. We are aligning this nomination with GAAD week and supporting it with localized assets, clear accessibility communication, and a focused event window. We can provide a concise accessibility walkthrough video, gameplay trailer, and press kit links via Supplemental Materials.`

### B) Secondary (`New Content`) — Use when event is approved/published

- Nomination Name (37/60):
  `RetroRapid! GAAD Challenge Event 2026`
- Nomination Type:
  `New Content`
- Publish Date (Start):
  `2026-05-18`
- Publish Date (End):
  `2026-05-24`
- Platforms:
  `iOS (iPhone), iOS (iPad), macOS, watchOS`
- Nomination Description (493/1000):
  `RetroRapid! GAAD Challenge Week introduces a limited-time high-score event designed for quick play sessions and broad participation. Alongside the event, we are featuring accessibility-forward gameplay options such as VoiceOver support, adaptive audio cues, haptic feedback, Dynamic Type-friendly UI choices, and Reduce Motion behavior. The event and supporting store assets are localized (EN/ES/CA) and designed to highlight inclusive play without compromising the core arcade racing fantasy.`
- Helpful Details (337/500):
  `This nomination ties a time-bound challenge to inclusive product storytelling during GAAD week. We will support it with localized assets, a short event trailer, and a brief accessibility walkthrough clip. The campaign message is gameplay first, inclusion always: fast arcade racing that remains approachable for a wider range of players.`

## 9.7 Suggested Additional Field Values

- Relevant Countries or Regions (ISO3):
  `USA,GBR,ESP,CAN,AUS`
- Do you plan to launch in certain markets first?
  `No`
- Do you intend to submit a new In-App Event for this nomination?
  `No` (Primary) / `Yes` (Secondary)
- Localization shortcodes:
  `en-US,es-ES,ca`

## 9.8 Supplemental Materials Package (Up to 5 URLs)

Use this exact order:
1. Gameplay trailer (30-45s, gameplay-first).
2. Accessibility walkthrough (VoiceOver, haptics, Reduce Motion).
3. Press kit folder (logos, screenshots, one-sheet).
4. Release notes / update details page.
5. Optional campaign rationale page (GAAD context + timeline).

## 9.9 CSV Import Guidance (If Submitting in Bulk)

Template guardrails:
- Keep the CSV template columns unchanged.
- Start data entry at row 5, one nomination per row.
- Keep UTF-8 encoding.
- Use comma-separated values.
- Up to 50 nominations per CSV import.

Operational note:
- CSV imports submit immediately (not as drafts).
- Use single-entry draft flow for high-risk edits or last-minute copy changes.

## 9.10 Submit/Review Checklist

Before submission:
1. Character-limit check passed for Name/Description/Helpful Details.
2. Publish window and lead time are valid.
3. Platforms reflect currently shipped App Store offer.
4. Supplemental links are public and non-expiring.
5. Accessibility claims match live product behavior.
6. Localization strings and screenshots are aligned to campaign message.

After submission:
1. Confirm nomination appears under Submitted.
2. Record submission date/time and final text snapshot.
3. If updates are needed, edit allowed fields only (type and related apps are locked after submission).

## 10) Sources

- RetroRapid microsite: https://accessibilityupto11.com/apps/retrorapid/
- RetroRapid App Store listing: https://apps.apple.com/us/app/retrorapid/id6758641625
- ScreenshotStudio source project: `/Users/dadederk/Documents/RetroRacing.screenshotstudio`
- Apple App Store localizations reference: https://developer.apple.com/help/app-store-connect/reference/app-store-localizations
- Apple Getting Featured overview: https://developer.apple.com/app-store/getting-featured/
- Apple nomination workflow: https://developer.apple.com/help/app-store-connect/manage-featuring-nominations/nominate-your-app-for-featuring/
- Apple nominations template reference: https://developer.apple.com/help/app-store-connect/reference/nominations/nominations-template/
- GAAD official site: https://accessibility.day/
- Apple IAP overview: https://developer.apple.com/in-app-purchase/
- Apple IAP pricing management: https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase/
- Comparable racing listings reviewed:
  - https://apps.apple.com/us/app/retro-highway/id1163605498
  - https://apps.apple.com/id/app/traffic-racer/id547101139

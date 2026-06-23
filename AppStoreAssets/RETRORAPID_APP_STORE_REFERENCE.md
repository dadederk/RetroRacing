# RetroRapid! App Store Reference

Last updated: 2026-06-14

This document keeps RetroRapid!'s App Store copy, screenshot strategy, ASO review notes, localization priorities, and execution plan in one place. It mirrors the shape of Xarra's App Store reference while keeping the earlier RetroRapid ASO execution plan as historical campaign context.

Related docs:

- [Xarra App Store reference](../../Xarra/AppStoreAssets/XARRA_APP_STORE_REFERENCE.md)
- [RetroRapid ASO execution plan](../Plans/retrorapid_aso_growth_plan.md)
- [Localization requirements](../Requirements/localization.md)

## App Store Limits

Checked against Apple Developer documentation on 2026-06-14.

- App name: 30 characters maximum.
- Subtitle: 30 characters maximum.
- Promotional text: 170 characters maximum.
- Description: 4000 characters maximum.
- Keywords: 100 bytes per localization. Treat this as bytes, not only visible characters.
- What's New: 4000 characters maximum.
- Screenshots: one to ten screenshots per platform/localization, in `.jpeg`, `.jpg`, or `.png`.

Sources:

- [Apple App information reference](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Apple platform version information reference](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [Apple App Store localizations reference](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations)
- [Apple Product Page Optimization overview](https://developer.apple.com/help/app-store-connect/create-product-page-optimization-tests/overview-of-product-page-optimization)

## Current Public Listing Snapshot

Checked on 2026-06-14 from the public App Store pages.

Sources:

- [RetroRapid! US App Store listing](https://apps.apple.com/us/app/retrorapid/id6758641625)
- [RetroRapid! UK App Store listing](https://apps.apple.com/gb/app/retrorapid/id6758641625)
- [RetroRapid! Spain App Store listing](https://apps.apple.com/es/app/retrorapid/id6758641625)

| Field | Current public value | Notes |
|---|---|---|
| Name | `RetroRapid!` | Strong brand, but uses only 11/30 characters and leaves the highest-weight visible field without generic discovery terms. |
| Subtitle | `Retro racing at full speed` | Clear vibe, but less specific than the actual mechanic. It repeats the retro/racing idea without using lane, traffic, dodging, high score, or arcade-reflex language. |
| Promotional text | `iPhone, iPad, Mac, Apple Watch` | Inferred from the public page placement. This is clear platform support, but weak conversion copy and does not mention the actual game loop. Verify in App Store Connect. |
| Category | Racing | Good fit. Keep unless data strongly argues for a different Games subcategory. |
| Current version | 1.4.2, May 12, 2026 | The current What's New text still says `RetroRacing` in the public listing. This should be fixed on the next version metadata pass. |
| Languages | English, Catalan, Spanish | Matches current app localization requirements. |
| IAP | Unlimited Plays | One-time purchase positioning remains a conversion strength. |
| Public accessibility labels | VoiceOver, Larger Text, Dark Interface, Sufficient Contrast | Strong base. Verify whether Reduced Motion and Differentiates Without Color Alone can also be declared based on the current implementation. |
| Public compatibility | iPhone, iPad, Mac, Apple Watch, Apple Vision compatibility | Product copy says iPhone, iPad, Mac, and Apple Watch. Decide whether Apple Vision is intentional compatibility-only support or a product promise. |

The public page shows 4.8 stars in both the US and UK snapshots checked. The UK page shows more ratings than the US page in the public web view, so UK performance should be reviewed separately rather than assumed to behave like US performance.

Hidden keywords are not visible from the public App Store page. Pull the current keyword fields from App Store Connect before submission so this reference can archive current values and measure deltas.

## ASO Review

### Current Strengths

- The brand is distinctive and memorable.
- The public page already communicates privacy, accessibility, Game Center, Apple Watch, Mac, and one-time IAP support.
- User reviews reinforce the right messages: addictive high-score chasing, simple controls, Apple Watch support, nostalgia, and accessibility.
- The game has a clean core search story: retro arcade racing, 3 lanes, traffic dodging, high-score/reflex play, quick sessions, and accessible gameplay.
- Screenshot source files already include English, Spanish, and Catalan for iPhone/iPad.

### Main Opportunities

- Use the app name field for brand plus category intent, not brand alone.
- Replace the subtitle with mechanic-specific copy that adds unique searchable terms.
- Replace the platform-only promotional text with a benefit-led conversion message.
- Fix the public What's New brand mismatch from `RetroRacing` to `RetroRapid!`.
- Make the first three screenshots tell the conversion story in this order: game loop, controls, accessibility.
- Bring Mac screenshots to parity with iPhone/iPad and localize them into Spanish and Catalan.
- Decide how to handle Apple Vision compatibility in public copy and ScreenshotStudio output.
- Remove or park Apple TV screenshot output while tvOS is not publicly supported.
- Build a measurement loop before changing metadata repeatedly.

## Selected Metadata Candidate

This candidate is designed for the next version metadata update. It keeps the brand visible, adds high-intent discovery terms, avoids direct repetition between name/subtitle/keywords where practical, and keeps accessibility present without making the top-level promise too narrow.

### Localized Metadata

| Locale | App name | Name count | Subtitle | Subtitle count | Keywords | Keyword bytes |
|---|---|---:|---|---:|---|---:|
| en-US / en-GB draft | `RetroRapid! Arcade Racing` | 25/30 | `3-Lane Endless Traffic Dodger` | 29/30 | `retro,car,high,score,overtake,reflex,casual,offline,voiceover,haptics,watch,controller,leaderboard` | 98/100 |
| es-ES | `RetroRapid! Carreras Arcade` | 27/30 | `3 carriles, tráfico infinito` | 28/30 | `retro,coche,record,adelantar,reflejos,casual,sinconexion,voiceover,hapticos,reloj,mando,ranking` | 95/100 |
| ca | `RetroRapid! Carreres Arcade` | 27/30 | `3 carrils, trànsit infinit` | 26/30 | `retro,cotxe,record,avancaments,reflexos,casual,sensexarxa,voiceover,haptics,rellotge,comandament` | 96/100 |
| es-MX draft | `RetroRapid! Carreras Arcade` | 27/30 | `3 carriles, tráfico sin fin` | 27/30 | `retro,carro,record,rebasar,reflejos,casual,sininternet,voiceover,hapticos,reloj,control,ranking` | 95/100 |

Notes:

- The English subtitle spends almost all 30 characters on the mechanic: lane, endless, traffic, dodging.
- `RetroRapid! Arcade Racing` keeps the brand first while adding category intent.
- Hidden keywords preserve Apple Watch, controller, accessibility, and high-score/reflex language without repeating `arcade`, `racing`, `traffic`, `endless`, or `lane`.
- Spanish and Catalan hidden keywords avoid accents where useful to preserve byte budget and catch unaccented searches.
- Spanish (Mexico) should not blindly reuse Spain copy forever. The draft swaps `coche` for `carro`, `adelantar` for `rebasar`, and `sinconexion` for `sininternet`; validate against Appfigures/Krankie before shipping.

### Promotional Text

| Locale | Promotional text | Count |
|---|---|---:|
| en-US / en-GB draft | `Dodge traffic, chase high scores, and race quick retro arcade runs with Game Center, Apple Watch, and accessibility-first options.` | 130/170 |
| es-ES | `Esquiva tráfico, supera tu récord y juega carreras arcade retro rápidas con Game Center, Apple Watch y opciones de accesibilidad.` | 129/170 |
| ca | `Esquiva trànsit, supera el teu rècord i gaudix de carreres arcade retro ràpides amb Game Center, Apple Watch i accessibilitat.` | 126/170 |
| es-MX draft | `Esquiva tráfico, supera tu récord y juega carreras arcade retro rápidas con Game Center, Apple Watch y opciones de accesibilidad.` | 129/170 |

### Description Candidate

#### en-US / en-GB draft

```text
RetroRapid! is a fast retro arcade racer built for quick sessions and high-score chasing.

Move across 3 lanes, dodge traffic, and survive as speed keeps rising. Controls are simple to learn and hard to master, so every run becomes a reflex challenge.

Why players keep coming back:
- One-more-run arcade gameplay
- Game Center leaderboards and achievements
- Designed for iPhone, iPad, Mac, Apple Watch, and compatible Apple Vision devices
- Accessibility-first options: VoiceOver support, audio cues, haptics, larger text, dark interface, sufficient contrast, and Reduce Motion behavior
- Optional one-time Unlimited Plays purchase; no subscription

Crash, restart, and beat your best.
```

Count: 687/4000 characters.

#### es-ES

```text
RetroRapid! es un arcade de carreras retro pensado para partidas rápidas y para perseguir tu mejor puntuación.

Muévete entre 3 carriles, esquiva tráfico y aguanta cuando la velocidad sube. Los controles son fáciles de aprender y difíciles de dominar, así que cada partida pone a prueba tus reflejos.

Por qué engancha:
- Jugabilidad arcade de "una más"
- Clasificaciones y logros de Game Center
- Diseñado para iPhone, iPad, Mac, Apple Watch y dispositivos Apple Vision compatibles
- Opciones de accesibilidad: VoiceOver, pistas de audio, hápticos, texto más grande, interfaz oscura, contraste suficiente y reducción de movimiento
- Compra única opcional de Partidas ilimitadas; sin suscripción

Choca, reinicia y supera tu marca.
```

Count: 731/4000 characters.

#### ca

```text
RetroRapid! és un arcade de carreres retro pensat per a partides ràpides i per a perseguir la teua millor puntuació.

Mou-te entre 3 carrils, esquiva trànsit i resistix quan la velocitat puja. Els controls són fàcils d'aprendre i difícils de dominar, aixina que cada partida posa a prova els teus reflexos.

Per què enganxa:
- Jugabilitat arcade de "una més"
- Classificacions i assoliments de Game Center
- Dissenyat per a iPhone, iPad, Mac, Apple Watch i dispositius Apple Vision compatibles
- Opcions d'accessibilitat: VoiceOver, pistes d'àudio, hàptics, text més gran, interfície fosca, contrast suficient i reducció de moviment
- Compra única opcional de Partides il·limitades; sense subscripció

Xoca, reinicia i supera la teua marca.
```

Count: 740/4000 characters.

### What's New Candidate

Use this shape for the next bug-fix/polish release if there is no larger feature to lead with. It fixes the live brand mismatch and keeps Game Center value visible without over-explaining.

#### en-US / en-GB draft

```text
This update sharpens RetroRapid! with bug fixes and racing polish. The Game Center update is still the star: earn achievements, chase friends on the track, and share clean snapshots of your best runs. Thanks for racing with us.
```

Count: 227/4000 characters.

#### es-ES

```text
Esta actualización hace que RetroRapid! sea más estable y fiable. Game Center sigue siendo la estrella: logros, amigos en la pista y capturas limpias para compartir tus mejores partidas. Gracias por correr con nosotros.
```

Count: 219/4000 characters.

#### ca

```text
Esta actualització fa que RetroRapid! siga més estable i fiable. Game Center continua sent l'estrela: assoliments, amistats en la pista i captures netes per a compartir les teues millors partides. Gràcies per córrer amb nosaltres.
```

Count: 230/4000 characters.

## Why This Metadata Direction

- The visible fields carry the strongest discovery terms: arcade racing, lane, endless, traffic, and dodger.
- The hidden keywords cover supporting intent: car, high score, overtakes, reflexes, casual/offline play, VoiceOver, haptics, Apple Watch, controllers, and leaderboards.
- The promotional text moves from platform inventory to a real promise: dodge traffic, chase high scores, quick runs, Game Center, Apple Watch, accessibility.
- The description opens with gameplay first, then proves replayability, platform support, accessibility, and monetization clarity.
- Apple Vision is named carefully as compatible-device support, not as a full native visionOS promise. If that is not the desired message, remove the phrase before submission.

## Screenshot Assets

Screenshot Studio project:

- [Project root](RetroRacing.screenshotstudio/)
- [iPhone source copy](RetroRacing.screenshotstudio/iphone/data.plist)
- [iPad source copy](RetroRacing.screenshotstudio/ipad/data.plist)
- [Mac source copy](RetroRacing.screenshotstudio/mac/data.plist)
- [Apple Watch source copy](RetroRacing.screenshotstudio/appleWatch/data.plist)
- [Project settings](RetroRacing.screenshotstudio/project.plist)

Current source state on 2026-06-14:

- iPhone and iPad have seven localized screenshot entries for `en-US`, `es-ES`, and `ca`.
- Mac has five English entries and blank Spanish/Catalan entries.
- Apple Watch currently has blank text entries, which is acceptable if the watch set is sequence-only, but it should be intentional.
- ScreenshotStudio still has Apple TV and Apple Vision selected in project settings. Apple TV should be parked unless tvOS is actively shipping. Apple Vision needs a product decision because the public App Store listing shows compatibility.

### Current iPhone/iPad Sequence

| # | Current title | Current English body | ASO note |
|---:|---|---|---|
| 1 | `Race Through Endless Traffic` | `Navigate your car, dodge rivals, and rack up overtakes in this retro-inspired arcade racer.` | Good first slide. Consider adding the final period consistently if the visual style uses sentence punctuation. |
| 2 | `One Wrong Move. Game Over` | `The speed climbs. One mistake ends your run. Chase your high score!` | Strong tension slide, but it currently appears before controls/accessibility. |
| 3 | `Climb the Leaderboard` | `Challenge friends, beat rivals, and prove you're the fastest on Game Center.` | Good feature, but too early for first-three conversion unless rankings prove Game Center is the hook. |
| 4 | `Simple Controls. Pure Arcade Action` | `Move left. Move right. Don't crash. Master the basics in seconds, spend hours chasing your high score.` | Move this to slide 2. |
| 5 | `Built For Accessibility` | `VoiceOver support, audio cues, haptics, and adaptable gameplay settings` | Move this to slide 3. Add final punctuation in English. |
| 6 | `Customize Your Experience` | `Adjust volume, choose haptic feedback, select your theme, and fine-tune controls. RetroRapid! adapts to your play style.` | Good later slide. |
| 7 | `Choose Your Retro Aesthetic` | `From classic pocket consoles green to lcd handheld games, customize your visual experience with iconic retro themes.` | Rewrite body for clarity and capitalize LCD. |

### Recommended Screenshot Storyboard

Use this as the next source-copy pass for iPhone, iPad, and Mac. Localize all slides before export.

| # | Title | Body | Purpose |
|---:|---|---|---|
| 1 | `Race Through Endless Traffic` | `Navigate your car, dodge rivals, and rack up overtakes in this retro-inspired arcade racer.` | Hook: what the game is. |
| 2 | `Simple Controls. Pure Arcade Action` | `Move left. Move right. Don't crash. Master the basics in seconds, then chase your high score for hours.` | Clarity: how it plays. |
| 3 | `Built For Accessibility` | `VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings.` | Differentiator: inclusive play without leading only with accessibility. |
| 4 | `One Wrong Move. Game Over` | `The speed climbs. One mistake ends your run. Restart fast and beat your best.` | Tension: why it is replayable. |
| 5 | `Climb the Leaderboards` | `Earn achievements, chase friends, and share your best runs with Game Center.` | Retention: social/replay proof. |
| 6 | `Choose Your Retro Aesthetic` | `Switch from pocket-console green to LCD handheld style, and make every run feel properly retro.` | Monetization/theme support. |
| 7 | `Customize Your Experience` | `Tune controls, haptics, volume, visual style, and feedback so RetroRapid! fits your play style.` | Personalization and trust. |

Watch screenshots:

- Keep them sequence-first unless there is a clean, legible watch overlay style.
- Recommended order: gameplay, Digital Crown/control moment, speed/tension, accessibility/help, result/high score.
- If overlay text is used, keep it extremely short and localized.

Mac screenshots:

- Bring Mac to the same seven-slide story or intentionally choose a tighter five-slide Mac story.
- Fill Spanish and Catalan localizations before export.
- Show keyboard/controller controls somewhere in the Mac set because Mac users will look for input clarity.

Apple Vision:

- If the app is compatibility-only on Apple Vision, avoid screenshot copy that implies a bespoke spatial experience.
- If Vision is intended as a first-class store surface, create a separate Vision screenshot story after validating the experience in-app.

Apple TV:

- Do not export or upload Apple TV screenshots until tvOS is publicly supported.
- Keep tvOS ASO work in a separate launch plan so it does not dilute the current App Store promise.

## Release-Note Voice

RetroRapid release notes work best when they sound energetic, specific, and grateful:

- Lead with the player-facing reason for the update.
- Use racing language sparingly and only when it clarifies the release.
- Keep feature bullets practical: achievements, friends, controllers, accessibility cues, stability.
- Use `RetroRapid!` consistently. Avoid `RetroRacing` in public copy except for internal module/repo references.
- Name accessibility improvements plainly and by user benefit.
- Mention App Store review/user feedback when the change came from players.
- Keep the first 2-3 lines useful because many users will not expand the full version history.

Reusable shape:

```text
RetroRapid! [adds/fixes/improves] [specific player benefit].

Highlights:
- [Feature/improvement], so [plain benefit]
- [Feature/improvement], so [plain benefit]

We've also included [specific stability/polish note].

Thanks for racing with us.
```

## Country And Language Expansion Strategy

Current supported app languages are English, Spanish, and Catalan. New App Store metadata localizations should not outpace app UI localization for long, especially because RetroRapid sells accessibility and settings clarity. For each new market, prepare App Store metadata, screenshots, app strings, IAP display names, Game Center metadata, and support/privacy pages as one localization package.

### Priority Tiers

| Priority | Locale / market | Why it is interesting | Preparation notes |
|---|---|---|---|
| P0 | `en-US`, `en-GB`, `es-ES`, `ca` | Existing languages. UK appears meaningful from public ratings. | Finish current metadata refresh, screenshot parity, and localized What's New. Consider explicit `en-GB` only if keyword/rating data differs from US. |
| P1 | `es-MX` | Apple uses Spanish (Mexico) across Mexico and much of Latin America. Low-lift from existing Spanish, but search language differs. | Prepare a separate metadata field and screenshot review. Validate `carro`, `rebasar`, `sininternet`, `control`, and `ranking` terms before shipping. |
| P1 | `de-DE` | Large European App Store market; racing and arcade terms are direct enough to localize well. | Requires full app strings and screenshots. Check `arcade rennen`, `retro rennen`, `verkehr`, `reaktion`, `watch spiel`, and accessibility terms. |
| P1 | `ja` | Strong game market and good fit for compact arcade gameplay. | Needs professional localization and screenshot typography QA. Avoid literal machine translation of racing/retro terms. |
| P1 | `pt-BR` | Large audience and useful next step after Spanish. | Prepare Brazilian Portuguese specifically, not generic Portuguese. Validate monetization/pricing expectations. |
| P2 | `fr-FR` | Large EU market with reasonable localization lift. | Check whether arcade/racing/watch-game terms have enough demand before full rollout. |
| P2 | `ko` | Strong mobile gaming market and high engagement potential. | Higher localization QA bar. Prioritize only after Japanese/German data or if App Store Connect shows Korean traction. |
| P2 | `zh-Hans`, `zh-Hant` | High upside, especially for simple arcade games. | Needs careful localization, legal/availability review, screenshot QA, and monetization expectations. |
| P3 | `it`, `nl`, `pl`, `tr` | Additional scale after the first wave. | Require keyword exports before committing. Italy may be the lowest-friction Romance-language follow-up. |

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

## Product Page Optimization

Use Product Page Optimization only after the base metadata and screenshot copy are clean. Apple supports testing up to three variants of app icons, screenshots, and previews for iOS/iPadOS product pages, and results should be judged on conversion lift and confidence.

First test candidate:

- Control: current visual style with recommended 7-slide order.
- Treatment A: accessibility in slide 3 with stronger VoiceOver/audio/haptics wording.
- Treatment B: Apple Watch/control story in slide 3, accessibility moved to slide 4.

Do not test name/subtitle changes through PPO; Apple does not use PPO for those fields. Treat metadata updates as versioned experiments with 28-day observation windows.

## 90-Day Execution Plan

### Days 1-7

- [ ] Pull current hidden keywords, promotional text, description, localized What's New, and screenshot uploads from App Store Connect.
- [ ] Decide whether to ship `RetroRapid! Arcade Racing` plus `3-Lane Endless Traffic Dodger` as the next visible metadata change.
- [ ] Replace current public What's New copy that says `RetroRacing`.
- [ ] Decide Apple Vision positioning: compatibility-only, first-class, or not mentioned in marketing copy.
- [ ] Remove or park Apple TV ScreenshotStudio output unless tvOS is actively in the release scope.

### Days 8-21

- [ ] Apply the recommended screenshot order to iPhone and iPad.
- [ ] Bring Mac screenshots to parity and fill Spanish/Catalan source strings.
- [ ] Create an intentional Apple Watch screenshot sequence.
- [ ] Verify accessibility labels in App Store Connect against shipped behavior, especially Reduced Motion and color/contrast claims.
- [ ] Save a metric baseline: product page views, conversion, units, IAP conversion, ratings, and keyword ranks.

### Days 22-45

- [ ] Submit the metadata/screenshot refresh with the next app version.
- [ ] Re-check keyword ranks after 7, 14, and 28 days.
- [ ] Compare UK and US conversion separately.
- [ ] Prepare `es-MX` and `de-DE` keyword exports and draft metadata.
- [ ] Decide whether the first PPO test has enough traffic to be meaningful.

### Days 46-90

- [ ] Run the first screenshot PPO test if traffic supports it.
- [ ] Prepare first-wave localization implementation work for `es-MX` and the next chosen full locale.
- [ ] Localize IAP and Game Center metadata alongside app strings.
- [ ] Build a seasonal App Store story around motorsport events only when the in-app content or release timing supports it.
- [ ] Update this reference with actual keyword rank movement and conversion changes.

## Validation Results

Validated on 2026-06-14 with the bundled ASO metadata validator and separate keyword byte counts.

| Locale | App name | Subtitle | Promotional text | Keywords | Keyword bytes | Description | What's New |
|---|---:|---:|---:|---:|---:|---:|---:|
| en-US / en-GB draft | 25/30 | 29/30 | 130/170 | 98/100 chars | 98/100 bytes | 687/4000 | 227/4000 |
| es-ES | 27/30 | 28/30 chars | 129/170 chars | 95/100 chars | 95/100 bytes | 731/4000 | 219/4000 |
| ca | 27/30 | 26/30 chars | 126/170 chars | 96/100 chars | 96/100 bytes | 740/4000 | 230/4000 |

All selected fields pass current Apple limits. Re-run validation after any copy edits, especially for Spanish/Catalan keyword byte counts.

## Open Questions

- What are the current hidden keyword fields in App Store Connect?
- Is the public Apple Vision compatibility intentional enough to mention in description and screenshots?
- Should UK get its own English metadata locale based on stronger public rating volume?
- Should accessibility labels add Reduced Motion or Differentiate Without Color Alone after implementation verification?
- Which market has the best current App Store Connect signal: UK, Spain, Mexico, Germany, Japan, or Brazil?
- Should the next visible name change be a conservative update (`RetroRapid! Arcade Racing`) or a bolder mechanic-first name?
